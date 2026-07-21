-- 登录和注册
package.path = require("./lua/DB_s/Head").path

local tBase         = require("base")           -- 基础功能接口
local api       = require("publicApi")    -- 共用功能接口
local tWeixin       = require("WeiXinLogic")         --微信系统
local tErr          = require("ErrorSink")       -- 捕捉错误
local tPubUserApi   = require("PublicUserInfo")    --玩家数据同步
local cjson         = require("cjson") 
local tname         = require("typename")     -- 类弄定义接口
local ProtoMgr      = require("ProtoManager") -- 协议管理对象  
local http        = require("socket.http")  -- Http 服务器


LogonSink = {}

function SafeExecute(func, funcName, ...)
    local success, result = pcall(func, ...)
    if not success then
        tBase.Log(string.format("函数 %s 执行失败: %s", funcName or "未知", result))
        return false, result
    end
    return true, result
end


local function GetLogonBy_Sql(sSql, tData)
    local tLogon={}
    local cursor = assert (dbSink.AccountsDB_connect:execute(sSql))
    repeat
        row = cursor:fetch({},"a")
        while row do
            function LogonSink.GetRes(row)
                tLogon.nErrCode = tonumber(row.nErrCode)  -- 返回的错误码
                if row.sErrorCode or row.ErrorInfo then
                    tBase.Log("_GetLogonBy_Sql ErrorCode:%s ErrorInfo:%s", row.sErrorCode, row.ErrorInfo or "")
                    return tLogon
                end
                if  tLogon.nErrCode  == 1 then
                    tLogon.UserID = tonumber(row.strUserID)
                    tLogon.sNickName = row.sNickName        --昵称
                    tLogon.nSex = tonumber(row.nSex)        --性别
                    tLogon.sFaceID = row.sFaceID   -- 注意 账号类型： 账号 1，微信 2   
                    tLogon.nGold     = tonumber(row.Gold) or 0       --金币数据  
                    tLogon.sPhone = row.sMobilePhone
                    if tLogon.sPhone == "" then tLogon.sPhone = "0" end 
                    tLogon.nServerId = tonumber(row.nServerId)   
                    tLogon.sIp = row.sIp
                    tLogon.nPort = tonumber(row.nPort) 
                    tLogon.nTimeDiff = tonumber(row.nTimeDiff)  --每天登陆的时间差： 大于 0 才发邮件     
                    tLogon.sChannel = row.sChannel  
                    tLogon.nShopID = tonumber(row.nShopID)    -- 分店; 表Accounts_InFo中的ChannelID
                    tLogon.nAccountType = tonumber(row.AccountType) -- 账号类型： 1 正式玩家，2测试  
                    tLogon.sShopAccount = row.sShopAccount or ""  
                    tLogon.nDiamonds     = tonumber(row.nDiamonds) or 0       --钻石数据
                    tLogon.nExp     = tonumber(row.nExp) or 0       --经验数据
                    tLogon.nSkin1     = tonumber(row.nSkin1) or 1000       --经验数据   
                    tLogon.nShopIdReal =tonumber(row.nShopIdReal) or -10   --表Accounts_InFo中的ShopID
                    tLogon.nEmail = row.sEmail
                    tLogon.sSafePassWard = row.sSafePassWard or ""
                    tLogon.nRegisTime = row.nRegisTime or ""
                    tLogon.sAddress = row.sAddress or ""
                    tBase.Log("_GetLogonBy_Sql  登录UserID_%d  info_%s ",tLogon.UserID,cjson.encode(tLogon))
                else
                    tLogon.UserID = tonumber(row.strUserID)
                    tBase.Log("_GetLogonBy_Sql 登录 UserID_%d  nErrCode:  %d  nAccountType_%d ",tLogon.UserID,tLogon.nErrCode,tData.nAccountType)
                    if tLogon.nErrCode == 3 then -- 封号： 获取解封时间   
                        tLogon.sUnsetTime = row.dEndTime
                        tBase.Log("_GetLogonBy_Sql 登录UserID_%d 封号了,解封时间 sUnsetTime:  %s",tLogon.UserID,tLogon.sUnsetTime)
                    end
                    if tData.nAccountType == 0 and tLogon.nErrCode == 5 then   -- 游客登录  没有数据  -- 注册流程
                        tData.sAccounts = row.strAccounts
                        tData.sPassword = row.LogonPassword
                        tData.sChannel= row.sLogon_Channel
                        tData.sLogon_IP= row.sLogon_IP
                    end
                    if tData.nAccountType == 7 and tLogon.nErrCode == 5 then -- tg自动注册登录
                    end
                end
            end
            xpcall(LogonSink.GetRes,tErr.tpLog, row)
            row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbSink.AccountsDB_connect:nextres()
    until( cursor == 0 )
    return tLogon
