package.path = require("./lua/Control/Head").path

require("base") -- 基础功能接口
require("publicApi") -- 共用功能接口
require("typename") -- 类弄定义接口
require("ProtoManager") -- 协议管理对象 
require("logging") -- 日志等级接口
require("logger") -- 日志对象  
local Define = require("ControlDefine") -- 定义  
require("Statist") -- 统计对象
require("ControlAPI") -- 辅助功能
require("ControlLink") -- 回调
require("ControlUserLink") -- 回调
require("ControlPublic") -- 回调
require("ControlTableLink") -- 回调
require("ServerInfo")
local tJson = require("cjson")
local tGameConfig = require("GameConfig") --  游戏匹配

-- 玩家功能回调
ClientSink = { LevelLog = nil }

ClientSink.m_lstControl = {}

-- 启动服务器
function ClientSink.OnStart() 
    
    -- 设置日志目录:
    logger.SetFile("./log/Control/" .. base.GetPort() .. "-" .. base.GetThreadIndex(), "Control", base)
    -- 设置全局等级
    logger:setLevel( logging.DEFAULT, "Control" )
    -- 注册服务器
    base.RegServer(typename.control)

    -- 注册协议  
    ClientSink.Protocol()

    base.SetTimer(Define.TimerID_LoadGameConfig, 1000 * 10, 1, ClientSink.ControlLoadConfig)          --加载配置
    base.SetTimer(Define.TimerID_AppBlackList, 1000 * 60, -1, ControlPublic.SengWebAppBlackList)         --发送App黑名单数据请求
    
    -- 等级案例
    logger:info("control Server Start") 



    -- local t = math.floor(socket.gettime() * 1000)

    -- logger:info('test tim:'..t)
    -- logger:info("a "..os.date("%Y-%m-%d %H:%M:%S" ,math.floor(t/1000)))
    -- logger:info("b "..os.date("%Y-%m-%d %H:%M:%S"))


    -- local t1 = math.floor(socket.gettime() * 1000)
    -- base.Sleep(100)
    -- local t2 = math.floor(socket.gettime() * 1000)
    -- logger:info('test space:'..t2 - t1)


 
end

function ClientSink.ControlLoadConfig(TimerID)

    -- logger:info('[UUUUU] _LoadConfig')

    local bTimer = false

    if ControlPublic.m_bLoadData_Config == false then
        ControlPublic.LoadConfig()
        bTimer = true
    end

    -- if ControlPublic.m_bLoadData_Scope == false then
    --     ControlPublic.GetUserIDScope()
    --     bTimer = true
    -- end


    if bTimer then
        base.SetTimer(Define.TimerID_LoadGameConfig, 1000 * 10, 1, ClientSink.ControlLoadConfig)          --加载配置

        -- logger:info('[UUUUU] TimerID_LoadGameConfig')
    end

end

-- 停止服务器
function ClientSink.OnStop()

    base.KillTimer(Define.TimerID_Check)
    base.KillTimer(Define.TimerID_CheckUser)

    -- 取消本地服务器
    base.UnRegServer()

end

-- 注册协议  
function ClientSink.Protocol()

    -- base.RegFunc(ProtoManager.Sys1.CONTROL, ProtoManager.Sub_Control.CONTROL_INFO, ControlPublic.OnControlInfo)
    -- base.RegFunc(ProtoManager.Sys1.CONTROL, ProtoManager.Sub_Control.CONTROL_USERINFO, ControlUserLink.OnSetUserInfo)
    base.RegFunc(ProtoManager.Sys1.CONTROL, ProtoManager.Sub_Control.CONTROL_ROOMINFO, ControlLink.OnSetUserInfo)
    base.RegFunc(ProtoManager.Sys1.CONTROL, ProtoManager.Sub_Control.CONTROL_WEB_SETPOOL, ControlTableLink.OnWebSetPool)

    -- base.RegFunc(ProtoManager.Sys.DB, ProtoManager.Sub_DB.SUB_REP_CONTROL_DATA, ControlLink.OnRepControlData)
    -- base.RegFunc(ProtoManager.Sys.DB, ProtoManager.Sub_DB.SUB_REP_CONTROL_GETNEW_USER, ControlUserLink.OnRepGetNewUserData)
    -- base.RegFunc(ProtoManager.Sys.DB, ProtoManager.Sub_DB.SUB_REP_CONTROL_USER_DATA, ControlUserLink.OnRepControlData)
    -- base.RegFunc(ProtoManager.Sys.DB, ProtoManager.Sub_DB.SUB_REP_USERID_SCOPE_DATA, ControlPublic.OnGetUserIDScope)
end

-- require "socket"

-- --host = "www.w3.org"
-- --file = "/TR/REC-html32.html"

-- function lua_string_split(str, split_char)    --字符串拆分

