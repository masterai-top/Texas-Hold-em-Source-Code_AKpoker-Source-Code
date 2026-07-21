package.path = require("./lua/DB_s/Head").path


local tBase     = require("base")           -- 基础功能接口
local tName     = require("typename")
local tErr      = require("ErrorSink")      -- 捕捉错误
local tPubUsrApi= require("PublicUserInfo") -- 用户信息  
local cjson     = require("cjson")          -- json 
local tProtoMgr = require("ProtoManager")   -- 协议管理对象 

AndroidSink = {
    isFinishInitLoad = false
}

function AndroidSink.LoadAndroidConfig(sReturnKey, sData, nLen)
    local ReadData = tBase.GetRP().new(sData, nLen)
    local nMainID = ReadData:GetModuleID() 
    local nSubID = ReadData:GetMsgID()

    local tLoadCfg = tProtoMgr.PubProto_pb.Req_LoadAndroidCfg()
    tLoadCfg:ParseFromString(ReadData:GetString())

    if tLoadCfg.nLoadVersion == 0 and AndroidSink.isFinishInitLoad == true then
        return
    end
    AndroidSink.isFinishInitLoad = true

    local arr = {}

    local cursor = assert (dbSink.PlatformDB_connect:execute (tLoadCfg.sSql))  
    repeat
        row = cursor:fetch({},"a")
        while row do  
            local tItem = {}
            function GetRes(row)
                tItem.nUserId = tonumber(row.UserID)
                tItem.sAccounts = row.Accounts
                tItem.sNickName = row.NickName
                tItem.sHeadUrl = row.HeadUrl 
                tItem.nSex = tonumber(row.Sex) 
                tItem.nSleep = tonumber(row.Sleep) 
                tItem.nDiamond = tonumber(row.Diamond) 
                tItem.nMinRound = tonumber(row.MinRound) 
                tItem.nMaxRound = tonumber(row.MaxRound) 
                tItem.nMinppty = tonumber(row.Minppty)
                tItem.nMaxppty = tonumber(row.Maxppty)
                tItem.sInvite_Code = row.Invite_Code
                tItem.sLocation = row.Location
                tItem.nStatus = tonumber(row.Status) 
                tItem.nGold = tonumber(row.Gold)
                tItem.nGrpId = tonumber(row.GrpId)
                tItem.sOnlineT = row.OnlineT
            end  
            xpcall(GetRes, tErr.tpLog, row)
            row = cursor:fetch(row,"a")

            table.insert(arr, tItem)
        end
        cursor:close()
        cursor = dbSink.PlatformDB_connect:nextres()
    until( cursor == 0 )

    local nPageSize = 20

    local tSend = nil
    for i = 1, #arr do
        if i % nPageSize == 1 then
            tSend = tProtoMgr.PubProto_pb.Rep_LoadAndroidCfg()
            if #arr - i < nPageSize then
                tSend.isLastPage = true
            else
                tSend.isLastPage = false
            end           
        end
        local t = arr[i]
        local tItem = tSend.arrAndroidItem:add()

        for k, a in pairs(tProtoMgr.PubProto_pb.AndroidItem()._setter) do 
            tItem[k] = t[k] 
        end

        if i % nPageSize == 0 then
            local s = tBase.GetSP().new(tProtoMgr.Sys.DB, tProtoMgr.Sub_DB.SUB_REP_LOADANDROIDCFG)
            s:AddString(tSend:SerializeToString())
            tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())

            tSend = nil
        end
    end

    if tSend then
        local s = tBase.GetSP().new(tProtoMgr.Sys.DB, tProtoMgr.Sub_DB.SUB_REP_LOADANDROIDCFG)
        s:AddString(tSend:SerializeToString())
        tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    end

    tBase.Log("DB服加载机器人完毕:"..#arr)
end

function AndroidSink.GetAndroidNameConfig(sReturnKey, sData, nLen)
    local ReadData = tBase.GetRP().new(sData, nLen)
    local nMainID = ReadData:GetModuleID() 
    local nSubID = ReadData:GetMsgID()

    local tLoadCfg = tProtoMgr.PubProto_pb.Req_LoadAndroidName()
    tLoadCfg:ParseFromString(ReadData:GetString())

    local arr = {}
    local cursor = assert (dbSink.RecordDB_connect:execute (tLoadCfg.sSql)) 
    tBase.Log("hahah sql: %s", tLoadCfg.sSql)
    if type(cursor) ~= "number" then
        repeat
            row = cursor:fetch({},"a")
            while row do  
                local tItem = {}
                function GetRes(row)
                    tItem.sNickName = row.NickName
                    tItem.sHeadUrl = row.UserAvatar 
                    tItem.nSex = tonumber(row.Sex)
                    tItem.nId = tonumber(row.id)
                    tItem.nLanguage = tonumber(row.Language)
                    tItem.sShopAcc = row.sShopAcc or ""
                    tItem.nShopId =tonumber(row.ShopID) or -1
                    tItem.nChannelID=tonumber(row.ChannelID) or -1
                end  
                xpcall(GetRes, tErr.tpLog, row)
                row = cursor:fetch(row,"a")

                table.insert(arr, tItem)
            end
            cursor:close()
            cursor = dbSink.RecordDB_connect:nextres()
        until( cursor == 0 )

        local nPageSize = 20

        local tSend = nil
        for i = 1, #arr do
            if i % nPageSize == 1 then
                tSend = tProtoMgr.PubProto_pb.Rep_LoadAndroidName()
                tSend.nLanguageId = tLoadCfg.nLanguageId
                tSend.nGrpId = tLoadCfg.nGrpId
                if #arr - i < nPageSize then
                    tSend.isLastPage = true
                else
                    tSend.isLastPage = false
                end           
            end
            local t = arr[i]
            local tItem = tSend.arrAndroidItemName:add()

            for k, a in pairs(tProtoMgr.PubProto_pb.AndroidItemName()._setter) do
                tItem[k] = t[k]
            end

            if i % nPageSize == 0 then
                local s = tBase.GetSP().new(tProtoMgr.Sys.DB, tProtoMgr.Sub_DB.SUB_REP_GETANDROIDNAME)
                s:AddString(tSend:SerializeToString())
                tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())

                tSend = nil
            end
        end

        --不满一页的也发送
        if tSend then
            local s = tBase.GetSP().new(tProtoMgr.Sys.DB, tProtoMgr.Sub_DB.SUB_REP_GETANDROIDNAME)
            s:AddString(tSend:SerializeToString())
            tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
        end
    end

    --即使没有数据也有通报
    if #arr == 0 then
        local tSend = tProtoMgr.PubProto_pb.Rep_LoadAndroidName()
        tSend.nLanguageId = tLoadCfg.nLanguageId
        tSend.isLastPage = true
        tSend.nGrpId = tLoadCfg.nGrpId

        local s = tBase.GetSP().new(tProtoMgr.Sys.DB, tProtoMgr.Sub_DB.SUB_REP_GETANDROIDNAME)
        s:AddString(tSend:SerializeToString())
        tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    end  