end

-- 登录返回
local function LogonReturn(sReturnKey,tData)
    local pLogon = ProtoMgr.PubProto_pb.Rup_Logon()
    pLogon.ClientID = tData.sClientID
    pLogon.UserID   = tData.UserID
    pLogon.nErrCode = tData.nErrCode
    pLogon.sPlatform =tData.sPlatform
    if tData.nErrCode == 3 then   -- 封号数据
        pLogon.sUnsetTime = tData.sUnsetTime
    end
    local s = tBase.GetSP().new(tData.MainID, tData.SubID)
    s:AddString(pLogon:SerializeToString())
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())  
    tBase.Log("_LogonReturn 登录失败: %d   sSql: %s ",tData.nErrCode,tData.sSql)   
    return
end

-- 账号登录和 游客登录 + tg自动注册登录
function LogonSink.RequstAccountLogon(sReturnKey, sData, nLen)
    local ReadData = tBase.GetRP().new(sData, nLen)
    local tData = {}
    tData.MainID = ReadData:GetModuleID()
    tData.SubID = ReadData:GetMsgID()
    local rLogon = ProtoMgr.PubProto_pb.Ruq_Logon()
    rLogon:ParseFromString(ReadData:GetString())
    tData.sClientID     = rLogon.ClientID
    tData.sSql          = rLogon.sSql
    tData.sSql2          = rLogon.sSql2
    tData.nAccountType  = rLogon.nAccountType
    tData.Account_Type  = rLogon.nAccountType
    tData.sToken        =rLogon.sToken
    tData.nShopId       =rLogon.nShopId
    tData.sPlatform     =rLogon.sPlatform
    tData.sChannel      =rLogon.sChannel
    if tData.nAccountType == 1 or tData.nAccountType == 7 then -- 账号 TG
        local tLogon = GetLogonBy_Sql(tData.sSql, tData)
        if tLogon.nErrCode == 1 then   -- 转发
            local Send = ProtoMgr.PubProto_pb.Req_AssignDBLogonAccount()
            Send.sReturnKey = sReturnKey
            Send.nUserId = tLogon.UserID
            Send.sLogonData = cjson.encode(tData)
            local s = tBase.GetSP().new(ProtoMgr.Sys.DB,ProtoMgr.Sub_DB.SUB_REQ_ASSIGNDBLOGONACCOUNT)
            s:AddString(Send:SerializeToString())

            local sKey = tBase.GetUserIdSrcKey(tname.db,tLogon.UserID)
            if sKey then
                tBase.Log("_RequstAccountLogon  指定DB服登录 UserID_%d sKey: %s ",tLogon.UserID,sKey)
                tBase.PostToServer(sKey,0,s:GetData(), s:GetSize()) --转发消息到内网
            else
                tBase.Log("_RequstAccountLogon  指定DB服登录 UserID_%d 随机  ",tLogon.UserID)
                tBase.PostDatasByType(tname.db, 0,tLogon.UserID, s:GetData(), s:GetSize())
            end
            return
        else
            if tData.nAccountType == 0 and tLogon.nErrCode == 5 then
                tBase.Log("_RequstAccountLogon 游客注册")
                LogonSink.Tourist_Register(sReturnKey,tData)
                return
            end
            if tData.nAccountType == 7 and tLogon.nErrCode == 5 then
                tBase.Log("_RequstAccountLogon TG注册")
                LogonSink.Tg_Register(sReturnKey, tData)
                return
            end
            if tLogon.nErrCode==3 then
                tData.sUnsetTime = tLogon.sUnsetTime or ""
                tBase.Log("_RequstAccountLogon 账号封禁 UserID_%d sUnsetTime:%s",tLogon.UserID,tData.sUnsetTime)
            elseif tLogon.nErrCode==100 then
                tLogon.nErrCode = 3
                tData.sUnsetTime = tLogon.sUnsetTime or ""
                tBase.Log("_RequstAccountLogon IP封禁 UserID_%d sUnsetTime:%s",tLogon.UserID,tData.sUnsetTime)
            elseif tLogon.nErrCode==101 then
                tLogon.nErrCode = 3
                tData.sUnsetTime = tLogon.sUnsetTime or ""
                tBase.Log("_RequstAccountLogon GPS封禁 UserID_%d sUnsetTime:%s",tLogon.UserID,tData.sUnsetTime)
            end
            tData.UserID = tLogon.UserID or -1
            tData.nErrCode = tLogon.nErrCode or -1
            LogonReturn(sReturnKey,tData)
        end
        return
    end
    LogonSink.RequstLogon(sReturnKey,tData)
    return 0