--     local sub_str_tab = {};
--     while (true and str ~= nil) do
--         local pos = string.find(str, split_char);
--         if (not pos) then
--             sub_str_tab[#sub_str_tab + 1] = str;
--             break;
--         end
--         local sub_str = string.sub(str, 1, pos - 1);
--         sub_str_tab[#sub_str_tab + 1] = sub_str;
--         str = string.sub(str, pos + 1, #str);
--     end

--     return sub_str_tab;
-- end


-- function download(url)

--     base.Log("download")

--     local infolist = lua_string_split(url,"/")
--     -- local cache_file = infolist[#infolist]

--     local host = infolist[3]
--     local pos = string.find(url, host)
--     local file = nil
--     if pos then
--         file = string.sub(url, pos + #host)
--     end
--     pos = nil

--     --local out = io.open(cache_file,"wb")

--     local sRes = ""

--     socket.settimeout(0)
--     local c, myer = socket.connect(host, 80)

--     if myer and myer == 'timeout' then
--         base.Log('timeout 2')
--         coroutine.yield(c)
--     else
--         base.Log('connect end')
--     end

--     local count = 0
--     local pos = nil

    
--     c:send("GET " ..file .." HTTP/1.0\r\n\r\n")
--     while true do
--         local s, status, partial = receive(c)
--         count = count + #(s or partial)
--         local data = s or partial

--         if data then
--             if pos == nil then            --去除响应头
--                 pos = string.find(data, "\r\n\r\n")
--                 if pos then
--                     -- out:write(string.sub(data, pos + #"\r\n\r\n"))
--                     sRes = sRes..string.sub(data, pos + #"\r\n\r\n")
--                 end
--             else
--                 -- out:write(data)
--                 sRes = sRes..data
--             end
--         end
--         if status == "closed" then break end
--     end
--     c:close()
-- --  print(file, count)
--     -- out:close()
-- --    os.execute("del " .. cache_file)

--     base.Log(sRes)
-- end

-- function receive(connection)
--     connection:settimeout(0)
--     local s, status, partial = connection:receive(2^10*100)
--     if status == 'timeout' then
--         base.Log('timeout')
--         coroutine.yield(connection)
--     end
--     return s or partial, status
-- end

-- threads = {}

-- function get(url)
--     local co = coroutine.create(function ()
--         download(url)
--     end)
--     table.insert(threads, co)
-- end

-- function dispatch()
--     local i = 1
--     local connections = {}
--     while true do
--         if threads[i] == nil then
--             if threads[1] == nil then break end
--             i = 1
--             connections = {}
--         end
--         local status, res = coroutine.resume(threads[i])
--         if not res then
--             table.remove(threads, i)
--         else
--             i = i + 1
--             connections[#connections + 1] = res
--             if #connections == #threads then
--                 local a, b, err = socket.select(connections)
--                 -- for k, v in pairs(a) do
--                 --     base.Log(k..'a=a'..v)
--                 -- end
--                 -- for k, v in pairs(b) do
--                 --     base.Log(k..'b=b'..v)
--                 -- end
--             end
--         end
--     end
-- end

--get("http://www.w3.org/TR/REC-html32.html")
--get("http:///1/将夜") --下载中文会出错



-- require("NonBlockHttps")
-- local url = require("socket.url")
-- local dispatchMgr = require("dispatchMgr")
-- local http = require("socket.http")
-- dispatchMgr.TIMEOUT = 10

-- function ClientSink.Test()

--     http.baseLog = base
--     dispatchMgr.baseLog = base

--     handler = dispatchMgr.newhandler("coroutine")

--     handler:start(function()

--         base.Log("-------start")

--         local r, c, h, s = http.request({
--             method = "HEAD",
--             url = "http://qp.mpapi.co/game/list",
--             create = handler.tcp
--         })
        

--         base.Log(r)
--     end)

--     base.Log("run")

--     while true do
--         handler:step()
--         base.Sleep(100)
--     end

--     base.Log("End.")

--     -- base.Log(http.request("http://qp.mpapi.co/game/list"))

--     -- NonBlockHttps.Init(base, 5421)

--     -- local FuncRes = function(reqt, body, tRes, code, headers, status2)

--     -- base.Log(http.request("http://qp.mpapi.co/game/list"))

--     -- end

--     -- base.Log("NonBlockHttps")
--     -- NonBlockHttps.http("http://qp.mpapi.co/game/list", nil, FuncRes)

--     -- -- return {isRecommendOn=isRecommendOn,isFollowBetOn=isFollowBetOn,isUserBankerOn=isUserBankerOn}
    
--     -- local sHttp = "http://qp.mpapi.co/game/list"
--     -- -- local sHttp = "http://mayagame.com/"

--     -- http.init(base, 14101)
--     -- base.Log(sHttp)

--     -- local json_data = http.request(sHttp, "123")
--     -- if json_data ~= nil and json_data ~= "" then
--     --     --base.Log(json_data)

--     --     local kl = base.GetKernel()
--     --     local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)
--     --     km:Log(json_data)

--     -- else
--     --     base.Log("nil")
--     -- end

--     -- get("http://mayagame.com/")

--     -- dispatch()

--     -- print(os.clock())

-- end

return ClientSink