end

function AndroidSink.SaveAndroidItem(sReturnKey, sData, nLen)
    local ReadData = tBase.GetRP().new(sData, nLen)
    local nMainID = ReadData:GetModuleID() 
    local nSubID = ReadData:GetMsgID()

    local tL = tProtoMgr.PubProto_pb.Req_SaveAndroidItem()
    tL:ParseFromString(ReadData:GetString())

    local tItem = {}
    for _, v in ipairs(tL.arrAndroidItem) do
        for a, b in pairs(tProtoMgr.PubProto_pb.AndroidItem()._setter) do
            tItem[a] = v[a]
        end
        break
    end

    if next(tItem) == nil then return end

    local sSql = string.format('Call SaveAndroidItem(%d, "%s", "%s", "%s", %d, %d, %d, %d, %d,'.. 
        '%d, %d, "%s", "%s", %d, %d, %d, "%s")', 
        tItem.nUserId, tItem.sAccounts, tItem.sNickName, tItem.sHeadUrl, tItem.nSex, tItem.nSleep,
        tItem.nDiamond, tItem.nMinRound, tItem.nMaxRound, tItem.nMinppty, tItem.nMaxppty,
        tItem.sInvite_Code, tItem.sLocation, tItem.nStatus, tItem.nGold, tItem.nGrpId,
        tItem.sOnlineT)

    assert(dbSink.RecordDB_connect:execute (sSql))

    tBase.Log("完成机器人数据保存")
end

function AndroidSink.CleanMysqlAndroidData(sReturnKey, sData, nLen)
    local ReadData = tBase.GetRP().new(sData, nLen)
    local nMainID = ReadData:GetModuleID() 
    local nSubID = ReadData:GetMsgID()

    local tL = tProtoMgr.PubProto_pb.Req_CleanAndroidMysql()
    tL:ParseFromString(ReadData:GetString())

    local sSql = string.format('delete from AndroidSrvInfo where SrvId = %d', tL.nSrvId)
    assert(dbSink.RecordDB_connect:execute (sSql))
end

function AndroidSink.UpdateMysqlAndroidData(sReturnKey, sData, nLen)
    local ReadData = tBase.GetRP().new(sData, nLen)
    local nMainID = ReadData:GetModuleID() 
    local nSubID = ReadData:GetMsgID()

    local tL = tProtoMgr.PubProto_pb.Req_UpdateAndroidMysql()
    tL:ParseFromString(ReadData:GetString())

    local sSql = string.format("Call UpdateAndroidSrvInfo(%d, %d, '%s', %d, %d, %d, %d ,%d)", 
        tL.nSrvId, tL.nGrpId, tL.sIndex, tL.nTotal, tL.nWorking, tL.nRelax, tL.nLending, tL.nCanUse)
    tBase.Log("执行更新机器人 %s",sSql)

    assert(dbSink.RecordDB_connect:execute (sSql))
end

return AndroidSink
