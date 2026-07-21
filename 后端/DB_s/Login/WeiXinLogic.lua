
-- 微信 系统

package.path = require("./lua/DB_s/Head").path

local tBase = require("base")           -- 基础功能接口
local redis = require("redis")      -- Redis数据库接口
local api = require("publicApi")    -- 共用功能接口
local tBase64 = require("BaseSink")    -- base 编码解码
local tname = require("typename")   -- 类弄定义接口
local cjson     = require("cjson")        -- json 
local http      = require("socket.http")  -- Http 服务器
local dbInfo = require("DBInfo")      -- 数据库连接信息
local tErr    = require("ErrorSink")       -- 捕捉错误

WeiXinLogic= {}


-- 微信登录 ：  返回: ErrorCode,  sOpenID,sUnionid
function WeiXinLogic.HttpLogon(sCode)
    tBase.Log(" 请求HTTP处理    微信登录     ")
    local sHttp = dbInfo.sHttp.."Auth?Type=Login&code="
    sHttp = sHttp..sCode
    tBase.Log(" 请求HTTP处理   微信登录   sHttp = sHttp..sCode :   %s   ",sHttp)
    local tLogon = {}
    -- 主动 请求Http  服务器 ，直接返回  json_data数据
    tLogon.nResult = 0  -- 数据处理结果，  0 失败，1 成功
    tLogon.nError =  1  -- 错误代码， 1 成功,  2 网络错误（重新请求）
    local json_data = http.request(sHttp)  
    tBase.Log(" 请求HTTP处理  微信登录     请求Http  http.request 成功    ")
    -- 捕获异常
    function WeiXinLogic.XpcallHttpLogon(json_data)   
        tBase.Log(" 请求HTTP处理  捕获异常    XpcallHttpLogon   ")
        if json_data ~= nil and json_data ~= "" then
            -- 解析json数据
            local unjson = cjson.decode(json_data)  
            if  tonumber(unjson["ErrorCode"]) == 0 then 
                tLogon.sOpenID = unjson["OpenID"] 
                tLogon.sUnionID = unjson["unionid"] 
                tLogon.sRefresh_Token = unjson["refresh_token"] 
                if tLogon.sOpenID == nil or tLogon.sUnionID == nil or tLogon.sRefresh_Token == nil  then 
                    tBase.Log(" 请求HTTP处理  微信登录    json_data    异常状态   请求失败  %s      Error_Info==2040 ",json_data)
                    return nil 
                end 
                tBase.Log(" 请求HTTP处理  微信登录     OpenID:  %s  ",tLogon.sOpenID)
                tBase.Log(" 请求HTTP处理  微信登录     sUnionID:  %s  ",tLogon.sUnionID) 
                tBase.Log(" 请求HTTP处理  微信登录     sRefresh_Token:  %s  ",tLogon.sRefresh_Token) 
                tLogon.nResult  = 1 
                return tLogon 
            elseif  tonumber(unjson["ErrorCode"]) == 599 then 
                tLogon.nError =  2  -- 网络错误，重新请求
                tBase.Log(" 请求HTTP处理   微信登录  网络错误需要重启请求    重新授权登录   ")
                return nil 
            else
                tBase.Log(" 请求HTTP处理    Error_Info==2041  请求失败   ErrorCode:   %d ",tonumber(unjson["ErrorCode"]))
                -- 返回 错误数据给客户端。
                return nil 
            end
        else
            tBase.Log(" 请求HTTP处理  json_data  Error_Info==2042  异常状态   请求失败  %s  ",json_data)
            return nil 
        end
    end
    -- 捕获异常,输出错误日志
    xpcall(WeiXinLogic.XpcallHttpLogon,tErr.tpLog,json_data)
    if tLogon.nResult == 0  then
        tBase.Log(" 请求HTTP处理  微信登录  获取数据   失败 Error_Info==2043   ")
        return nil 
    else 
        tBase.Log(" 请求HTTP处理  微信登录  获取数据    成功    ")
        return tLogon
    end 
end