end

-- tg自动注册登录
function LogonSink.TgAfterLogon(sReturnKey, tData)
    local tLogon = GetLogonBy_Sql(tData.sSql, tData)
    if tLogon.nErrCode == 1 then   -- 转发
        local Send = ProtoMgr.PubProto_pb.Req_AssignDBLogonAccount()
        Send.sReturnKey = sReturnKey
        Send.nUserId = tLogon.UserID
        Send.sLogonData = cjson.encode(tData)
        local s = tBase.GetSP().new(ProtoMgr.Sys.DB,ProtoMgr.Sub_DB.SUB_REQ_ASSIGNDBLOGONACCOUNT)
        s:AddString(Send:SerializeToString())

        local sKey = tBase.GetUserIdSrcKey(tname.db,tLogon.UserID)
        if sKey then
            tBase.Log("tgAfterLogon  指定DB服登录 UserID_%d sKey: %s ",tLogon.UserID,sKey)
            tBase.PostToServer(sKey,0,s:GetData(), s:GetSize()) --转发消息到内网
        else
            tBase.Log("tgAfterLogon  指定DB服登录 UserID_%d 随机  ",tLogon.UserID)
            tBase.PostDatasByType(tname.db, 0,tLogon.UserID, s:GetData(), s:GetSize())
        end
        return
    else
        if tLogon.nErrCode==3 then
            tData.sUnsetTime = tLogon.sUnsetTime or ""
            tBase.Log("tgAfterLogon 账号封禁 UserID_%d sUnsetTime:%s",tLogon.UserID,tData.sUnsetTime)
        elseif tLogon.nErrCode==100 then
            tLogon.nErrCode = 3
            tData.sUnsetTime = tLogon.sUnsetTime or ""
            tBase.Log("tgAfterLogon IP封禁 UserID_%d sUnsetTime:%s",tLogon.UserID,tData.sUnsetTime)
        elseif tLogon.nErrCode==101 then
            tLogon.nErrCode = 3
            tData.sUnsetTime = tLogon.sUnsetTime or ""
            tBase.Log("tgAfterLogon GPS封禁 UserID_%d sUnsetTime:%s",tLogon.UserID,tData.sUnsetTime)
        end
        tData.UserID = tLogon.UserID or -1
        tData.nErrCode = tLogon.nErrCode or -1
        LogonReturn(sReturnKey,tData)
    end
end

-- 指定DB 登录账号
function LogonSink.AssignDBLogonAccount(sClientID, sData, nLen)
    local ReadData = tBase.GetRP().new(sData, nLen)
    local Read = ProtoMgr.PubProto_pb.Req_AssignDBLogonAccount()
    Read:ParseFromString(ReadData:GetString())
    local sReturnKey = Read.sReturnKey
    local nUserId = Read.nUserId
    local tData = cjson.decode(Read.sLogonData)
    tBase.Log("_AssignDBLogonAccount  指定DB服登录 nUserId_%d  sClientID_%s  ",nUserId,sClientID)
    LogonSink.RequstLogon(sReturnKey,tData)
    return
end 

-- 账号注册 
function LogonSink.RequstAccountRegister(sReturnKey, sData, nLen)
    local tData = {}
    local ReadData = tBase.GetRP().new(sData, nLen)
    tData.MainID = ReadData:GetModuleID() 
    tData.SubID = ReadData:GetMsgID()

    local rRegist = ProtoMgr.PubProto_pb.Ruq_Regist()
    rRegist:ParseFromString(ReadData:GetString())
    tData.sClientID     = rRegist.ClientID
    tData.sSql          = rRegist.sSql
    tData.Account_Type  = rRegist.nAccountType
    tData.sPlatform =rRegist.sPlatform
    LogonSink.RequstRegister(sReturnKey,tData)
    return 0
end

function SqlExecut(sSql,dbConnect)
    local arrRows ={} 
    local cursor,msg =assert(dbConnect:execute (sSql))
    if cursor==nil or type(cursor)=='number' then
        return
    end
    repeat
        local row = cursor:fetch({},"a")
        while row do
          table.insert(arrRows,tBase.DeepCopy(row))
           row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbConnect:nextres()
    until( cursor == 0 )    
    return arrRows
end

local function WebDB_SqlExecute(sSql,isForRead)
    local connection =dbSink.WebDB_connect
    if isForRead then
        connection =dbSink.GetDbConnectForRead("DJH_WebDB")
    end
    return SqlExecut(sSql,connection)
