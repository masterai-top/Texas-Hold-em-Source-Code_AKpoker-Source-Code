--游戏服请求(租用和返还机器人)
local tSrvInfo = require("ServerInfo")
local tBase = require("base")
local ProtoManager = require("ProtoManager")
local tALog = require("AndroidLog")
local NameLibMgr = require("NameLibMgr")
local AndroidMgr = require("AndroidMgr") 
local tAndroidData = require("AndroidData")
local RentalInfo = require("RentalInfo")

local AnProtocol = {}

local function _GetAnCfgStr(nAnCfgId)
    local str = "合集机器人"
    if nAnCfgId and nAnCfgId == 2 then 
        str = "app机器人"
    end 
    return str
end

-- 获取机器人
function AnProtocol.Req_GetAndroid(sClientID, sData, nLen)
    local s = tBase.GetRP().new(sData, nLen)
    local tGetAndroid = ProtoManager.PubProto_pb.Req_GetAndroid()
    tGetAndroid:ParseFromString(s:GetString())
    tALog.Print("_Req_GetAndroid 收到请求机器人 GrpId_%d Index_%s Need_%d [%d-%d] nR_%d %s",tGetAndroid.nGrpId, 
    tGetAndroid.sIndex, tGetAndroid.nCnt, tGetAndroid.nMin, tGetAndroid.nHigh,tGetAndroid.nR or -1,sClientID)

    if tAndroidData.nServerState~=1 then
        local sErr = string.format("_ReturnAndroidToRedis  服务器状态为%d(0:未启用 1:正常 2:维护 3:测试 4:进程没开)，不处理请求",tAndroidData.nServerState)
        tALog.Print(sErr)
        tALog.SendMsgToTG(sErr)
        return
    end
    if not NameLibMgr.IsPrepareFinsh(tGetAndroid.nGrpId) then
        local sErr = string.format("_Req_GetAndroid  分组_%d 昵称库 没有准备好资源,不处理请求",tGetAndroid.nGrpId)
        tALog.Print(sErr)
        tALog.SendMsgToTG(sErr)
        return
    end
    local nAnCfgId = RentalInfo.GetAnCfgId(sClientID,tGetAndroid.nGrpId) 

    local tSend = ProtoManager.PubProto_pb.Rep_GetAndroid()
    tSend.nR = tGetAndroid.nR
    tSend.nGameNeedCnt = tGetAndroid.nGameNeedCnt 
    local arrAndroid = AndroidMgr.PopAndroid(tGetAndroid,nAnCfgId)
    if #arrAndroid < tGetAndroid.nGameNeedCnt  then
        tALog.Print("_Req_GetAndroid    找到的机器人数达不到需求数放回机器人[%d/%d],#arrAndroid:%d",tGetAndroid.nCnt,tGetAndroid.nGameNeedCnt,#arrAndroid)
        for _, v in pairs(arrAndroid) do
            AndroidMgr.PushAndroidToFreeQueue(v)
        end
        arrAndroid = {}
    end
    if #arrAndroid > 0 then
        local strUserId = ""
        for _, v in pairs(arrAndroid) do
            local tAnItem = tSend.arrAndroidItem:add()
            for k, a in pairs(ProtoManager.PubProto_pb.AndroidItem()._setter) do 
                if v[k] then
                    tAnItem[k] = v[k] 
                end
            end
            tAnItem.nMinppty = tGetAndroid.nMin
            tAnItem.nMaxppty = tGetAndroid.nHigh
            tAnItem.nServerId = tSrvInfo.nServerId --记录机器人所属的服务器id
            tAnItem.nChannelID 	=tAnItem.nChannelID or -1
            tAnItem.nShopId 	=tAnItem.nShopId or -1 

            strUserId = strUserId..string.format("%d,",v.nUserId)
            
            if nAnCfgId==1 and (tAnItem.sShopAcc~="" and tAnItem.sShopAcc~="0") then
                tALog.Print("_Req_GetAndroid    请出的机器人异常 nAnCfgId:%d, GrpId:%d nUserId:%d sShopAcc:%s",
                    nAnCfgId,tGetAndroid.nGrpId,tAnItem.nUserId,tAnItem.sShopAcc or "nil")
            elseif nAnCfgId==2 and (tAnItem.sShopAcc=="" or tAnItem.sShopAcc=="0") then
                tALog.Print("_Req_GetAndroid    请出的机器人异常nAnCfgId:%d, GrpId:%d nUserId:%d sShopAcc:%s",
                nAnCfgId,tGetAndroid.nGrpId,tAnItem.nUserId,tAnItem.sShopAcc)
            end
        end
        tALog.Print("_Req_GetAndroid    机器人服务器请出的机器人  GrpId_%d %s",tGetAndroid.nGrpId,strUserId)
        AndroidMgr.SetAndroidLend(sClientID,arrAndroid)
        RentalInfo.ShowGameServerLend(sClientID)
    end
    local s = tBase.GetSP().new(ProtoManager.Sys.ANDROID, ProtoManager.Sub_Android.SUB_REP_GETANDROID)
    s:AddString(tSend:SerializeToString())
    tBase.PostToClient(sClientID, s:GetData(), s:GetSize())  
end

-- 返回机器人
function AnProtocol.Req_SetAndroid(sClientID, sData, nLen)
    local s = tBase.GetRP().new(sData, nLen)
    local tSetAndroid = ProtoManager.PubProto_pb.Req_SetAndroid()
    tSetAndroid:ParseFromString(s:GetString())
    tALog.Print("_Req_SetAndroid    收到别的服放回_%d 个机器人  %s",#tSetAndroid.arrAndroidItem, sClientID)
    local tSend = ProtoManager.PubProto_pb.Rep_SetAndroid()
    local arrAndroid = {}
    for _, v in ipairs(tSetAndroid.arrAndroidItem) do
        local tAnItem = {}
        for a, b in pairs(ProtoManager.PubProto_pb.AndroidItem()._setter) do
            tAnItem[a] = v[a]
            --tALog.Print("获取机器人信息")
        end
        if AndroidMgr.IsServerAndroid(sClientID,tAnItem) then         
            AndroidMgr.ChangeGold(tAnItem)
            table.insert(arrAndroid,tAnItem)
            tSend.arrUserId:append(tAnItem.nUserId)		
        else
            tALog.Print("_Req_SetAndroid    Error ComeIn: UserId:%d", tAnItem.nUserId)
        end
    end
    AndroidMgr.SetAndroidReturn(sClientID,arrAndroid)
    RentalInfo.ShowGameServerLend(sClientID)
    local s = tBase.GetSP().new(ProtoManager.Sys.ANDROID, ProtoManager.Sub_Android.SUB_REP_SETANDROID)
    s:AddString(tSend:SerializeToString())
    tBase.PostToClient(sClientID, s:GetData(), s:GetSize())
end

return AnProtocol