-- 微信注册 : 返回: ErrorCode,  sOpenID,sUnionid ,sNickName,nSex,sHeadimgurl
function WeiXinLogic.HttpRegister(tData)
    local sHttp = dbInfo.sHttp.."Auth?Type=Regist&code="
    sHttp = sHttp..tData.sOpenID.."&".."refresh_token="..tData.sRefresh_Token

    tBase.Log(" 请求HTTP处理   微信注册     sHttp = sHttp..sOpenID..sRefresh_Token :   %s   ",sHttp)
    local tRegister = {}
    tRegister.nResult = 0 -- 数据处理结果，  0 失败，1 成功
    tRegister.nError =  1 -- 错误代码 1 成功
    -- 主动 请求Http  服务器 ，直接返回  json_data数据
    local json_data = http.request(sHttp)
    tBase.Log(" 请求HTTP处理  微信注册    请求Http    http.request 成功    ")
    -- 捕获异常
    function WeiXinLogic.XpcallHttpRegister(json_data) 
        tBase.Log(" 请求HTTP处理  微信注册    捕获异常    XpcallHttpRegister   ")
        if json_data ~= nil then
            -- 解析json数据
            tBase.Log(" 请求HTTP处理   微信注册   开始解析json数据   ")
            --tBase.Log(" 请求HTTP处理   微信注册   解析数据之前：  json_data ：       "..json_data)

            local unjson = cjson.decode(json_data)
            if  tonumber(unjson["ErrorCode"])== 0 then                 
                tRegister.sOpenID = unjson["OpenID"] 
                tRegister.sUnionID = unjson["unionid"] 
                if tRegister.sUnionID == nil or tRegister.sUnionID == nil then 
                    tBase.Log(" 请求HTTP处理   微信注册     获取 tRegister.sUnionID   Error  Error_Info==2044 ")
                    return nil
                end 
                -- 下面数据有可能是 空的
                tRegister.sNickName = unjson["nickname"]                 
                if #tRegister.sNickName < 1 then  
                    tRegister.sNickName = "玩家"
                end             
                tRegister.sNickName = api.Check_String_Special(tRegister.sNickName)   -- 过滤  ’ % 这些字符

                tRegister.sNickName = WeiXinLogic.Encrypt(tRegister.sNickName) -- 编码(处理 特殊字符问题)
                

                tRegister.nSex = tonumber(unjson["sex"])   -- 默认 男
                if tRegister.nSex == nil then 
                   tBase.Log(" 请求HTTP处理   微信注册  修改微信性别   空昵称  nSex:  %d",tRegister.nSex) 
                   tRegister.nSex = 0
                elseif tRegister.nSex == 1 then  -- 微信定义： 1 男，2 女                
                   tRegister.nSex = 0
                   tBase.Log(" 请求HTTP处理   微信注册  修改微信性别 男的 定义   nSex:  %d",tRegister.nSex)                
                elseif tRegister.nSex == 2 then   -- 微信定义： 1 男，2 女
                   tBase.Log(" 请求HTTP处理   微信注册  修改微信性别 女的 定义   nSex:  %d",tRegister.nSex) 
                   tRegister.nSex = 1     -- 我们定义： 0 男，1 女
                else                 
                   tBase.Log(" 请求HTTP处理   微信注册  修改微信性别   错误的  nSex:  %d",tRegister.nSex) 
                    tRegister.nSex = 0
                end
                tBase.Log(" 请求HTTP处理   微信注册     nSex:  %d",tRegister.nSex)           
                tRegister.sHeaUrl = unjson["headimgurl"]  -- 获取 nil  默认头像 1 
                tBase.Log(" 请求HTTP处理   微信注册     sHeaUrl:  %s ,len: %d  ",tRegister.sHeaUrl,#tRegister.sHeaUrl)           
                if #tRegister.sHeaUrl < 10 then 
                    tRegister.sHeaUrl = 1  -- 默认头像
                end 
                tBase.Log(" 请求HTTP处理   微信注册     sHeaUrl:  %s  ",type(tRegister.sHeaUrl))

                tBase.Log(" 请求HTTP处理   微信注册     OpenID:    %s  ",tRegister.sOpenID)
                tBase.Log(" 请求HTTP处理   微信注册     sUnionID:  %s  ",tRegister.sUnionID) 
                tBase.Log(" 请求HTTP处理   微信注册     sNickName: %s  ",tRegister.sNickName)  
                tBase.Log(" 请求HTTP处理   微信注册     nSex:      %d   ",tRegister.nSex)  
                tBase.Log(" 请求HTTP处理   微信注册     sHeadimgurl: %s   ",tRegister.sHeaUrl) 
                tRegister.nResult = 1 
                return tRegister 
            elseif  tonumber(unjson["ErrorCode"])  == 40030 then  
                tBase.Log(" 请求HTTP处理   微信注册  to_ken过期  重新授权登录   ")
                return nil 
            elseif  tonumber(unjson["ErrorCode"]) == 599 then 
                tRegister.nError =  2  -- 网络错误需要重启请求
                tBase.Log(" 请求HTTP处理   微信注册  网络错误需要重启请求    重新授权登录   ")
            else
                -- 返回 错误数据给客户端。
                return nil 
            end 
        else
            tBase.Log(" 请求HTTP处理  微信注册    json_data = nil      失败   Error_Info==2046  ")
            return nil 
        end
        return  nil 
    end 
    -- 捕获异常,输出错误日志
    xpcall(WeiXinLogic.XpcallHttpRegister,tErr.tpLog,json_data)
    if tRegister.nResult == 0  then
        tBase.Log(" 请求HTTP处理  微信注册  获取数据   失败   Error_Info==2047  ")
        return nil
    else 
        tBase.Log(" 请求HTTP处理  微信注册  获取数据    成功    ")
        return tRegister
    end 
end

-- 小程序登录 ：  返回: ErrorCode,  sOpenID,sUnionid
function WeiXinLogic.WebHttpLogon(sWebData)
    tBase.Log(" 小程序登录   请求HTTP处理    WebHttpLogon     ")

    tBase.Log(" 微信系统   小程序登录 :  需要URL编码:    "..sWebData)
    sWebData =   WeiXinLogic.encodeURI(sWebData)
    local sHttp = dbInfo.sHttp.."WXGameAuth?data="
    tBase.Log(" 小程序登录    请求HTTP处理   sHttp = sHttp..sWebData :   %s   ",sHttp)

    sHttp = sHttp..sWebData
    local tLogon = {}
    -- 主动 请求Http  服务器 ，直接返回  json_data数据
    tLogon.nResult = 0  -- 数据处理结果，  0 失败，1 成功
    tLogon.nError =  1  -- 错误代码， 1 成功,  2 网络错误（重新请求）
    local json_data = http.request(sHttp)  
    tBase.Log(" 小程序登录    请求HTTP处理   请求Http  http.request 成功    ")
    -- 捕获异常
    function WeiXinLogic.XpcallHttpLogon(json_data)   
        tBase.Log(" 小程序登录     请求HTTP处理  捕获异常    XpcallHttpLogon   ")
        if json_data ~= nil then
            -- 解析json数据
            local unjson = cjson.decode(json_data)  
            if  tonumber(unjson["ErrorCode"]) == 0 then 
                tLogon.sOpenID = unjson["OpenID"] 
                tLogon.sUnionID = unjson["unionid"] 
                if tLogon.sOpenID == nil or tLogon.sUnionID == nil  then 
                    tBase.Log(" 小程序登录    请求HTTP处理     json_data    异常状态   请求失败  %s  Error_Info==2048 ",json_data)
                    return nil 
                end 
                -- 下面数据有可能是 空的
                tLogon.sNickName = unjson["nickname"]                
                if #tLogon.sNickName < 1 then 
                    tLogon.sNickName = "玩家"
                end             

                tLogon.sNickName = api.Check_String_Special(tLogon.sNickName)   -- 过滤  ’ % 这些字符
                
                tLogon.sNickName = WeiXinLogic.Encrypt(tLogon.sNickName) -- 编码(处理 特殊字符问题)
                tLogon.nSex = tonumber(unjson["sex"])   -- 默认 男
                if tLogon.nSex == nil then 
                   tBase.Log(" 请求HTTP处理   小程序登录  修改微信性别   空昵称  nSex:  %d",tLogon.nSex) 
                   tLogon.nSex = 0
                elseif tLogon.nSex == 1 then  -- 微信定义： 1 男，2 女                
                   tLogon.nSex = 0
                   tBase.Log(" 请求HTTP处理   小程序登录  修改微信性别 男的 定义   nSex:  %d",tLogon.nSex)                
                elseif tLogon.nSex == 2 then   -- 微信定义： 1 男，2 女
                   tBase.Log(" 请求HTTP处理   小程序登录  修改微信性别 女的 定义   nSex:  %d",tLogon.nSex) 
                   tLogon.nSex = 1     -- 我们定义： 0 男，1 女
                else                 
                   tBase.Log(" 请求HTTP处理   小程序登录  修改微信性别   错误的  nSex:  %d",tLogon.nSex) 
                    tLogon.nSex = 0
                end
                tBase.Log(" 请求HTTP处理   小程序登录     nSex:  %d",tLogon.nSex)           
                tLogon.sHeaUrl = unjson["headimgurl"]  -- 获取 nil  默认头像 1 
                tBase.Log(" 请求HTTP处理   小程序登录     sHeaUrl:  %s ,len: %d  ",tLogon.sHeaUrl,#tLogon.sHeaUrl)           
                if #tLogon.sHeaUrl < 10 then 
                    tLogon.sHeaUrl = 1  -- 默认头像
                end 
                tBase.Log(" 请求HTTP处理   小程序登录     OpenID:    %s  ",tLogon.sOpenID)
                tBase.Log(" 请求HTTP处理   小程序登录     sUnionID:  %s  ",tLogon.sUnionID) 
                tBase.Log(" 请求HTTP处理   小程序登录     sNickName: %s  ",tLogon.sNickName)  
                tBase.Log(" 请求HTTP处理   小程序登录     nSex:      %d   ",tLogon.nSex)  
                tBase.Log(" 请求HTTP处理   小程序登录     sHeadimgurl: %s   ",tLogon.sHeaUrl) 
                tLogon.nResult  = 1 
                return tLogon 
            elseif  tonumber(unjson["ErrorCode"]) == 599 then 
                tLogon.nError =  2  -- 网络错误，重新请求
                tBase.Log(" 小程序登录    请求HTTP处理   网络错误需要重启请求    重新授权登录   ")
                return nil 
            else
                tBase.Log(" 小程序登录    请求HTTP处理    Error_Info==2049    请求失败   ErrorCode:   %d ",tonumber(unjson["ErrorCode"]))
                -- 返回 错误数据给客户端。
                return nil 
            end
        else
            tBase.Log(" 小程序登录    请求HTTP处理   json_data Error_Info==2050   异常状态   请求失败  %s  ",json_data)
            return nil 
        end
    end
    -- 捕获异常,输出错误日志
    xpcall(WeiXinLogic.XpcallHttpLogon,tErr.tpLog,json_data)
    if tLogon.nResult == 0  then
        tBase.Log(" 小程序登录    请求HTTP处理    获取数据   失败      Error_Info==2051  ")
        return nil 
    else 
        tBase.Log(" 小程序登录    请求HTTP处理     获取数据    成功    ")
        return tLogon
    end 
end

-- URI 解码
function WeiXinLogic.decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end
-- URI 编码
function WeiXinLogic.encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "%20")
end


-- 加密规则： 微信自动登录  tData:  OpenID + to_ken +  机器码
function WeiXinLogic.EncryptRule(tData)
    tBase.Log(" 微信系统  自动登录   加密规则：    EncryptRule    ")
    local sKey = ""
    tBase.Log(" 微信系统  微信自动登录   加密数据   ")
    -- 拼接数据
    sKey = "1".."#"..tData.Models.."#"..tData.sOpenID.."#"..tData.sUnionID.."#"..tData.sRefresh_Token

    -- tBase.Log(" 微信系统    拼接数据  sKey:  %s ",sKey) 
    sKey =  WeiXinLogic.Encrypt(sKey)   -- 进行  base64 加密
    tBase.Log(" 微信系统    数据加密成功    sKey:  %s    ",sKey)
    return sKey
end

-- 解密规则： 微信自动登录  tData:  OpenID + to_ken +  机器码
function WeiXinLogic.DecodeRule(tData)
    tBase.Log(" 微信系统    解密规则：    DecodeKey    ")
    local sDecodeInfo =  WeiXinLogic.Decode(tData)   -- 进行  base64 解密
    if  sDecodeInfo == nil  then 
        tBase.Log(" 微信系统    解密数据   失败 Decode    Error_Info==2052  ")
        return nil 
    end 
    tBase.Log(" 微信系统    解密后数据    tTable:  %s    ",sDecodeInfo)
    local tDecdde = {}
    local tTable = api.string_split(sDecodeInfo,"#")
    if tTable == nil then 
        tBase.Log(" 微信系统    解析数据失败   tTable     Error_Info==2053 ")
        return nil 
    end  
    for key,value in ipairs(tTable) do
        if key == 1 then 
            if "1" ~= value  then 
                tBase.Log(" 微信系统    解析数据失败   标志位错误  Error_Info==2054 ")
                return nil 
            end 
            tDecdde.Weixin = value  
            tBase.Log(" 微信系统   %d   解析字符串  Weixin:  %s   ",key,tDecdde.Weixin) 

        elseif key == 2 then 
            tDecdde.Models = value 
            tBase.Log(" 微信系统   %d   解析字符串  Models:  %s   ",key,tDecdde.Models) 
        elseif key == 3 then 
            tDecdde.sOpenID = value 
            tBase.Log(" 微信系统   %d   解析字符串  sOpenID:  %s   ",key,tDecdde.sOpenID) 
        elseif key == 4 then 
            tDecdde.sUnionID = value 
            tBase.Log(" 微信系统   %d   解析字符串  sUnionID:  %s   ",key,tDecdde.sUnionID) 
        elseif key == 5 then 
            tDecdde.sRefresh_Token = value 
            tBase.Log(" 微信系统   %d   解析字符串  sRefresh_Token:  %s   ",key,tDecdde.sRefresh_Token) 
        else  
            tBase.Log(" 微信系统    解析字符串    失败     Error_Info==2055 ")
            return nil 
        end  

    end
    tBase.Log(" 微信系统   数据解密成功    ")
    return tDecdde
end

-- 加密： 使用base64进行编码处理
function WeiXinLogic.Encrypt(sData)
    tBase.Log(" 微信  编码    Encrypt  ")   
    tBase.Log(" Base64  编码前: sData:   %s  ",sData) 
    sData = tBase64.encode(sData) 
    tBase.Log(" Base64  编码前: sData:   %s  ",sData) 
    tBase.Log(" Base64  编码前     nLen:  %d",#sData)    
    return sData
end

-- 解密：使用base64进行解码处理
function WeiXinLogic.Decode(sData)
    tBase.Log(" 微信  解码    Decode")    
    tBase.Log(" Base64  解码前: sData:   %s  ",sData) 
    sData = tBase64.decode(sData) 
    tBase.Log(" Base64  解码后: sData:   %s  ",sData) 
    tBase.Log(" Base64  解码后     nLen:  %d",#sData)    
    return sData
end

-- 微信重连 数据保存 redis  ,生成 sKey
function WeiXinLogic.ReconnectionsKey(tData)
    if tData == nil then 
        tBase.Log(" 微信重连   ReconnectionsKey   tData  = nil      Error_Info==2056  ")
        return 0
    end       
    local sKey = "WeiXinConnect_"..tData.nUserID
    local tWriteInfo = {}
    tWriteInfo["sOpenID"] = tData.sOpenID
    tWriteInfo["sUnionID"] = tData.sUnionID
    tWriteInfo["sRefresh_Token"] = tData.sRefresh_Token
    tBase.Log(" 微信重连   ReconnectionsKey  sKey:   %s ",sKey)  
    tBase.Log(" 微信重连   生成sKey       sOpenID:     "..tWriteInfo["sOpenID"])  
    tBase.Log(" 微信重连   生成sKey       sUnionID:    "..tWriteInfo["sUnionID"]) 
    tBase.Log(" 微信重连   生成sKey       sRefresh_Token: "..tWriteInfo["sRefresh_Token"]) 

    -- 将数据  保存redis 中
    WeiXinLogic.WriteRedisData(sKey,tData)
    tBase.Log(" 微信重连   ReconnectionsKey    保存redis  成功   ")
    return sKey
end

-- 微信重连 处理 
function WeiXinLogic.WeiXinReconnection(sKey)
    if sKey == nil  then 
        tBase.Log(" 微信重连   WeiXinReconnection   sKey = nil      Error_Info==2057 ")
        return nil
    end  
    -- 获取 redis 数据
    local tData ={}
    tData = WeiXinLogic.GetRedisData(sKey)
    if tData == nil   then 
        tBase.Log(" 微信重连   WeiXinReconnection   获取 redis 数据  失败     Error_Info==2058  ")
        -- 下发错误协议
        return nil
    end 
    if tData.sOpenID == nil or tData.sUnionID == nil or tData.sRefresh_Token == nil then 
        if tData.sOpenID == nil then 
           tBase.Log(" 微信重连   获取数据   sUnionID  nil   Error_Info==2059 ")
        elseif tData.sUnionID == nil then 
            tBase.Log(" 微信重连   获取数据   sUnionID  nil    Error_Info==2060  ")
        else 
            tBase.Log(" 微信重连   获取数据   sRefresh_Token  nil  Error_Info==2061  ")
        end
        return nil 
    end 
    tBase.Log(" 微信重连   获取数据       sOpenID:        "..tData.sOpenID)  
    tBase.Log(" 微信重连   获取数据       sUnionID:       "..tData.sUnionID)  
    tBase.Log(" 微信重连   获取数据       sRefresh_Token: "..tData.sRefresh_Token)  

    tBase.Log(" 微信重连   WeiXinReconnection   获取 redis 数据  成功  ")
    return tData
end

-- 写入redis 数据:  
function WeiXinLogic.WriteRedisData(sKey,tRedisParam)
    if sKey == nil and tRedisParam == nil then 
        tBase.Log(" 微信重连   WriteRedisData   sKey = nil ,tRedisParam = nil  Error_Info==2062  ")
        return 0
    end  
    -- 写入reids 中
    tBase.m_MyRedisData[1].redis:hmset(sKey,tRedisParam)

    -- 设置  24 小时 时效
    tBase.m_MyRedisData[1].redis:expire(sKey, 60 * 60 * 24)   

    return  1
end

--  获取 redis 数据
function WeiXinLogic.GetRedisData(sKey)
    if sKey == nil  then 
        tBase.Log(" 微信重连   GetRedisData   sKey = nil    Error_Info==2063 ")
        return 0
    end    
    tBase.Log(" 微信重连   GetRedisData   获取redis 数据     ")
    local t = tBase.m_MyRedisData[1].redis:hgetall(sKey)
    if t == nil then
        tBase.Log(" 微信重连  获取 redis 数据    失败   Error_Info==2064  ")
        return nil 
    end 
    return t 
end

-- 微信昵称中的特殊字符处理：   emoji 表情变*    utf8    
function WeiXinLogic.filter_emoji_chars(s)
    local ss = {}
    local k = 1
    while true do
        if k > #s then break end
        local c = string.byte(s,k)
        if not c then break end
        if c<192 then
            table.insert(ss, string.char(c))
            k = k + 1
            -- tBase.Log(" 微信昵称中的特殊字符处理： 11111  ")
        elseif c<224 then
            local c1 = string.byte(s,k+1)
            table.insert(ss, string.char(c,c1))
            k = k + 2
            -- tBase.Log(" 微信昵称中的特殊字符处理： 22222  ")
        elseif c<240 then
            if c>=228 and c<=233 then
                local c1 = string.byte(s,k+1)
                local c2 = string.byte(s,k+2)
                if c1 and c2 then
                    local a1,a2,a3,a4 = 128,191,128,191
                    if c == 228 then a1 = 184
                    elseif c == 233 then a2,a4 = 190,c1 ~= 190 and 191 or 165
                    end
                    if c1>=a1 and c1<=a2 and c2>=a3 and c2<=a4 then
                        table.insert(ss, string.char(c,c1,c2))
                        print(c)
                    else
                        local str = string.char(c,c1,c2)
                        if string.find(str, "[\226][\132-\173]") or string.find(str, "[\227][\138]") or string.find(str, "[\227][\128][\189]") then
                            table.insert(ss,"*")
                            -- tBase.Log(" 微信昵称中的特殊字符处理： 33333   44444  ")
                        else
                            table.insert(ss, string.char(c,c1,c2))
                        end
                    end
                end
            else
                local c1 = string.byte(s,k+1)
                local c2 = string.byte(s,k+2)
                local str = string.char(c,c1,c2)
                if string.find(str, "[\226][\132-\173]") or string.find(str, "[\227][\138]") or string.find(str, "[\227][\128][\189]") then
                    table.insert(ss,"*")
                    -- tBase.Log(" 微信昵称中的特殊字符处理： 33333   55555  ")
                    print(c)
                else
                    table.insert(ss, string.char(c,c1,c2))
                end
            end
            -- tBase.Log(" 微信昵称中的特殊字符处理： 33333333 ")
            k = k + 3
        elseif c<248 then
            k = k + 4
            -- tBase.Log(" 微信昵称中的特殊字符处理： 44444444 ")
            table.insert(ss,"*")
        elseif c<252 then
            k = k + 5
            table.insert(ss,"*")
            -- tBase.Log(" 微信昵称中的特殊字符处理： 555555555 ")
        elseif c<254 then
            k = k + 6
            table.insert(ss,"*")
            -- tBase.Log(" 微信昵称中的特殊字符处理： 666666666 ")
        end
    end
    return table.concat(ss)
end

return WeiXinLogic