end

--观察类型登陆
local function GetLogonBy_Create(sChannel)
    local tLogon={}
    tLogon.nErrCode  = 1                         -- 返回的错误码   
    tLogon.UserID = tPubUserApi.GetAVisitorUserId()
    tLogon.sNickName = "dmlzaXRvcg=="           --昵称
    tLogon.nSex = 1                             --性别
    tLogon.sFaceID = "1"                        --注意 账号类型： 账号 1，微信 2  
    -- 获取财富数据
    tLogon.nGold     =  0                        --金币数据  
    tLogon.sPhone = "0"
    tLogon.nServerId = 0  
    tLogon.sIp = ""
    tLogon.nPort = 0 
    tLogon.nTimeDiff = 0                        --每天登陆的时间差： 大于 0 才发邮件     
    tLogon.sChannel =sChannel or "-1"   
    tLogon.nAccountType = 4                     -- 账号类型： 1 正式玩家，2测试
    tLogon.nExp = 0                             -- 经验
    tLogon.nDiamonds = 0                        -- 钻石
    local sql =string.format("SELECT Id,ParentId FROM DJH_WebDB.Group WHERE ChannelKey='%s';",sChannel)
    local arrRow =WebDB_SqlExecute(sql,true)
    local nShopID =-1
    local nShopIdReal=-10
    if #arrRow==1 then
        nShopID =tonumber(arrRow[1].Id) or -2
        nShopIdReal=tonumber(arrRow[1].ParentId) or -10
    end
    tLogon.nShopID = nShopID                        -- 分店
    tLogon.nShopIdReal=nShopIdReal
    tBase.Log("_GetLogonBy_Create UserID:%d sChannel:%s nShopID:%d",tLogon.UserID,sChannel,nShopID)
    return tLogon
end

-- 登录流程：  账号和微信  和  游客  共用部分
function LogonSink.RequstLogon(sReturnKey,tData)
    tBase.Log("_RequstLogon  登录账号 nAccountType_%d  sSql: %s ", tData.nAccountType,tData.sSql)
    local tLogon =nil
    local isNoDbCopy =false
    if  tData.nAccountType==4 then             --观察类型登陆
        tLogon = GetLogonBy_Create(tData.sChannel)
        isNoDbCopy=true
    else
        tLogon=GetLogonBy_Sql(tData.sSql, tData)
        if tData.nAccountType == 0 and tLogon.nErrCode == 5 then
            tBase.Log("_RequstLogon 游客注册")
            LogonSink.Tourist_Register(sReturnKey,tData)
            return
        end
    end
    if tLogon.nErrCode == 1 then
        local tUserBasic = {}
        tUserBasic["nUserID"]  = tLogon.UserID
        tUserBasic["sClientID"] = tData.sClientID
        tUserBasic["sNickName"] = tLogon.sNickName              --昵称 
        tUserBasic["nSex"]       = tLogon.nSex                   --性别  
        tUserBasic["sFaceID"]    = tLogon.sFaceID                --头像
        tUserBasic["sPhone"]     = tLogon.sPhone
        tUserBasic["sChannel"]   = tLogon.sChannel
        tUserBasic["nShopID"]    = tLogon.nShopID
        tUserBasic["nAccountType"]    = tLogon.nAccountType
        tUserBasic["isAndroid"]  = 0   --是否机器人 真人是0
        tUserBasic["Account_Type"]  =  tData.nAccountType -- 账号类型
        tUserBasic["sShopAccount"]  = tLogon.sShopAccount
        tUserBasic["sPlatform"] = tData.sPlatform or ""
        tUserBasic["nShopIdReal"] =tLogon.nShopIdReal
        tUserBasic["nEmail"] = tLogon.nEmail or ""
        tUserBasic["sSafePassWard"] = tLogon.sSafePassWard or ""
        tUserBasic["nRegisTime"] = tLogon.nRegisTime
        tUserBasic["sAddress"] = tLogon.sAddress
        tUserBasic["nOnline"] = 1
        tPubUserApi.PersistUserInfo(tLogon.UserID)
        tPubUserApi.UpdateUserData(tUserBasic)
        local tUserTreasure = {}
        tUserTreasure["nUserID"] = tLogon.UserID
        tUserTreasure["nGold"] = tLogon.nGold --金币
       
        tPubUserApi.UpdateUserGold(tLogon.UserID,tLogon.nGold,1,isNoDbCopy)   --设置redis玩家金币          
        tPubUserApi.UpdateUserSkin(tLogon.UserID,{{nPos=1,nItemID=tLogon.nSkin1 or 1000}})    --设置redis玩家皮肤  

        SafeExecute(LogonSink.GetClubUserPublicInfo, "GetClubUserPublicInfo", tLogon.UserID)
        SafeExecute(LogonSink.GetUserMarkInfo, "GetUserMarkInfo", tLogon.UserID)
        -- LogonSink.GetClubUserPublicInfo(tLogon.UserID)
        -- LogonSink.GetUserMarkInfo(tLogon.UserID)
        tBase.Log("_RequstLogon   Mysql财富数据_%s",cjson.encode(tUserTreasure))
    else
        tData.UserID = tLogon.UserID or -1
        tData.nErrCode = tLogon.nErrCode or -1
        tData.sUnsetTime = tLogon.sUnsetTime or ""
        LogonReturn(sReturnKey,tData)
        return
    end 
    local pLogon = ProtoMgr.PubProto_pb.Rup_Logon()
    pLogon.ClientID = tData.sClientID
    pLogon.UserID   = tLogon.UserID
    pLogon.nErrCode = tLogon.nErrCode
    pLogon.sPlatform =tData.sPlatform
    pLogon.nTimeDiff = tLogon.nTimeDiff
    pLogon.nServerId = tLogon.nServerId
    pLogon.nPort     = tLogon.nPort
    pLogon.sIp       = tLogon.sIp
    pLogon.sToken=tData.sToken
    pLogon.nLoginCount = 2
    if tData.isNew then
        pLogon.nLoginCount = 1
    end
    local s = tBase.GetSP().new(tData.MainID,tData.SubID)
    s:AddString(pLogon:SerializeToString())
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    tBase.Log("_RequstLogon 登录成功  UserID: %d  nAccountType_%d ",tLogon.UserID, tData.nAccountType)
    return 0
