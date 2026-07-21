package.path = require("./lua/Chat/Head").path 
local http  = require("socket.http")  -- Http 服务器 
local cjson = require("cjson")   
local ProtoAux =require("ProtoCoder").Aux

local tTrendMath = require("TrendMath")

require("HttpNB")

-- 玩家功能回调
ClientSink = {} 
 
 

--聊天服<->前端协议
local Chat_pb =ProtoManager.Chat_pb
local Chat_CMD =ProtoManager.Chat_pb.Chat_Proto()
local ToCMD =function(strProto) 
    return Chat_CMD.Main_CMD,Chat_CMD[strProto..'_CMD']
end
ChatAux =ProtoAux:New(Chat_pb,ToCMD)       --生成个全局的编解码辅助对象

-- web后台<->中心服协议
local pb_Backstage =ProtoManager.Backstage_pb
CMD_Backstage =ProtoManager.Backstage_pb.Backstage_Proto()
local ToCMD_Backstage =function(strProto)
    return CMD_Backstage.Main_CMD,CMD_Backstage[strProto..'_CMD']
end
BackstageAux =ProtoAux:New(pb_Backstage,ToCMD_Backstage)
   
-- 启动服务器
function ClientSink.OnStart()     
    -- 设置日志目录:
    local sLogDir =DBInfo.LogDir.."Chat/" .. base.GetPort() .. "-" .. base.GetThreadIndex()
    logger.SetFile(sLogDir ,"Chat",base)
    
    -- 设置全局等级
    logger:setLevel(logging.DEFAULT, "Chat" )
    -- 消息接收处理，不用默认函数
    base.m_MyMonitorFun = ClientSink.onMsgRecv
    -- 注册服务器
    base.RegServer(typename.chat)

    -- 注册协议
    ClientSink.Protocol()   

    base.Log("  Chat  Server Start  ")  
        
    IMMessage.LoadUrlConfig()  
    
    -- 异步http访问
    HttpNB.Init(1101,1102)
   
    --恢复故障记录 
    base.SetTimer(60004,1000*3,1,ChatHandle.RestartService_CloseTable)    
   
    base.SetTimer(60005,1000*10,1,ChatHandle._Timer_CLearList)  

end   

-- 停止服务器
function ClientSink.OnStop() 
     
    ChatHandle._StopServerClear_IM_Group()
    
    base.Sleep(1000) 
    
    -- 取消本地服务器
    base.UnRegServer() 
    

    -- Test()
    
end

-- 有新用户连接
function ClientSink.OnAccept(ClientID, ip, port) 

end

-- 关闭连接
function ClientSink.OnClose(ClientID)
 

end

function ClientSink.OnBackNotice(sReturnKey,Data,nLen)
    local s = tBase.GetRP().new(Data, nLen)
    local nMainID = s:GetModuleID()
    local nSubID = s:GetMsgID()
    local tRead = ProtoManager.Backstage_pb.CloseServerNotice()
    tRead:ParseFromString(s:GetString())
    local nServerId = tonumber(tRead.nServerId) or 0
    local isClose = tRead.isClose
    local nReason = tRead.nReason
    tBase.Log("nServerId:%d isClose:%s nReason:%s", nServerId, tostring(isClose or false), nReason or "")
end

-- 注册协议
function ClientSink.Protocol()   
    
    --网关通知
    tBase.RegFunc(ProtoManager.GatewayPro.GATEWAY,ProtoManager.Sub_GateWay.SUB_GATEWAY_CLIENT_CLOSE,ChatHandle.OnClose)--断线通知
    tBase.RegFunc(ProtoManager.GatewayPro.GATEWAY,ProtoManager.Sub_GateWay.SUB_REQ_GAMESRV_SWICTHCONN,ChatHandle.OnSwicthConn)--切换连接通知

    tBase.RegFunc(CMD_Backstage.Main_CMD, CMD_Backstage.ReqAPI_Table_CMD,ChatHandle.OnReqAPI_Table)              --后台桌子管理请求 (创建与关闭)    
    tBase.RegFunc(Chat_CMD.Main_CMD ,Chat_CMD.ChatLogonReq_CMD,ChatHandle.ChatLogonReq)                          --登陆请求 
    tBase.RegFunc(Chat_CMD.Main_CMD ,Chat_CMD.ChatBackToLobbyReq_CMD,ChatHandle.ChatBackToLobbyReq)              --返回大厅 
    tBase.RegFunc(Chat_CMD.Main_CMD ,Chat_CMD.ChatChangeReq_CMD,ChatHandle.ChatChangeReq)                        --聊天记录请求 
    tBase.RegFunc(Chat_CMD.Main_CMD ,Chat_CMD.ClubChatAppKeyReq_CMD,ChatHandle.ClubChatAppKeyReq)                --俱乐部聊天 APPkey 请求 
    tBase.RegFunc(Chat_CMD.Main_CMD ,Chat_CMD.ChatVedioLogonReq_CMD,ChatHandle.ChatVedioLogonReq)                --俱乐部聊天 APPkey 请求 

    Base.RegFunc(CMD_Backstage.Main_CMD, CMD_Backstage.VideoRoomLeaveNotice_CMD, ChatHandle.VideoRoomLeaveNotice)  --玩家离开语音房

 
    tBase.RegFunc(Chat_CMD.Main_CMD ,Chat_CMD.LogonZhiBoReq_CMD,ChatHandle.LogonZhiBoReq)                        --直播登陆请求 
    tBase.RegFunc(Chat_CMD.Main_CMD ,Chat_CMD.ZhiBoChatReq_CMD,ChatHandle.ZhiBoChatReq)                          --直播聊天请求 

    Base.RegFunc(CMD_Backstage.Main_CMD, CMD_Backstage.CloseServerNotice_CMD, ClientSink.OnBackNotice)   --关服/恢复
    
end

return ClientSink

