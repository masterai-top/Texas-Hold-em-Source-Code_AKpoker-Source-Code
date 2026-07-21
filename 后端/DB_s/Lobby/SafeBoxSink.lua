package.path = require("./lua/DB_s/Head").path

local tBase = require("base") -- 基础功能接口
local redis = require("redis") -- Redis数据库接口
local api = require("publicApi") -- 共用功能接口
local tname = require("typename") -- 类弄定义接口
local tErr = require("ErrorSink") -- 捕捉错误
local ProtoMgr = require("ProtoManager") -- 协议管理对象 
local cjson = require("cjson") -- 数据交换格式
local tPubUserApi = require("PublicUserInfo") -- 用户数据

SafeBoxSink = {

    _luaFunc = {
        fMyInset = table.insert,
        fMySort = table.sort, 
    },
}

-- 验证银行密码
function SafeBoxSink.SafeBoxPassWordVerifySink(sReturnKey, sData, nLen)

    local ReadData = tBase.GetRP().new(sData, nLen)
    local MainID = ReadData:GetModuleID() 
    local SubID = ReadData:GetMsgID()
 
    local Read = ProtoMgr.PubProto_pb.RUQ_SafePassword()
    Read:ParseFromString(ReadData:GetString())
  
    local nClientID = Read.nClientID  
    local nUserID = Read.nUserID
    local nPassword = Read.nPassword
    local sSql =  Read.sSql
    
    local tData = { Result = 1 }
    tBase.Log(" nUserID: "..nUserID.." 请求验证银行密码sSql:"..sSql.." nPassword:"..nPassword ) 
    local cursor = assert (dbSink.AccountsDB_connect:execute (sSql))  
    repeat
        row = cursor:fetch({},"a")
        while row do
           function SafeBoxSink.GetRes(row)              
                tData.Result = math.modf(row.Result)
                if tData.Result == 0 then 
                    tData.nGold = math.modf(row.nGold) 
                    local tSafeBoxLockTime = {}                        
                    local now_date = os.date("*t",now)-- 获取当前时间
                    tSafeBoxLockTime["nUserID"] = nUserID
                    tSafeBoxLockTime["SafeBoxLockTime"] = os.time{year=now_date.year, month=now_date.month, day=now_date.day, hour=23,min=59,sec=59}
                    tPubUserApi.SetUserBankLockTime(tSafeBoxLockTime)
                    tBase.Log("上锁:"..tSafeBoxLockTime["SafeBoxLockTime"])
                end
           end
           xpcall(SafeBoxSink.GetRes,tErr.tpLog, row)
           row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbSink.AccountsDB_connect:nextres()
    until( cursor == 0 ) 

    tBase.Log(" nGold, Result(0y1n): %s",cjson.encode(tData) )
    local tSend =  ProtoMgr.PubProto_pb.RUP_SafePassword() 
    tSend.nClientID = nClientID
    tSend.nUserID = nUserID
    tSend.Result = tData.Result
    if tData.Result == 0 then 
        tSend.nGold = tData.nGold 
    end
    local s = tBase.GetSP().new(MainID, SubID)
    s:AddString(tSend:SerializeToString())
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    tBase.Log(" 大厅服 银行密码 DB服 返回成功 ")

end