end

local function CallProceduerSql(sProceduerName,arrParameter)
    local str ="call "..sProceduerName.."("
    for dex,v in ipairs(arrParameter) do
        if type(v)=='string' then
            str =str.."'"..v.."'"
        else
            str =str..v
        end
        if dex ~=#arrParameter then
            str =str..","
        end
    end
    return str..")"
end

function LogonSink.Tourist_Register(sReturnKey,tData)
    tBase.Log("_Tourist_Register   游客注册  sChannel:  "..tData.sChannel)
    local arrParameter ={}
    arrParameter[1] =tData.sAccounts
    arrParameter[2] =tData.sPassword
    arrParameter[3] =1              --tData.nAccountType
    arrParameter[4] ="贵宾"         --sNickName
    arrParameter[5] ="1"            --faceId
    arrParameter[6] =0              --sex
    arrParameter[7] =tData.sChannel or "default"      --sChannel
    arrParameter[8] = "109.206.246.145" --tData.sLogon_IP or "192.168.0.1"  --ip
    arrParameter[9] ="sPhone"       --sPhoneType
    arrParameter[10] ="1234567"     --sSystemVersion
    arrParameter[11] ="12345678"    --sModels
    arrParameter[12] =tData.nShopId or 1--(tData.nShopId 不应该为nil)
    local sSql =CallProceduerSql("Regist_Accounts",arrParameter) --x 
    tData.MainID=ProtoMgr.Sys.DB
    tData.SubID=ProtoMgr.Sub_DB.SUB_REQ_ACCOUNT_REGISTER
    tData.sSql=sSql
    LogonSink.RequstRegister(sReturnKey, tData)
    return
end

function LogonSink.Tg_Register(sReturnKey, tData)
    tBase.Log("Tg_Register TG注册 sChannel: " .. tData.sChannel)
    -- tData.MainID=ProtoMgr.Sys.DB
    -- tData.SubID=ProtoMgr.Sub_DB.SUB_REQ_ACCOUNT_REGISTER
    -- tData.sSql = tData.sSql2
    tData.isNew = true
    LogonSink.RequstRegister(sReturnKey, tData)
end

local function convert_telegram_avatar_url(photo_url)
    if not photo_url or type(photo_url) ~= "string" then
        return "1"
    end
    -- 提取 SVG 文件名（不含扩展名）
    local filename = photo_url:match("/([^/]+)%.svg$")
    if not filename then
        return photo_url -- 如果不是 SVG 格式，返回原链接
    end
    -- 转换为 aws 存储url
    local png_url = "https://res.kkpoker.life/icon/" .. filename .. ".svg"
    return png_url
end

