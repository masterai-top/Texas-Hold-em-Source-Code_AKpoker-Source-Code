--机器人服打印，发送日志到tg群
local Define = require("Define")
local tSrvInfo = require("ServerInfo")
local tBase = require("base")

local AndroidLog = {
    tTgMsgNotify = {}
}

function AndroidLog.Print(str,...)
	tBase.Log(Define.ServerName.."=>"..str,...) 
end

-- 发送消息到tg群
function AndroidLog.SendMsgToTG(skey,sErr,nSpaceTime)
    if not sErr then
        sErr = skey
    end
    if not nSpaceTime then
        nSpaceTime = Define.nSpaceTimeTg
    end
    if skey and sErr then
        local isSend = true
        local nNowTime = os.time()

        for i=#AndroidLog.tTgMsgNotify,1,-1 do
            local TgMsg = AndroidLog.tTgMsgNotify[i]

            if nNowTime - TgMsg.nTime > TgMsg.nSpaceTime then
                --清除时间间隔够的
                table.remove(AndroidLog.tTgMsgNotify,i)
            else
                --时间间隔不够的
                if TgMsg.skey == skey then
                    isSend = false
                end
            end
        end
        
        if isSend then
            table.insert(AndroidLog.tTgMsgNotify,{skey=skey,sErr=sErr,nTime=nNowTime,nSpaceTime=nSpaceTime})
            Base._OnMonitorInfo(Define.ServerName..sErr,tSrvInfo.nServerId) 
        end

        return isSend
    end
    return false
end

return AndroidLog