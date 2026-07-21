_G.devEnv = "test"
package.path = "../lua/?.lua;./lua/?.lua;" .. package.path
package.path = "../lua/base/?.lua;./lua/base/?.lua;" .. package.path
local m = require("base")           -- 基础功能接口
local th = require("thread")        -- 协程接口
local api = require("publicApi")    -- 共用功能接口
local tSrvInfo = require("ServerInfo")
local cjson = require("cjson")
require("logger") -- 日志对象
require("DBInfo")
require("SetingConfig")
local cs = {}




-- 服务器启动
function OnStartService(tData)
    -- m.Log("_OnStartService tData: %s  ",cjson.encode(tData))
    local tVal = api.Split(tData, ":")
    local runluafile = tVal[1]
    tSrvInfo.nServerId = tonumber(tVal[2])
    tSrvInfo.nPort = tonumber(tVal[3])
    if tVal[4] ~= nil then
        tSrvInfo.nFun = tonumber(tVal[4])
        tSrvInfo.nStype = tonumber(tVal[4])
    end
    tSrvInfo.nIp = tVal[5]
    tSrvInfo.nSocketType = tVal[6]
    tSrvInfo.sName = tVal[7]
    cs = require(runluafile)    -- 功能回调接口

    th.co_create(cs.OnStart)

    SetingConfig.RestartServer(1)

end

-- 服务器关闭
function OnStopService()

    SetingConfig.RestartServer(2)

    th.co_create(cs.OnStop)
    th.co_create(th.CloseAllCoroutine)

end

-- 有新连接
function OnAccept (ClientID,  ip, port)
    th.co_create(cs.OnAccept, ClientID,  ip, port)
end

-- ws 握手信息
function OnHandShake(ClientID, info)
     if cs.OnHandShake then
        th.co_create(cs.OnHandShake, ClientID,  info)
    end
end

-- 关闭连接
function OnClose (ClientID)
    th.co_create(cs.OnClose, ClientID)
end

-- 协议回调函数分发
function dispatch(name, ClientID, buff, len)
    if cs.OnRecv ~= nil then
        local dwStartTime = m.GetTime()

        th.co_create(cs.OnRecv, ClientID, buff, len)

        local dwSpaceTime = m.GetTime() - dwStartTime

        if dwSpaceTime > SetingConfig.RunTimeOut then
            local r = m.GetRP().new(buff, len)
            local MainID = r:GetModuleID()
            local SubID = r:GetMsgID()
            logger:error(string.format("timeout dispatch 11,nServerId:%d ClientID:%d, MainID:%d, SubID:%d, SpaceTime:%d", ClientID,tSrvInfo.nServerId, MainID, SubID, dwSpaceTime))

        end
    end
end

-- 定时器分发
function dispatch_timer (name, timerID)
    local func = m.GetFuncByName(name)
    if func then
        local dwStartTime = m.GetTime()
        th.co_create(m.dispatch_timer, func, timerID)
        local dwSpaceTime = m.GetTime() - dwStartTime
        if dwSpaceTime > SetingConfig.RunTimeOut then
            local sLogfile = m.GetLogPath()
            logger:error(string.format("timeout dispatch_timer,nServerId: %d TimerID:%d, SpaceTime:%d",tSrvInfo.nServerId,timerID, dwSpaceTime))
        end
    end
end

-- 频道监控分发器
function dispatch_channel (name, ChannelName, ChannelData, ChannelDataSize)
    local func = m.GetFuncByName(name)
    if func then
        local dwStartTime = m.GetTime()

        th.co_create(func, ChannelName, ChannelData, ChannelDataSize)

        local dwSpaceTime = m.GetTime() - dwStartTime

        if dwSpaceTime > SetingConfig.RunTimeOut then

            local SrcKey, ClientID, Size, Buff = m.GetTCP(ChannelData, ChannelDataSize)

            local r = m.GetRP().new(Buff, Size)
            local MainID = r:GetModuleID()
            local SubID = r:GetMsgID()
            local sLogfile = m.GetLogPath()
            logger:error(string.format("timeout dispatch_channel,nServerId: %d ClientID:%d, MainID:%d, SubID:%d, SpaceTime:%d",tSrvInfo.nServerId,ClientID, MainID, SubID, dwSpaceTime))

            if tSrvInfo.nStype == 3 then   -- DB服
                th.co_create(cs.OnTimeOutDatabase)
            end
        end
    end
end

-- 错误信息分发器
function dispatch_Error (Type, Data, Len)
    th.co_create(m.ErrorDispatch, Type, Data, Len)
end