local function sendBack(nUserId, photo_url)
    if #photo_url < 5 then
        return
    end
    pcall(function()
        local back_url = string.format("http://127.0.0.1:8888/api/IMServer/SaveUserImage?uid=%d&url=%s", nUserId, photo_url)
        tBase.LogT({"推送头像信息", back_url})
        http.request(back_url)
    end)
end

-- 注册流程 ：   账号和微信 共用部分   
function LogonSink.RequstRegister(sReturnKey, tData)
    local MainID = tData.MainID
    local SubID = tData.SubID
    local Account_Type = tData.Account_Type
    local sClientID = tData.sClientID
    local sSql = tData.sSql
    if tData.nAccountType == 7 then
        sSql = tData.sSql2
    end

    local tUserBasic = {}      --玩家基本数据玩家统计数据
    local tUserTreasure = {}   --玩家财富数据
    local tUserStatisti = {}   --玩家统计数据 
    local tRegist = {}
    local sqlRes = {}
    local nIndex = 0
    tBase.Log("_RequstRegister  注册SQL: %s",sSql)
    local cursor = assert (dbSink.AccountsDB_connect:execute(sSql))
    repeat
        row = cursor:fetch({},"a")
        while row do
           function LogonSink.GetRes(row)
                 tRegist.nErrCode = tonumber(row.ErrCode)   -- 错误码 1 正确，其他失败
                 if tRegist.nErrCode == 1 then 
                    tRegist.UserID = tonumber(row.UserID)                
                    tRegist.sNickName = row.sNickName  
                    tRegist.nSex= tonumber(row.nSex) 
                    tRegist.sFaceID= row.sFaceID         
                    tRegist.nGold = row.Gold       
                    tRegist.sChannel = row.Channel 
                    tRegist.nShopID = row.nShopID
                    tRegist.nAccountType = row.Account_Type
                    tRegist.nRegistIP = row.RegistIP
                    tRegist.nShopIdReal =tonumber(row.nShopIdReal) or -10
                    tBase.Log("_RequstRegister UserID: %d   NickName: %s  nSex:  %d nGold:  %d nShopIdReal:%d", tRegist.UserID, tRegist.sNickName, tRegist.nSex,tRegist.nGold,tRegist.nShopIdReal) 
                    tBase.Log("_RequstRegister sFaceID:"..tRegist.sFaceID.." nShopID:"..tRegist.nShopID.." RegistIP:"..tRegist.nRegistIP) 
                else  
                    local ErrorCode  = row.ErrorCode   -- mysql 错误码 
                    local ErrorInfo  = row.ErrorInfo   -- mysql 错误信息
                    if ErrorCode and ErrorInfo then                     
                        tBase.Log("_RequstRegister 注册失败   错误代码ErrorCode %s   ErrorInfo  %s   ",ErrorCode,ErrorInfo)
                    end
                end           
           end  
           xpcall(LogonSink.GetRes,tErr.tpLog, row)
           tBase.Log("_RequstRegister  注册错误代码nErrCode:%d",tRegist.nErrCode)
            nIndex      = nIndex + 1
            row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbSink.AccountsDB_connect:nextres()
    until( cursor == 0 )

    if tRegist.nErrCode == 1 then
        local sFaceID = tRegist.sFaceID
        if tData.nAccountType == 7 then
            sFaceID = convert_telegram_avatar_url(tRegist.sFaceID)
            sendBack(tRegist.UserID, tRegist.sFaceID)
        end
        tUserBasic["nUserID"]  = tRegist.UserID
        tUserBasic["sClientID"] = sClientID
        tUserBasic["sNickName"] = tRegist.sNickName              --昵称 
        tUserBasic["nSex"]     = tRegist.nSex                   --性别  
        tUserBasic["sFaceID"]  = sFaceID                          --性别 
        tUserBasic["Account_Type"]  = Account_Type             -- 账号类型
        tUserBasic["sChannel"]  = tRegist.sChannel      
        tUserBasic["nShopID"] = tRegist.nShopID                 --表Accounts_InFo中的ChannelID
        tUserBasic["nAccountType"] = tRegist.nAccountType
        tUserBasic["sPlatform"] = tData.sPlatform or ""
        tUserBasic["nShopIdReal"]=tRegist.nShopIdReal           --表Accounts_InFo中的ShopID
        tUserBasic["nEmail"] = ""
        tUserBasic["sSafePassWard"] = ""
        tUserBasic["nRegisTime"] = tRegist.nRegisTime
        tUserBasic["sAddress"] = ""
        tUserBasic["nOnline"] = 1
        --玩家财富数据
        tUserTreasure["nUserID"] = tRegist.UserID
        tUserTreasure["nGold"]       = tRegist.nGold        --金币 
        -- 统计数据 
        tUserStatisti["nUserID"] = tRegist.UserID
        tUserStatisti["nSumIning"] =  0
        tUserStatisti["nWinRecord"] = 0
        tUserStatisti["nHuPaiIning"] = 0
        tUserStatisti["nHuPaiRate"] = 0
        tUserStatisti["nLastkeepWin"] = 0
        tUserStatisti["sBestPaiXing"] = ""
        
        tBase.Log("_RequstRegister 玩家基本数据：  UserID  %d , 昵称： %s  , 性别： %d  分店: %d 渠道:%s ",
        tUserBasic["nUserID"],tUserBasic["sNickName"],tUserBasic["nSex"],tUserBasic["nShopID"],tUserBasic["sChannel"] )

        tBase.Log("_RequstRegister  财富数据   金币： %d",tUserTreasure["nGold"])
 
        -- 将用户数据写入redis 中
        tPubUserApi.PersistUserInfo(tRegist.UserID)
        tPubUserApi.UpdateUserData(tUserBasic)

        --设置redis玩家金币
        tPubUserApi.UpdateUserGold(tUserTreasure.nUserID,tUserTreasure.nGold,1)
 
        --设置redis玩家皮肤
        tPubUserApi.UpdateUserSkin(tRegist.UserID,{{nPos=1,nItemID=1000},{nPos=2,nItemID=2000},{nPos=3,nItemID=3000}})
       
        tPubUserApi.UpdateUserData(tUserStatisti)
        SafeExecute(LogonSink.GetClubUserPublicInfo, "GetClubUserPublicInfo", tRegist.UserID)
        SafeExecute(LogonSink.GetUserMarkInfo, "GetUserMarkInfo", tRegist.UserID)
        tPubUserApi.IncrRegister()
        tBase.Log("_RequstRegister 注册成功  UserID:%d, nErrCode:%d", tRegist.UserID, tRegist.nErrCode)
    else
        -- 根据 UserID 返回的参数进行检查：   如果返回结果是   UserID = -1 ， 失败， UserID  > 10  成功 
        tBase.Log("_RequstRegister DB Error_Info==2038  Regist   error    = :%d", tRegist.nErrCode)
        tRegist.UserID = -1
    end

    if tData.nAccountType == 7 then
        if tRegist.nErrCode == 1 then  -- 注册成功
            LogonSink.TgAfterLogon(sReturnKey, tData)
            return
        else
            LogonReturn(sReturnKey, tData)
            return
        end
    end
     
    local pRegist = ProtoMgr.PubProto_pb.Rup_Regist()
    pRegist.ClientID = tData.sClientID
    pRegist.UserID   = tRegist.UserID
    pRegist.nErrCode = tRegist.nErrCode
    pRegist.sPlatform =tData.sPlatform

    if tRegist.nErrCode == 1 then
        pRegist.sIp = tRegist.nRegistIP
    end
    local s = tBase.GetSP().new(MainID, SubID)
    s:AddString(pRegist:SerializeToString())
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    tBase.Log("_RequstRegister  注册成功  返回成功UserID: "..tRegist.UserID)
    return 0