-- 银行明细
function SafeBoxSink.SafeBoxDetailSink(sReturnKey, sData, nLen)

    local ReadData = tBase.GetRP().new(sData, nLen)
    local MainID = ReadData:GetModuleID() 
    local SubID = ReadData:GetMsgID()
 
    local Read = ProtoMgr.PubProto_pb.RUQ_Safe_Detiail()
    Read:ParseFromString(ReadData:GetString())
  
    local nClientID = Read.nClientID  
    local nUserID = Read.nUserID 
    local sSql = string.format("Call SafeBox_Detail(%d)", nUserID) 
    
    local tArr = { }
    tBase.Log(" nUserID: "..nUserID.." 请求验证银行密码sSql:"..sSql) 
    local cursor = assert (dbSink.RecordDB_connect:execute (sSql))  
    repeat
        row = cursor:fetch({},"a")
        xpcall( function(row)
                    while row do 
                        local tmp = {}
                        tmp.UpdateTime = row.UpdateTime
                        tmp.UpdateCount = row.UpdateCount
                        tmp.SourceType = row.SourceType                        
                        SafeBoxSink._luaFunc.fMyInset(tArr,tmp)  
                        SafeBoxSink._luaFunc.fMySort(tArr,function(nTime1,nTime2)
                        if ( nTime1.UpdateTime == nil ) or ( nTime2.UpdateTime == nil ) then 
                                return false
                            else
                                return (  nTime1.UpdateTime >  nTime2.UpdateTime )
                            end
                        end
                        )
                        row = cursor:fetch(row,"a")                    
                    end 
                end, 
        tErr.tpLog, row)
        cursor:close()
        cursor = dbSink.RecordDB_connect:nextres()
    until( cursor == 0 )

    local tSend = ProtoMgr.PubProto_pb.RUP_Safe_Detiail()
    tSend.nClientID = nClientID
    tSend.nUserID = nUserID
    for i = 1, #tArr do
        local tItem = tSend.arrSafeBoxDetailItem:add()
        tItem.UpdateTime = tArr[i].UpdateTime
        tItem.SourceType = math.modf(tArr[i].SourceType)   
        tItem.UpdateCount = math.modf(tArr[i].UpdateCount) 
    end

    local s = tBase.GetSP().new(MainID, SubID)
    s:AddString(tSend:SerializeToString())
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    tBase.Log(" 银行明细操作 DB服 返回成功： 包len:"..s:GetSize().." 数据条数:"..#tArr)

end

-- 重置密码
function SafeBoxSink.SafeBoxResetCodeSink(sReturnKey, sData, nLen)

    local ReadData = tBase.GetRP().new(sData, nLen)
    local MainID = ReadData:GetModuleID() 
    local SubID = ReadData:GetMsgID()
 
    local Read = ProtoMgr.PubProto_pb.RUQ_Safe_ResetCode()
    Read:ParseFromString(ReadData:GetString())
   
    local nClientID = Read.nClientID
    local tmp = {}
    tmp.nUserID = Read.nUserID
    tmp.nType = Read.nType
    tmp.OldPassword = Read.OldPassword 
    tmp.NewPassword = Read.NewPassword
    local sSql =  "Call SafeBox_ReSetCode("..tmp.nUserID..",'"..tmp.OldPassword.."','"..tmp.NewPassword.."')" 

    local nResult = 1
    local cursor = assert (dbSink.AccountsDB_connect:execute (sSql))  
    repeat
        row = cursor:fetch({},"a")
        xpcall( function(row)
                    while row do  
                        nResult = math.floor(row.Result)
                        row = cursor:fetch(row,"a")                    
                    end 
                end,
        tErr.tpLog, row)
        cursor:close()
        cursor = dbSink.AccountsDB_connect:nextres()
    until( cursor == 0 )

    tmp.nResult = nResult
    tBase.Log(" 重新设置密码: %s ",cjson.encode(tmp) )

    local tSend = ProtoMgr.PubProto_pb.RUP_Safe_ResetCode()
    tSend.nClientID = nClientID
    tSend.nUserID = tmp.nUserID
    tSend.nResult = nResult
    tSend.nType = tmp.nType
    local s = tBase.GetSP().new(MainID, SubID)
    s:AddString(tSend:SerializeToString())
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    tBase.Log(" 玩家："..tmp.nUserID.." 银行重置密码操作 DB服 返回成功 ")

end

-- 修改个人信息
function SafeBoxSink.Update_UserInfo(sReturnKey, sData, nLen)

    local ReadData = tBase.GetRP().new(sData, nLen)
    local MainID = ReadData:GetModuleID() 
    local SubID = ReadData:GetMsgID()

    local Read = ProtoMgr.PubProto_1_pb.RUQ_UpdateUserInfo()
    Read:ParseFromString(ReadData:GetString())
   local   nClientID =  Read.nClientID
   local   nUserID   =  Read.nUserID
   local   sSql      =  Read.sSql

    tBase.Log(" 修改个人信息: %s   ",sSql)
    local t = {}
    t.nResult = 0
    t.nType = 0
    t.sContent = ""
    local cursor = assert (dbSink.AccountsDB_connect:execute (sSql))  
    repeat
        row = cursor:fetch({},"a")
        xpcall( function(row)
                    while row do  
                        t.nResult = tonumber(row.Result)
                        t.nType = tonumber(row.nType)
                        t.sContent = tostring(row.sContent)
                        row = cursor:fetch(row,"a")                    
                    end 
                end,
        tErr.tpLog, row)
        cursor:close()
        cursor = dbSink.AccountsDB_connect:nextres()
    until( cursor == 0 )

    tBase.Log(" ---------->   ".. cjson.encode(t) ) 
    local tSend = ProtoMgr.PubProto_1_pb.RUQ_UpdateUserInfo()
    tSend.nClientID = nClientID
    tSend.nUserID = nUserID
    tSend.sSql =  "sql"
    tSend.nType = t.nType
    tSend.sContent =  t.sContent or  "-1"
    tSend.nResult = t.nResult
    local s = tBase.GetSP().new(MainID, SubID)
    s:AddString(tSend:SerializeToString())    
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    tBase.Log(" 修改个人信息:  nResult：  %d   ( 0 成功， -1 失败 )  ",t.nResult )

end



return SafeBoxSink