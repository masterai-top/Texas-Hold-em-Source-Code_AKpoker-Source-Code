package.path  = "../lua/base/luasec/?.lua;./lua/base/luasec/?.lua;" .. package.path
local ssl_https     = require('luasec.https');
local socket_http   = require("socket.http")
local ltn12         = require "ltn12"
local cjson         = require("cjson")

------------------------
---how to use:
---1. get  http
-- local http_client = require "MyHttps"
-- local ok, code, body, headers, status =
-- http_client.request("http://httpbin.org/get")
-- print("ok   :", ok)
-- print("code :", code)
-- print("status:", status)
-- print("body :", body)

---2. get https
-- local http_client = require "MyHttps"
-- local ok, code, body, headers, status =
-- http_client.request("https://httpbin.org/get", {
--     timeout = 5,       -- 5 秒超时，可选
--     insecure = true,   -- 跳过证书校验（测试用，生产环境建议关掉）
-- })
-- print("code :", code)
-- print("body :", body)

---3. post 带body
---
-- local http_client = require "MyHttps"
-- local data = "name=test&pwd=123456"
-- local ok, code, body, headers, status =
--     http_client.request("https://httpbin.org/post", {
--         method  = "POST",
--         headers = {
--             ["Content-Type"] = "application/x-www-form-urlencoded",
--         },
--         body    = data,
--     })
-- print("code :", code)
-- print("body :", body)

---4. HTTPS 如果证书有问题
-- 可以暂时通过 opts.insecure = true 设置 verify = "none"，
-- 但生产环境最好正确配置 CA 证书。
------------------------

MyHttps = {}

-- 默认请求头，防止因为 User-Agent 等过“干净”被 403
local DEFAULT_HEADERS = {
    ["User-Agent"]      = "Mozilla/5.0 (LuaSocket+LuaSec)",
    ["Accept"]          = "*/*",
    ["Accept-Encoding"] = "identity",
    ["Connection"]      = "close",
}

local function merge_headers(custom)
    local h = {}
    -- 默认
    for k, v in pairs(DEFAULT_HEADERS) do
        h[k] = v
    end
    -- 用户覆盖
    if custom then
        for k, v in pairs(custom) do
            h[k] = v
        end
    end
    return h
end

--- 发送 HTTP/HTTPS 请求
-- @param url     string  完整 URL，支持 http:// 和 https://
-- @param opts    table   可选参数：
--                        opts.method  : "GET" / "POST" / "PUT" ... 默认 "GET"
--                        opts.headers : table 请求头
--                        opts.body    : string 请求体（用于 POST/PUT）
--                        opts.timeout : number 超时时间（秒，可选）
--                        opts.insecure : true 跳过证书校验（测试用，生产环境建议关掉）
-- @return ok, code, body, resp_headers, status
function MyHttps.request(url, opts)
    opts = opts or {}
    local method  = (opts.method or "GET"):upper()
    local headers = merge_headers(opts.headers)
    local body    = opts.body

    local resp_chunks = {}
    local req = {
        url     = url,
        method  = method,
        headers = headers,
        sink    = ltn12.sink.table(resp_chunks),
    }

    -- 有 body 一般是 POST/PUT 等
    if body then
        headers["Content-Length"] = #body
        req.source = ltn12.source.string(body)
    end

    -- 可选：设置超时（单位秒）
    if opts.timeout then
        -- http / https 都是基于 luasocket，设置全局超时
        socket_http.TIMEOUT = opts.timeout
        ssl_https.TIMEOUT   = opts.timeout
    end

    -- 根据协议选择 http 或 https
    local requester
    if url:match("^https://") then
        requester = ssl_https.request
        -- 需要忽略证书校验时，可以这样（生产环境建议正确配置证书）
        if not req.protocol then
            req.protocol = "tlsv1_2"
        end

        if opts.insecure then
            req.verify = "none"
        end
    else
        requester = socket_http.request
    end

    local ok, code, resp_headers, status = requester(req)
    local resp_body = table.concat(resp_chunks)

    return ok, code, cjson.decode(resp_body), resp_headers, status
end

return MyHttps