end

--加载俱乐部玩家的公用信息
function LogonSink.GetClubUserPublicInfo(nUserId)
    local sSql = string.format("call Club_GetUserPublicRedisInfo(%d)",nUserId)
    local arrRows = SqlExecut(sSql,dbSink.AccountsDB_connect)
    local row = arrRows[1]
    if row then
        local tUserInfo = {}
        tUserInfo.nUserID = nUserId
        tUserInfo.nVip = tonumber(row.nVip)
        tUserInfo.nExp = tonumber(row.nExp)
        tUserInfo.nGloryLevel = tonumber(row.nGloryLevel)
        tUserInfo.nLevelStart = tonumber(row.nLevelStart)
        tUserInfo.nOpenProtection = tonumber(row.nOpenProtection)
        if tUserInfo.nOpenProtection==0 or tUserInfo.nOpenProtection==1 then
            tUserInfo.sSafePassWard = row.sSafePassWard
        end
        tPubUserApi.UpdateUserData(tUserInfo)
    end
end

local function AccountsDB_SqlExecute(sSql,isForRead)
    local connection =dbSink.AccountsDB_connect
    if isForRead then
        connection =dbSink.GetDbConnectForRead("DJH_AccountsDB")
    end
    return SqlExecut(sSql,connection)
end

-- 自动下注加载用户数据
function LogonSink._AutoBet_LoadUserInfo(sReturnKey, sData, nLen)   
    local ReadData = tBase.GetRP().new(sData, nLen) 
    local Read = ProtoMgr.PubProto_pb.AutoBetLoadUserInfoReq()
    Read:ParseFromString(ReadData:GetString())    
    local nUserId = Read.nUserId 
    local sSql = string.format("call AutoBet_LoadUserinfo(%d)",nUserId)

    local tUserBasic = {}      --玩家基本数据玩家统计数据
    local tUserTreasure = {}   --玩家财富数据 
    local tUserInfo = {}   
    tUserInfo.nErrCode = -99
    local cursor = assert(dbSink.AccountsDB_connect:execute(sSql))  
    repeat
        row = cursor:fetch({},"a")
        while row do   
            function GetRes(row) 
                tUserInfo.nErrCode = tonumber(row.nErrCode)   -- 错误码 1 正确，其他失败
                if tUserInfo.nErrCode == 1 then 
                    tUserInfo.UserID = tonumber(row.strUserID)                
                    tUserInfo.sNickName = row.sNickName  
                    tUserInfo.nSex= tonumber(row.nSex) 
                    tUserInfo.sFaceID= row.sFaceID         
                    tUserInfo.nGold = tonumber(row.Gold)
                    tUserInfo.sChannel = row.sChannel  
                    tUserInfo.nShopID = row.nShopID
                    tUserInfo.nAccountType = row.AccountType
                    tUserInfo.sShopAccount = row.sShopAccount                     
                    tBase.Log("_AutoBet_LoadUserInfo UserID: %d  nGold: %.1f ",tUserInfo.UserID,tUserInfo.nGold) 
                else  
                    local ErrorCode  = row.ErrorCode   -- mysql 错误码 
                    local ErrorInfo  = row.ErrorInfo   -- mysql 错误信息
                    if ErrorCode or ErrorInfo then                     
                        tBase.Log("_AutoBet_LoadUserInfo   加载失败  ErrorCode %s   ErrorInfo  %s   ",ErrorCode or -111 ,ErrorInfo or "")
                    end
                end     
            end  
            xpcall(GetRes, tErr.tpLog, row)
            row = cursor:fetch(row,"a") 
        end
        cursor:close()
        cursor = dbSink.AccountsDB_connect:nextres()
    until( cursor == 0 )
    if tUserInfo.nErrCode == 1 then 
        tUserBasic["nUserID"]  = tUserInfo.UserID 
        -- tUserBasic["sClientID"] = ""
        tUserBasic["sNickName"] = tUserInfo.sNickName              --昵称 
        tUserBasic["nSex"]     = tUserInfo.nSex                   --性别  
        tUserBasic["sFaceID"]  = tUserInfo.sFaceID                --性别 
        tUserBasic["Account_Type"]  = tUserInfo.nAccountType             -- 账号类型
        tUserBasic["sChannel"]  = tUserInfo.sChannel            
        tUserBasic["nShopID"] = tUserInfo.nShopID       
        tUserBasic["nAccountType"] = tUserInfo.nAccountType 
        tUserBasic["nGold"]   = tUserInfo.nGold        --金币  

        --玩家财富数据
        tUserTreasure["nUserID"] = tUserInfo.UserID
        tUserTreasure["nGold"]   = tUserInfo.nGold        --金币  
  
        tPubUserApi.PersistUserInfo(tUserInfo.UserID)
        tPubUserApi.UpdateUserData(tUserBasic) 
        tPubUserApi.UpdateUserGold(tUserTreasure.nUserID,tUserTreasure.nGold,1)
    end      
    local Send = ProtoMgr.PubProto_pb.AutoBetLoadUserInfoRep()
    Send.nUserId = nUserId
    Send.nResult = tUserInfo.nErrCode
    local s = tBase.GetSP().new(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.AutoBetLoadUserInfoRep)
    s:AddString(Send:SerializeToString())
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    tBase.Log("_AutoBet_LoadUserInfo  nUserId_%d    nErrCode_%d   %s",nUserId,tUserInfo.nErrCode,sSql)
    return 0
end

--加载玩家标记用户信息
function LogonSink.GetUserMarkInfo(nUserId)
    local isSet = tPubUserApi.TryGetUserMarkInfo(nUserId)  --加载过就return
    if isSet then
        return
    end
    local sSql = string.format("call Load_UserMarkInfo(%d)",nUserId)
    local arrRows = SqlExecut(sSql,dbSink.AccountsDB_connect)
    local row = arrRows[1]
    if row then
        local content = row.content
        local changeName = row.changeName
        tPubUserApi.SetUserMarkInfo(nUserId, content)
        tPubUserApi.SetUserNameInfo(nUserId, changeName)
    end
end


return LogonSink