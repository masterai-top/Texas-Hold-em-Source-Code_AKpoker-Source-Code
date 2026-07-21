--俱乐部
package.path = require("./lua/DB_s/Head").path

local tBase = require("base")           -- 基础功能接口
local tParserAux = require("ParserAux")
local cjson = require("cjson")
local tPubUsrApi  = require("PublicUserInfo")   -- 用户信息
local tPublicUserGold = require("PublicUserGold")
local tPublicRedis= require("PublicRedis")
local logger = require("logger")      -- 日志对象
local tApi = require("publicApi")
local tname        = require("typename")        -- 类弄定义接口

local DbClubProtoParse =tParserAux.DbClubParse
local DbClubProtoParse1 =tParserAux.DbClub1Parse
local DbClubSendToServer =tParserAux.DbClubSendToServer
local DbClub1SendToServer =tParserAux.DbClub1SendToServer
local DbProtoParse1 =tParserAux.DbProtoParse1
local DbSendToServer1 =tParserAux.DbSendToServer1
local DbProtoEncode =tParserAux.DbProtoEncode


local ClubSink ={}
ClubSink.sql = {}

local function Check_ExecutIsError(sSql,arrRows)
    if arrRows and arrRows[1] and arrRows[1].ErrorCode and arrRows[1].ErrorInfo then
        tBase.Log("ErrorMsg  ErrorCode: %s  ErrorInfo_%s sSql_%s   ",arrRows[1].ErrorCode,arrRows[1].ErrorInfo,sSql)
    end 
end  

local function PlatformDB_SqlExecute(sSql,isForRead)
    local connection =dbSink.PlatformDB_connect
    if isForRead then
        connection =dbSink.GetDbConnectForRead("DJH_PlatformDB")
    end
    return SqlExecut(sSql,connection)
end
local function AccountsDB_SqlExecute(sSql,isForRead)
    local connection =dbSink.AccountsDB_connect
    if isForRead then
        connection =dbSink.GetDbConnectForRead("DJH_AccountsDB")
    end
    return SqlExecut(sSql,connection)
end
local function RecordDB_SqlExecute(sSql,isForRead)
    local connection =dbSink.RecordDB_connect
    if isForRead then
        connection =dbSink.GetDbConnectForRead("DJH_RecordDB")
    end
    return SqlExecut(sSql,connection)
end
local function TreasureDB_SqlExecute(sSql,isForRead)
    local connection =dbSink.TreasureDB_connect
    if isForRead then
        connection =dbSink.GetDbConnectForRead("DJH_TreasureDB")
    end
    return SqlExecut(sSql,connection)
end
local function WebDB_SqlExecute(sSql,isForRead)
    local connection =dbSink.WebDB_connect
    if isForRead then
        connection =dbSink.GetDbConnectForRead("DJH_WebDB")
    end
    return SqlExecut(sSql,connection)
end

local function SetWebRedisResulte(sRequestkey,tData)
    if not sRequestkey then
       return
    end
    local tRedis =tBase.m_MyRedisData[1].redis
    tRedis:hmset(sRequestkey,tData)
    tRedis:expire(sRequestkey,60)
end


-----------------------------俱乐部 ------------------------------
--俱乐部数据 请求
function ClubSink.OnClubDataReq(sReturnKey,Data,nLen)
    local strReq ="ClubDataReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrClubData = {}
    local arrClubId = {}

    local sSql = string.format("call Club_Load(%d,%d,%d)",tData.nMinClubId,tData.nLimitCnt,tData.nMaxClubId)
    local arrRows =AccountsDB_SqlExecute(sSql,true)
    for _,row in ipairs(arrRows) do
        local ClubItem ={}
        ClubItem.nClubId =tonumber(row.ClubId) or 0; --俱乐部id
        ClubItem.sClubName =row.ClubName or ""; -- 俱乐部名称	  
        ClubItem.nMaster =tonumber(row.MasterId) or 0; -- 主席id
        ClubItem.sFaceId =row.FaceID or ""; -- url
        ClubItem.sName =row.NickName or ""; -- 昵称
        ClubItem.nSex =tonumber(row.Sex) or 0; -- 性别 0:男 1:女
        ClubItem.sShopAcc =row.ShopAccount or ""; -- 第三方账号
        ClubItem.nClubGold =tonumber(row.ClubGold) or 0; -- 俱乐部币
        ClubItem.nCanApply =tonumber(row.CanApply) or 0; -- 能否申请加入
        ClubItem.nCanSearch =tonumber(row.CanSearch) or 0; -- 能否被搜索
        ClubItem.nIncome =tonumber(row.ClubGoldIncome) or 0; --总收益(俱乐部币)
        ClubItem.nUserCnt =tonumber(row.Members) or 0; --成员数
        ClubItem.nGroupId =tonumber(row.GroupId) or 0 --分组id
        ClubItem.sCreateTime=row.CreateTime or "1970-01-01 08:00:00" --创建时间
        ClubItem.sPassWord=row.PassWords or "" --库存密码
        ClubItem.nApplyJionCnt =tonumber(row.ApplyJionCnt) or 0; --加入俱乐部申请数目
        ClubItem.nApplyAddGoldCnt =tonumber(row.ApplyAddGoldCnt) or 0; --增加俱乐部币申请数目
        ClubItem.nApplyCutGoldCnt =tonumber(row.ApplyCutGoldCnt) or 0; --增加俱乐部币申请数目
        ClubItem.nGold =tonumber(row.Gold) or 0; -- 金币
        ClubItem.nGoldIncome=tonumber(row.GoldIncome) or 0; -- 总收益(金币)
    
        table.insert(arrClubData,ClubItem)
        table.insert(arrClubId,ClubItem.nClubId)
        
        --同步俱乐部总资产到redis
        tPubUsrApi._InitClubSumAsset(ClubItem.nClubId,ClubItem.nClubGold,ClubItem.nClubId)
        tPubUsrApi._InitClubSumAsset(ClubItem.nClubId,ClubItem.nGold,1)
    end

    local ClubDataRsp ={}
    ClubDataRsp.arrClub =arrClubData
    ClubDataRsp.nMinClubId =tData.nMinClubId
    ClubDataRsp.nMaxClubId =tData.nMaxClubId
    ClubDataRsp.nLimitCnt =tData.nLimitCnt
    DbClubSendToServer(sReturnKey,"ClubDataRsp",ClubDataRsp)
end

--加载俱乐部成员的基本信息 请求
function ClubSink.OnClubLoadUserInfoReq(sReturnKey,Data,nLen)
    local strReq ="ClubLoadUserInfoReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    for _,nClubId in pairs(tData.arrClubId) do
        if type(nClubId)=="number" then
            if not tPublicRedis.IsExitsClubUserInfo(nClubId) then
                local sSql = string.format("call Club_LoadUserInfo(%d)",nClubId)
                tBase.Log("OnClubLoadUserInfoReq sSql:%s",sSql)
                local arrClubUserInfo = {}
                local arrRows = AccountsDB_SqlExecute(sSql,true)
                for _,row in pairs(arrRows) do
                    local tItem = {}
                    tItem.nUserId = tonumber(row.UserId) or 0
                    tItem.nIdentify = tonumber(row.Identify) or 0
                    tItem.sPower = GetUserPower(row)
                    if tItem.nUserId~=0 then
                        table.insert(arrClubUserInfo,tItem)
                    end
                end
                tPublicRedis.SetClubUserInfo(nClubId,arrClubUserInfo)
            end
        end
    end
end

--服务器对应分组 请求
function ClubSink.OnServerIdGroupReq(sReturnKey,Data,nLen)
    local strReq ="ServerIdGroupReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = string.format("call Load_ServerIdGroup(%d,%d)",tData.nServerId,tData.nLoadAll)
    tBase.Log("OnServerIdGroupReq sSql:%s",sSql)
    local arrGroup = {}
    local nMinClubId = 0
    local nMaxClubId = -1
    local arrRows = PlatformDB_SqlExecute(sSql,true)
    for _,row in ipairs(arrRows) do
        local nGroupId = tonumber(row.GroupId) or 0
        if nGroupId~=0 then
            table.insert(arrGroup,nGroupId)
        end
        nMinClubId = tonumber(row.nMinClubId) or 0
        nMaxClubId = tonumber(row.nMaxClubId) or -1
    end

    local ServerIdGroupRsp ={}
    ServerIdGroupRsp.arrGroup =arrGroup
    ServerIdGroupRsp.nMinClubId = nMinClubId
    ServerIdGroupRsp.nMaxClubId = nMaxClubId
    DbClubSendToServer(sReturnKey,"ServerIdGroupRsp",ServerIdGroupRsp)
end

--创建俱乐部 请求
function ClubSink.OnCreateClubReq(sReturnKey,Data,nLen)
    local strReq ="CreateClubReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = tData.sSql

    tBase.Log("OnCreateClubReq sSql:%s",sSql)
    local arrRows =AccountsDB_SqlExecute(sSql)
    local row = arrRows[1]
    
    local CreateClubRsp = {}
    CreateClubRsp.nRlt = tonumber(row.ErrCode) or 99
    CreateClubRsp.nUserId = tData.nUserId

    if CreateClubRsp.nRlt==0 then
        --创建俱乐部成功
        local ClubItem ={}
        ClubItem.nClubId =tonumber(row.nClubId) or 0; --俱乐部id
        ClubItem.sClubName =row.sClubName or ""; -- 俱乐部名称	  
        ClubItem.nMaster =tonumber(row.nMaster) or 0; -- 主席id 
        ClubItem.nClubGold =tonumber(row.nClubGold) or 0; -- 俱乐部币
        ClubItem.nCanApply =tonumber(row.nCanApply) or 0; -- 能否申请加入
        ClubItem.nCanSearch =tonumber(row.nCanSearch) or 0; -- 能否被搜索
        ClubItem.nIncome = 0; --总收益(俱乐部币)
        ClubItem.nUserCnt = 1 ; --成员数
        ClubItem.nGroupId =tonumber(row.nGroupId) or 0 --分组id
        ClubItem.sCreateTime=row.sCreateTime or "1970-01-01 08:00:00" --创建时间
        ClubItem.sPassWord=row.sPassWord or "" --库存密码
        ClubItem.nApplyJionCnt=0; --加入俱乐部申请数目
        ClubItem.nApplyAddGoldCnt=0; --增加俱乐部币申请数目
        ClubItem.nApplyCutGoldCnt=0; --增加俱乐部币申请数目
        ClubItem.sFaceId =row.sFaceId or "" --主席公共信息
        ClubItem.sName =row.sName or "" --主席公共信息
        ClubItem.nSex =tonumber(row.nSex) or 0 --主席公共信息
        ClubItem.sShopAcc =row.sShopAcc or "" --主席公共信息
        ClubItem.nGold = 0; -- 金币
        ClubItem.nGoldIncome= 0; -- 总收益(金币)
        CreateClubRsp.tClubItem = ClubItem

        --同步俱乐部总资产到redis
        tPubUsrApi._InitClubSumAsset(ClubItem.nClubId,ClubItem.nClubGold,ClubItem.nClubId)
        tPubUsrApi._InitClubSumAsset(ClubItem.nClubId,ClubItem.nGold,1)
        --把主席信息保存到redis
        local tClubUserInfo = {}
        tClubUserInfo.nUserId = ClubItem.nMaster
        tClubUserInfo.nIdentify = 1
        tClubUserInfo.sPower = cjson.encode({{nPowerType=1,isOpen=true},{nPowerType=2,isOpen=true},{nPowerType=3,isOpen=true}})
        tPublicRedis.SetClubUserInfo(ClubItem.nClubId,{tClubUserInfo})
    end

    DbClubSendToServer(sReturnKey,"CreateClubRsp",CreateClubRsp)
end

--把权限转成json格式
function GetUserPower(tData)
    local nMemberPower = tonumber(tData.nMemberPower) or tonumber(tData.MemberPower) or 0
    local nClubGoldPower = tonumber(tData.nClubGoldPower) or tonumber(tData.ClubGoldPower) or 0
    local nTablePower = tonumber(tData.nTablePower) or tonumber(tData.TablePower) or 0
    local arrPower = {}
    if nMemberPower==1 then
        table.insert(arrPower,{nPowerType=1,isOpen=true})
    else
        table.insert(arrPower,{nPowerType=1,isOpen=false}) 
    end
    if nClubGoldPower==1 then
        table.insert(arrPower,{nPowerType=2,isOpen=true})
    else
        table.insert(arrPower,{nPowerType=2,isOpen=false}) 
    end
    if nTablePower==1 then
        table.insert(arrPower,{nPowerType=3,isOpen=true})
    else
        table.insert(arrPower,{nPowerType=3,isOpen=false}) 
    end
    local sPower = cjson.encode(arrPower)
    return sPower
end

--俱乐部玩家登录 请求
function ClubSink.OnClubUserLogonReq(sReturnKey,Data,nLen)
    local strReq ="ClubUserLogonReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local icode = tData.nInviteCode or ""
    local sSql = string.format("call Club_UserLogon(%d,%d,'%s')",tData.nClubId,tData.nUserId,icode)
    tBase.Log("OnClubUserLogonReq sSql:%s",sSql)
    local arrRows =AccountsDB_SqlExecute(sSql,false)
    local row = arrRows[1]
    local ClubUserLogonRsp = {}
    ClubUserLogonRsp.nRlt = tonumber(row.nRlt) or 0
    ClubUserLogonRsp.nClubId = tData.nClubId
    ClubUserLogonRsp.nUserId = tData.nUserId
    if ClubUserLogonRsp.nRlt==1 then
        --登录俱乐部成功
        local ClubUserInfo ={}
        ClubUserInfo.nUserId =tData.nUserId; --玩家id
        ClubUserInfo.sFaceId =row.sFaceId or ""; -- url	  
        ClubUserInfo.sName =row.sName or ""; -- 昵称 
        ClubUserInfo.nSex =tonumber(row.nSex) or 0; -- 性别 0:男 1:女
        ClubUserInfo.nClubId =tData.nClubId; -- 俱乐部id
        ClubUserInfo.nIdentify =tonumber(row.nIdentify) or 0; -- 身份
        ClubUserInfo.sPower =GetUserPower(row); --权限
        ClubUserInfo.nContribution =tonumber(row.nContribution) or 0; --累计贡献(俱乐部币)
        ClubUserInfo.nGroupId =tonumber(row.nGroupId) or 0 --分组id
        ClubUserInfo.nGold=tonumber(row.nGold) or 0; --金币
        ClubUserInfo.nClubGold=tonumber(row.nClubGold) or 0; --俱乐部币
        ClubUserInfo.sShopAcc = row.sShopAcc or ""
        ClubUserInfo.nGoldContribution =tonumber(row.nGoldContribution) or 0; --累计贡献(金币)
        ClubUserInfo.nCreateTime = row.sCreateTime or "1970-01-01 08:00:00" --加入时间
        ClubUserLogonRsp.tUserInfo = ClubUserInfo
        tBase.Log("_OnClubUserLogonReq nUserId: %d nClubGold: %f nClubId: %d   ",ClubUserInfo.nUserId,ClubUserInfo.nClubGold,ClubUserInfo.nClubId)

        if tData.nClubId >= 1000000 then
            --同步玩家俱乐部币到redis
            tPubUsrApi.UpdateUserGold(ClubUserInfo.nUserId,ClubUserInfo.nClubGold,ClubUserInfo.nClubId,false)
        end
    elseif ClubUserLogonRsp.nRlt == 4 then
        ClubUserLogonRsp.sExData = row.dEndTime
    else
        tBase.Log("_OnClubUserLogonReq  nRlt_%d 获取失败 nUserId_%d arrRows: %d "
        ,ClubUserLogonRsp.nRlt,ClubUserLogonRsp.nUserId or -1,#arrRows)
        for k, row in pairs(arrRows) do
            if row then
                tBase.Log("_OnClubUserLogonReq  k_%d row_%s ",k,cjson.encode(row))
            end        
        end
    end
    ClubUserLogonRsp.ifBinging = tonumber(row.nBinging) or 0
    tBase.Log("用户是否为绑定用户:%d",row.nBinging)
    DbClubSendToServer(sReturnKey,"ClubUserLogonRsp",ClubUserLogonRsp)
end

--玩家俱乐部列表 请求
function ClubSink.OnGetUserClubListReq(sReturnKey,Data,nLen)
    local strReq ="GetUserClubListReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetUserClub(%d)",tData.nUserId)
    tBase.Log("OnClubUserLogonReq sSql:%s",sSql)

    local arrClub = {}
    local arrRows =AccountsDB_SqlExecute(sSql,true)
    for _,row in ipairs(arrRows) do
        local UserClubItem ={}
        UserClubItem.nClubId =tonumber(row.ClubId) or 0; --俱乐部id
        UserClubItem.nIdentify =tonumber(row.Identify) or 0; --角色
        UserClubItem.sClubName =row.ClubName or ""; -- 俱乐部名称	  
        UserClubItem.nMaster =tonumber(row.MasterId) or 0; -- 主席id 
        table.insert(arrClub,UserClubItem)
    end

    local nLen = #arrClub
    local nSendLen = 50 --每次发送50条
    if nLen>nSendLen then
        local arrTemp = {}
        local nAllPage = math.ceil(nLen/nSendLen)
        local nPage = 1
        for i=1,nLen do
            table.insert(arrTemp,arrClub[i])
            if i%nSendLen==0 or i==nLen then
                local GetUserClubListRsp ={}
                GetUserClubListRsp.arrClub =arrTemp
                GetUserClubListRsp.nUserId = tData.nUserId
                GetUserClubListRsp.nPage = nPage
                GetUserClubListRsp.nAllPage = nAllPage
                GetUserClubListRsp.sClientID = tData.sClientID
                DbClubSendToServer(sReturnKey,"GetUserClubListRsp",GetUserClubListRsp)
                arrTemp = {}
                nPage = nPage + 1
            end
        end
    else
        local GetUserClubListRsp ={}
        GetUserClubListRsp.arrClub =arrClub
        GetUserClubListRsp.nUserId = tData.nUserId
        GetUserClubListRsp.nPage = 1
        GetUserClubListRsp.nAllPage = 1
        GetUserClubListRsp.sClientID = tData.sClientID
        DbClubSendToServer(sReturnKey,"GetUserClubListRsp",GetUserClubListRsp)
    end
end

--搜索俱乐部 请求
function ClubSink.OnSearchClubReq(sReturnKey,Data,nLen)
    local strReq ="SearchClubReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_SearchClub('%s',%d)",tData.str,tData.nUserId)
    tBase.Log("OnSearchClubReq sSql:%s",sSql)

    local arrItem = {}
    local arrRows =AccountsDB_SqlExecute(sSql,true)
    for _,row in ipairs(arrRows) do
        local ClubSearchItem ={}
        ClubSearchItem.nClubId =tonumber(row.ClubId) or 0; --俱乐部id
        ClubSearchItem.sClubName =row.ClubName or ""; -- 俱乐部名称	  
        ClubSearchItem.nMaster =tonumber(row.MasterId) or 0; -- 主席id 
        ClubSearchItem.sMasterName =row.MasterName or ""; -- 主席昵称
        ClubSearchItem.nStatus =tonumber(row.nStatus) or 0; -- 状态 0:未申请 1:已申请  2:已加入
        ClubSearchItem.nUserCnt =tonumber(row.UserCnt) or 0; -- 目前成员个数
        ClubSearchItem.nGroupId =tonumber(row.GroupId) or 0; -- 目前成员个数
        table.insert(arrItem,ClubSearchItem)
    end

    local nLen = #arrItem
    local nSendLen = 30 --每次发送30条
    if nLen>nSendLen then
        local arrTemp = {}
        local nAllPage = math.ceil(nLen/nSendLen)
        local nPage = 1
        for i=1,nLen do
            table.insert(arrTemp,arrItem[i])
            if i%nSendLen==0 or i==nLen then
                local SearchClubRsp ={}
                SearchClubRsp.arrItem =arrTemp
                SearchClubRsp.nUserId = tData.nUserId
                SearchClubRsp.nPage = nPage
                SearchClubRsp.nAllPage = nAllPage
                DbClubSendToServer(sReturnKey,"SearchClubRsp",SearchClubRsp)
                arrTemp = {}
                nPage = nPage + 1
            end
        end
    else
        local SearchClubRsp ={}
        SearchClubRsp.arrItem =arrItem
        SearchClubRsp.nUserId = tData.nUserId
        SearchClubRsp.nPage = 1
        SearchClubRsp.nAllPage = 1
        DbClubSendToServer(sReturnKey,"SearchClubRsp",SearchClubRsp)
    end
end

--申请加入俱乐部 请求
function ClubSink.OnApplyJoinClubReq(sReturnKey,Data,nLen)
    local strReq ="ApplyJoinClubReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_ApplyJoin(%d,%d,%d,%d)",tData.nClubId,tData.nUserId,tData.nLimitCnt,tData.nGroupId)
    tBase.Log("OnApplyJoinClubReq sSql:%s",sSql)

    local arrRows =RecordDB_SqlExecute(sSql)
    local row = arrRows[1]

    local ApplyJoinClubRsp = {}
    ApplyJoinClubRsp.nRlt = tonumber(row.ErrCode) or 99
    ApplyJoinClubRsp.nUserId = tData.nUserId
    ApplyJoinClubRsp.nClubId = tData.nClubId 

    if ApplyJoinClubRsp.nRlt==0 then
        --申请加入俱乐部成功
        local ClubApplyItem ={}
        ClubApplyItem.nId =tonumber(row.id) or 0; --记录id(自增全游戏记录唯一id)
        ClubApplyItem.nUserId =tonumber(row.UserId) or 0; -- 申请者的UserId	  
        ClubApplyItem.sFaceId =row.FaceID or ""; -- url 
        ClubApplyItem.sName =row.NickName or ""; -- 昵称
        ClubApplyItem.nSex =tonumber(row.Sex) or 0; -- 性别 0:男 1:女
        ClubApplyItem.sTime =row.CreateTime or "1970-01-01 08:00:00"; -- 时间
        ClubApplyItem.nType =tonumber(row.nType) or 0; --申请类型: 1:增加俱乐部币 2:退还俱乐部币 3:加入俱乐部
        ApplyJoinClubRsp.nApplyCnt = tonumber(row.ApplyCnt) or 0 --目前未处理申请数目
        ApplyJoinClubRsp.tItem = ClubApplyItem
    end

    DbClubSendToServer(sReturnKey,"ApplyJoinClubRsp",ApplyJoinClubRsp)
end

--修改俱乐部信息 请求
function ClubSink.OnChangeClubInfoReq(sReturnKey,Data,nLen)
    local strReq ="ChangeClubInfoReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local ChangeClubInfoRsp = {}
    ChangeClubInfoRsp.nClubId = tData.nClubId
    ChangeClubInfoRsp.nUserId = tData.nUserId
    ChangeClubInfoRsp.arrRlt = {}

    local arrItem =tData.arrItem

    local sNewPassWord = ""
    local sOldPassWord = ""
    local sClubName = ""
    local nCanSearch = -1
    local nCanApply = -1

    for k,v in pairs(arrItem) do
        if v.sKey == "sClubName" then
            sClubName = v.sVal
        end
    
        if v.sKey == "nCanSearch" then
            nCanSearch = tonumber(v.sVal) or 0
        end
    
        if v.sKey == "nCanApply" then
            nCanApply = tonumber(v.sVal) or 0
        end
    
        if v.sKey == "sNewPassWord" and #v.sVal>0 then
            sNewPassWord = v.sVal
        end
        if v.sKey == "sOldPassWord" and #v.sVal>0 then
            sOldPassWord = v.sVal
        end
    end
    local sSql = string.format("call Club_ChangeClubInfo('%s',%d,%d,'%s','%s',%d)",sClubName,nCanSearch,nCanApply,sNewPassWord,sOldPassWord,tData.nClubId)
    tBase.Log("OnChangeClubInfoReq sSql:%s",sSql)
    local arrRows =AccountsDB_SqlExecute(sSql)
    local row = arrRows[1]
    local nRlt = tonumber(row.ErrCode) or 99
    if nRlt == 0 then
        if tonumber(row.IsChangeClubName)==1 then
            table.insert(ChangeClubInfoRsp.arrRlt,{nRlt=0,sKey="sClubName",sValue=sClubName})
        end
        if tonumber(row.IsChangePassWard)==1 then
            table.insert(ChangeClubInfoRsp.arrRlt,{nRlt=0,sKey="sPassWord",sValue=sNewPassWord})
        end
        if tonumber(row.IsChangeCanApply)==1 then
            table.insert(ChangeClubInfoRsp.arrRlt,{nRlt=0,sKey="nCanApply",sValue=tostring(nCanApply)})
        end
        if tonumber(row.IsChangeCanSearch)==1 then
            table.insert(ChangeClubInfoRsp.arrRlt,{nRlt=0,sKey="nCanSearch",sValue=tostring(nCanSearch)})
        end
    elseif nRlt==1 then
        table.insert(ChangeClubInfoRsp.arrRlt,{nRlt=4,sKey="sPassWord"})
    elseif nRlt==2 then
        table.insert(ChangeClubInfoRsp.arrRlt,{nRlt=2,sKey="sClubName"})
    else
        if sClubName~="" then
            table.insert(ChangeClubInfoRsp.arrRlt,{nRlt=99,sKey="sClubName"})
        end
        if nCanSearch~=-1 then
            table.insert(ChangeClubInfoRsp.arrRlt,{nRlt=99,sKey="nCanSearch"})
        end
        if nCanApply~=-1 then
            table.insert(ChangeClubInfoRsp.arrRlt,{nRlt=99,sKey="nCanApply"})
        end
        if sNewPassWord~="" and sOldPassWord~="" then
            table.insert(ChangeClubInfoRsp.arrRlt,{nRlt=99,sKey="sPassWord"})
        end
    end
    DbClubSendToServer(sReturnKey,"ChangeClubInfoRsp",ChangeClubInfoRsp)  
end

--俱乐部成员 请求
function ClubSink.OnClubMembersReq_old(sReturnKey,Data,nLen)
    local strReq ="ClubMembersReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetMembers(%d,%d,%d)",tData.nClubId,tData.nCnt,tData.nPage)
    tBase.Log("OnClubMembersReq sSql:%s",sSql)

    local arrUser = {}
    local nUserCnt = 0
    local arrRows =AccountsDB_SqlExecute(sSql,true)
    for _,row in ipairs(arrRows) do
        local ClubUserInfo ={}
        ClubUserInfo.nUserId =tonumber(row.UserId); --玩家id
        ClubUserInfo.sFaceId =row.FaceID or ""; -- url	  
        ClubUserInfo.sName =row.NickName or ""; -- 昵称 
        ClubUserInfo.nSex =tonumber(row.Sex) or 0; -- 性别 0:男 1:女
        ClubUserInfo.nClubId =tData.nClubId; -- 俱乐部id
        ClubUserInfo.nIdentify =tonumber(row.Identify) or 0; -- 身份
        ClubUserInfo.nContribution =tonumber(row.Contribution) or 0; --累计贡献(俱乐部币)
        ClubUserInfo.nGold=tonumber(row.Gold) or 0; --金币
        ClubUserInfo.nClubGold=tonumber(row.ClubGold) or 0; --俱乐部币
        ClubUserInfo.sShopAcc = row.ShopAccount or ""
        ClubUserInfo.nGoldContribution =tonumber(row.GoldContribution) or 0; --累计贡献(金币)
        nUserCnt = tonumber(row.UserCnt) or 0 --成员人数
        table.insert(arrUser,ClubUserInfo)
    end

    local ClubMembersRsp ={}
    ClubMembersRsp.arrUser =arrUser
    ClubMembersRsp.nPage = tData.nPage
    ClubMembersRsp.nUserCnt = nUserCnt
    ClubMembersRsp.nUserId = tData.nUserId
    ClubMembersRsp.nClubId = tData.nClubId
    DbClubSendToServer(sReturnKey,"ClubMembersRsp",ClubMembersRsp)

end

--一期大厅成员 请求
function ClubSink.OnClubMembersReq(sReturnKey, Data, nLen)
    local strReq ="ClubMembersReq"
    local tData =DbClubProtoParse(Data, nLen, strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Lobby_GetMembers(%d,%d,%d)",tData.nShopId,tData.nCnt,tData.nPage)
    tBase.Log("OnClubMembersReq sSql:%s",sSql)

    local arrUser = {}
    local nUserCnt = 0
    local arrRows =AccountsDB_SqlExecute(sSql,true)
    for _,row in ipairs(arrRows) do
        local ClubUserInfo ={}
        ClubUserInfo.nUserId =tonumber(row.UserId); --玩家id
        ClubUserInfo.sFaceId =row.FaceID or ""; -- url	  
        ClubUserInfo.sName =row.NickName or ""; -- 昵称 
        ClubUserInfo.nSex =tonumber(row.Sex) or 0; -- 性别 0:男 1:女
        ClubUserInfo.nClubId = tData.nClubId; -- 俱乐部id
        ClubUserInfo.nIdentify =tonumber(row.Identify) or 0; -- 身份
        ClubUserInfo.nContribution =tonumber(row.Contribution) or 0; --累计贡献(俱乐部币)
        ClubUserInfo.nGold=tonumber(row.Gold) or 0; --金币
        ClubUserInfo.nClubGold=tonumber(row.ClubGold) or 0; --俱乐部币
        ClubUserInfo.sShopAcc = row.ShopAccount or ""
        ClubUserInfo.nGoldContribution =tonumber(row.GoldContribution) or 0; --累计贡献(金币)
        ClubUserInfo.nCreateTime = row.RegisTime or ""
        nUserCnt = tonumber(row.UserCnt) or 0 --成员人数
        table.insert(arrUser,ClubUserInfo)
    end
    if tData.nPage == 1 then
        local tUserInfo = tPubUsrApi.GetAllUserInfo(tData.nUserId)
        if tUserInfo then
            local ClubUserInfo = {}
            ClubUserInfo.nUserId = tData.nUserId --玩家id
            ClubUserInfo.sFaceId = tUserInfo.sFaceID or ""; -- url	  
            ClubUserInfo.sName =tUserInfo.sNickName or ""; -- 昵称 
            ClubUserInfo.nSex =tonumber(tUserInfo.nSex) or 0; -- 性别 0:男 1:女
            ClubUserInfo.nClubId = tData.nClubId; -- 俱乐部id
            ClubUserInfo.nIdentify = 0; -- 身份
            ClubUserInfo.nContribution = 0; --累计贡献(俱乐部币)
            ClubUserInfo.nGold=tonumber(tUserInfo.nGold) or 0; --金币
            ClubUserInfo.nClubGold= 0; --俱乐部币
            ClubUserInfo.sShopAcc = tUserInfo.sShopAccount or ""
            ClubUserInfo.nGoldContribution = 0; --累计贡献(金币)
            ClubUserInfo.nCreateTime = tUserInfo.nRegisTime or ""
            table.insert(arrUser,ClubUserInfo)
        end
    end

    local ClubMembersRsp ={}
    ClubMembersRsp.arrUser =arrUser
    ClubMembersRsp.nPage = tData.nPage
    ClubMembersRsp.nUserCnt = nUserCnt
    ClubMembersRsp.nUserId = tData.nUserId
    ClubMembersRsp.nClubId = tData.nClubId
    DbClubSendToServer(sReturnKey,"ClubMembersRsp",ClubMembersRsp)

end

--搜索俱乐部成员 请求
function ClubSink.OnSearchClubMemberReq(sReturnKey,Data,nLen)
    local strReq ="SearchClubMemberReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Lobby_SearchMembers('%s')",tData.str)
    tBase.Log("OnSearchClubMemberReq sSql:%s",sSql)

    local arrUser = {}
    local arrRows =AccountsDB_SqlExecute(sSql,true)
    for _,row in ipairs(arrRows) do
        local ClubUserInfo ={}
        ClubUserInfo.nUserId =tonumber(row.UserId) or 0; --玩家id
        ClubUserInfo.sFaceId =row.FaceID or ""; -- url	  
        ClubUserInfo.sName =row.NickName or ""; -- 昵称 
        ClubUserInfo.nSex =tonumber(row.Sex) or 0; -- 性别 0:男 1:女
        ClubUserInfo.nClubId =tData.nClubId; -- 俱乐部id
        ClubUserInfo.nIdentify =tonumber(row.Identify) or 0; -- 身份
        ClubUserInfo.nContribution =tonumber(row.Contribution) or 0; --累计贡献(俱乐部币)
        ClubUserInfo.nGold=tonumber(row.Gold) or 0; --金币
        ClubUserInfo.nClubGold=tonumber(row.ClubGold) or 0; --俱乐部币
        ClubUserInfo.sShopAcc = row.ShopAccount or ""
        ClubUserInfo.nGoldContribution =tonumber(row.GoldContribution) or 0; --累计贡献(金币)
        ClubUserInfo.nCreateTime = row.nCreateTime or ""
        table.insert(arrUser,ClubUserInfo)
    end

    local nLen = #arrUser
    local nSendLen = 10 --每次发送10条
    if nLen>nSendLen then
        local arrTemp = {}
        local nAllPage = math.ceil(nLen/nSendLen)
        local nPage = 1
        for i=1,nLen do
            table.insert(arrTemp,arrUser[i])
            if i%nSendLen==0 or i==nLen then
                local SearchClubMemberRsp ={}
                SearchClubMemberRsp.arrUser =arrUser
                SearchClubMemberRsp.nPage = nPage
                SearchClubMemberRsp.nAllPage = nAllPage
                SearchClubMemberRsp.nUserId = tData.nUserId
                SearchClubMemberRsp.nClubId = tData.nClubId
                DbClubSendToServer(sReturnKey,"SearchClubMemberRsp",SearchClubMemberRsp)
                arrTemp = {}
                nPage = nPage + 1
            end
        end
    else
        local SearchClubMemberRsp ={}
        SearchClubMemberRsp.arrUser =arrUser
        SearchClubMemberRsp.nPage = 1
        SearchClubMemberRsp.nAllPage = 1
        SearchClubMemberRsp.nUserId = tData.nUserId
        SearchClubMemberRsp.nClubId = tData.nClubId
        DbClubSendToServer(sReturnKey,"SearchClubMemberRsp",SearchClubMemberRsp)
    end
end

--搜索俱乐部成员 请求
function ClubSink.OnSearchClubMemberReq_old(sReturnKey,Data,nLen)
    local strReq ="SearchClubMemberReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_SearchMembers(%d,'%s')",tData.nClubId,tData.str)
    tBase.Log("OnSearchClubMemberReq sSql:%s",sSql)

    local arrUser = {}
    local arrRows =AccountsDB_SqlExecute(sSql,true)
    for _,row in ipairs(arrRows) do
        local ClubUserInfo ={}
        ClubUserInfo.nUserId =tData.nUserId; --玩家id
        ClubUserInfo.sFaceId =row.FaceID or ""; -- url	  
        ClubUserInfo.sName =row.NickName or ""; -- 昵称 
        ClubUserInfo.nSex =tonumber(row.Sex) or 0; -- 性别 0:男 1:女
        ClubUserInfo.nClubId =tData.nClubId; -- 俱乐部id
        ClubUserInfo.nIdentify =tonumber(row.Identify) or 0; -- 身份
        ClubUserInfo.nContribution =tonumber(row.Contribution) or 0; --累计贡献(俱乐部币)
        ClubUserInfo.nGold=tonumber(row.Gold) or 0; --金币
        ClubUserInfo.nClubGold=tonumber(row.ClubGold) or 0; --俱乐部币
        ClubUserInfo.sShopAcc = row.ShopAccount or ""
        ClubUserInfo.nGoldContribution =tonumber(row.GoldContribution) or 0; --累计贡献(金币)
        table.insert(arrUser,ClubUserInfo)
    end

    local nLen = #arrUser
    local nSendLen = 10 --每次发送10条
    if nLen>nSendLen then
        local arrTemp = {}
        local nAllPage = math.ceil(nLen/nSendLen)
        local nPage = 1
        for i=1,nLen do
            table.insert(arrTemp,arrUser[i])
            if i%nSendLen==0 or i==nLen then
                local SearchClubMemberRsp ={}
                SearchClubMemberRsp.arrUser =arrUser
                SearchClubMemberRsp.nPage = nPage
                SearchClubMemberRsp.nAllPage = nAllPage
                SearchClubMemberRsp.nUserId = tData.nUserId
                SearchClubMemberRsp.nClubId = tData.nClubId
                DbClubSendToServer(sReturnKey,"SearchClubMemberRsp",SearchClubMemberRsp)
                arrTemp = {}
                nPage = nPage + 1
            end
        end
    else
        local SearchClubMemberRsp ={}
        SearchClubMemberRsp.arrUser =arrUser
        SearchClubMemberRsp.nPage = 1
        SearchClubMemberRsp.nAllPage = 1
        SearchClubMemberRsp.nUserId = tData.nUserId
        SearchClubMemberRsp.nClubId = tData.nClubId
        DbClubSendToServer(sReturnKey,"SearchClubMemberRsp",SearchClubMemberRsp)
    end
end

--俱乐部个人历史牌局 请求
function ClubSink.OnClubPaiJuRecordReq(sReturnKey,Data,nLen)
    local strReq ="ClubPaiJuRecordReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetUserPaiJuRecord(%d,%d,%d,%d)",tData.nClubId,tData.nUserId,tData.nIdOfStart,tData.nCnt)
    tBase.Log("OnClubPaiJuRecordReq sSql:%s",sSql)

    local nAllCnt = 0
    local arrRecords = {}

    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local tHandCards,tTableInfo = {},{}
        local isSuccee1,tUsersInfo = pcall(cjson.decode,row.UsersInfo)
        if not isSuccee1 then
            tUsersInfo = {}
            Base.Log("_OnClubPaiPuReq decode UsersInfo fail PaiJuId_%s",row.PaiJuId or "")
        end
        local isSuccee2,tDealCardInfo = pcall(cjson.decode,row.DealCardInfo)
        if not isSuccee2 then
            tDealCardInfo = {}
            Base.Log("_OnClubPaiPuReq decode DealCardInfo fail PaiJuId_%s",row.PaiJuId or "")
        end
        local isSuccee3,tElseInfo = pcall(cjson.decode,row.ElseInfo)
        if not isSuccee3 then
            tElseInfo = {}
            Base.Log("_OnClubPaiPuReq decode ElseInfo fail PaiJuId_%s",row.PaiJuId or "")
        end
        --手牌信息
        local nSitId = -1
        for _,tUserInfo in pairs(tUsersInfo) do
            if tUserInfo.nUserId==tData.nUserId then
                nSitId = tUserInfo.nSitId
                break
            end
        end
        for _,tCardInfo in pairs(tDealCardInfo) do
            if tCardInfo.nSitId==nSitId or tCardInfo.nUserId==tData.nUserId then
                tHandCards.nCardType = tCardInfo.nCardType
                tHandCards.arrCard = tCardInfo.arrCard
                break
            end
        end
        --牌桌配置信息
        tTableInfo = tElseInfo.tTableInfo or {}
        tTableInfo.nPool = 0 --总底池
        for _,nPool in pairs(tElseInfo.arrPool or {}) do
            tTableInfo.nPool = tTableInfo.nPool + nPool
        end

        local tClubPaiJuRecordItem = {}
        tClubPaiJuRecordItem.nId = tonumber(row.id) or 0
        tClubPaiJuRecordItem.sPaiJuID = row.PaiJuId or ""
        tClubPaiJuRecordItem.nWinLose = tonumber(row.WinLose) or 0
        tClubPaiJuRecordItem.nGameId = tonumber(row.GameType) or 0
        tClubPaiJuRecordItem.sTime = row.CreateTime or ""
        tClubPaiJuRecordItem.sTableInfo = cjson.encode(tTableInfo)
        tClubPaiJuRecordItem.sHandCards = cjson.encode(tHandCards)
        tClubPaiJuRecordItem.nClubId = tonumber(row.ClubId) or 0
        tClubPaiJuRecordItem.nCollect = tonumber(row.nCollect) or 0
        table.insert(arrRecords,tClubPaiJuRecordItem)
        nAllCnt = tonumber(row.nAllCnt) or 0
    end

    local ClubPaiJuRecordRsp = {}
    ClubPaiJuRecordRsp.arrRecords = arrRecords
    ClubPaiJuRecordRsp.nClubId = tData.nClubId
    ClubPaiJuRecordRsp.nAllCnt = nAllCnt
    ClubPaiJuRecordRsp.nUserId = tData.nUserId
    ClubPaiJuRecordRsp.nSendUserId = tData.nSendUserId
    DbClubSendToServer(sReturnKey,"ClubPaiJuRecordRsp",ClubPaiJuRecordRsp)
end

--俱乐部个人贡献(俱乐部收益) 请求
function ClubSink.OnClubContribRecordReq(sReturnKey,Data,nLen)
    local strReq ="ClubContribRecordReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local nAllCnt = 0
    local arrRecords = {}
    local nTotalContrib = 0
    local nServiceCharge = 0
    local nPropsIncome = 0
    local nInsurance = 0

    local nItemId = tData.nClubId
    if tData.nType==1 then
        nItemId = 1
    end

    if tData.nUserId==0 then --俱乐部收益记录
        local sSql = string.format("call Club_GetClubIncomeRecord(%d,%d,%d,%d)",tData.nClubId,nItemId,tData.nIdOfStart,tData.nCnt)
        tBase.Log("OnClubContribRecordReq sSql:%s",sSql)

        local arrRows = RecordDB_SqlExecute(sSql,true)
        for _,row in pairs(arrRows) do
            local ClubContribItem = {}
            ClubContribItem.nId = tonumber(row.id) or 0
            ClubContribItem.nSourceType = tonumber(row.SourceType) or 0
            ClubContribItem.nContrib = tonumber(row.nChange) or 0
            ClubContribItem.sTime = row.CreateTime or ""
            table.insert(arrRecords,ClubContribItem)
            nTotalContrib = tonumber(row.nTotalIncome) or 0
            nServiceCharge = tonumber(row.nServiceCharge) or 0
            nPropsIncome = tonumber(row.nPropsIncome) or 0
            nInsurance = tonumber(row.nInsurance) or 0
            nAllCnt = tonumber(row.nAllCnt) or 0
        end
    else --俱乐部个人贡献记录
        local sSql = string.format("call Club_GetContribRecord(%d,%d,%d,%d,%d)",tData.nClubId,tData.nUserId,tData.nIdOfStart,tData.nCnt,nItemId)
        tBase.Log("OnClubContribRecordReq sSql:%s",sSql)

        local arrRows = RecordDB_SqlExecute(sSql,true)
        for _,row in pairs(arrRows) do
            local ClubContribItem = {}
            ClubContribItem.nId = tonumber(row.id) or 0
            ClubContribItem.nSourceType = tonumber(row.SourceType) or 0
            ClubContribItem.nContrib = tonumber(row.nChange) or 0
            ClubContribItem.sTime = row.CreateTime or ""
            table.insert(arrRecords,ClubContribItem)
            nTotalContrib = tonumber(row.nTotalContrib) or 0
            nServiceCharge = tonumber(row.nServiceCharge) or 0
            nPropsIncome = tonumber(row.nPropsIncome) or 0
            nInsurance = tonumber(row.nInsurance) or 0
            nAllCnt = tonumber(row.nAllCnt) or 0
        end
    end

    local ClubContribRecordRsp = {}
    ClubContribRecordRsp.arrRecords = arrRecords
    ClubContribRecordRsp.nClubId = tData.nClubId
    ClubContribRecordRsp.nAllCnt = nAllCnt
    ClubContribRecordRsp.nSendUserId = tData.nSendUserId
    ClubContribRecordRsp.nTotalContrib=nTotalContrib
    ClubContribRecordRsp.nType=tData.nType
    ClubContribRecordRsp.nServiceCharge=nServiceCharge
    ClubContribRecordRsp.nPropsIncome=nPropsIncome
    ClubContribRecordRsp.nInsurance=nInsurance
    DbClubSendToServer(sReturnKey,"ClubContribRecordRsp",ClubContribRecordRsp)
end

--俱乐部黑名单 请求
function ClubSink.OnClubBlacklistReq(sReturnKey,Data,nLen)
    local strReq ="ClubBlacklistReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetBlacklist(%d,%d,%d)",tData.nClubId,tData.nIdOfStart,tData.nCnt)
    tBase.Log("OnClubBlacklistReq sSql:%s",sSql)

    local nAllCnt = 0
    local arrBlacklist = {}

    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local ClubBlackListItem = {}
        ClubBlackListItem.nId = tonumber(row.id) or 0
        ClubBlackListItem.nUserId = tonumber(row.UserId) or 0
        ClubBlackListItem.sFaceId = row.FaceID or ""
        ClubBlackListItem.sName = row.NickName or ""
        ClubBlackListItem.nSex = tonumber(row.Sex) or 0
        ClubBlackListItem.sTime = row.CreateTime or ""
        ClubBlackListItem.sShopAcc = row.ShopAccount or ""
        table.insert(arrBlacklist,ClubBlackListItem)
        nAllCnt = tonumber(row.nAllCnt) or 0
    end

    local ClubBlacklistRsp = {}
    ClubBlacklistRsp.arrBlacklist = arrBlacklist
    ClubBlacklistRsp.nClubId = tData.nClubId
    ClubBlacklistRsp.nAllCnt = nAllCnt
    ClubBlacklistRsp.nUserId = tData.nUserId
    DbClubSendToServer(sReturnKey,"ClubBlacklistRsp",ClubBlacklistRsp)
end

--黑名单管理操作 请求
function ClubSink.OnClubBlacklistMgrReq(sReturnKey,Data,nLen)
    local strReq ="ClubBlacklistMgrReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_HandleBlacklist(%d,%d,%d,%d)",tData.nClubId,tData.nOpType,tData.nUserId,tData.nOpUserId)
    tBase.Log("OnClubBlacklistMgrReq sSql:%s",sSql)

    local arrRows = RecordDB_SqlExecute(sSql)
    local row = arrRows[1]
    local nRlt = tonumber(row.ErrCode) or 99

    local ClubBlacklistMgrRsp = {}
    ClubBlacklistMgrRsp.nRlt = nRlt
    ClubBlacklistMgrRsp.nUserId = tData.nUserId
    ClubBlacklistMgrRsp.nOpType = tData.nOpType
    ClubBlacklistMgrRsp.nClubId = tData.nClubId
    ClubBlacklistMgrRsp.nOpUserId = tData.nOpUserId
    DbClubSendToServer(sReturnKey,"ClubBlacklistMgrRsp",ClubBlacklistMgrRsp)
end

--黑名单玩家搜索 请求
function ClubSink.OnClubBlacklistSearchReq(sReturnKey,Data,nLen)
    local strReq ="ClubBlacklistSearchReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_SearchBlacklist(%d,'%s')",tData.nClubId,tData.str)
    tBase.Log("OnClubBlacklistSearchReq sSql:%s",sSql)


    local arrBlacklist = {}
    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local ClubBlackListItem = {}
        ClubBlackListItem.nId = tonumber(row.id) or 0
        ClubBlackListItem.nUserId = tonumber(row.UserId) or 0
        ClubBlackListItem.sFaceId = row.FaceID or ""
        ClubBlackListItem.sName = row.NickName or ""
        ClubBlackListItem.nSex = tonumber(row.Sex) or 0
        ClubBlackListItem.sTime = row.CreateTime or ""
        ClubBlackListItem.sShopAcc = row.ShopAccount or ""
        table.insert(arrBlacklist,ClubBlackListItem)
    end

    local nLen = #arrBlacklist
    local nSendLen = 10
    local nAllPage = math.ceil(nLen/nSendLen)
    if nAllPage==0 then
        nAllPage = 1
    end

    if nLen>nSendLen then
        local arrTemp = {}
        local nPage = 1 
        for i=1,nLen do
            table.insert(arrTemp,arrBlacklist[i])
            if i%nSendLen==0 or i==nLen then
                local ClubBlacklistSearchRsp = {}
                ClubBlacklistSearchRsp.arrBlacklist = arrTemp
                ClubBlacklistSearchRsp.nClubId = tData.nClubId
                ClubBlacklistSearchRsp.nPage = nPage
                ClubBlacklistSearchRsp.nAllPage = nAllPage
                ClubBlacklistSearchRsp.nUserId = tData.nUserId
                DbClubSendToServer(sReturnKey,"ClubBlacklistSearchRsp",ClubBlacklistSearchRsp)
                arrTemp = {}
                nPage = nPage + 1
            end
        end
    else
        local ClubBlacklistSearchRsp = {}
        ClubBlacklistSearchRsp.arrBlacklist = arrBlacklist
        ClubBlacklistSearchRsp.nClubId = tData.nClubId
        ClubBlacklistSearchRsp.nPage = 1
        ClubBlacklistSearchRsp.nAllPage = nAllPage
        ClubBlacklistSearchRsp.nUserId = tData.nUserId
        DbClubSendToServer(sReturnKey,"ClubBlacklistSearchRsp",ClubBlacklistSearchRsp)
    end
end

--俱乐部牌桌记录 请求
function ClubSink.OnClubTableRecordReq(sReturnKey,Data,nLen)
    local strReq ="ClubTableRecordReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetTableRecord(%d,%d,%d,%d)",tData.nClubId,tData.nUserId,tData.nIdOfStart,tData.nCnt)
    tBase.Log("OnClubTableRecordReq sSql:%s",sSql)

    local nAllCnt = 0
    local arrRecords = {}
    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local TableRecordItem = {}
        TableRecordItem.nId = tonumber(row.id) or 0
        TableRecordItem.sTableId = row.TableId or ""
        TableRecordItem.sTableInfo = row.TableInfo or ""
        TableRecordItem.sTime = row.CreateTime or ""
        table.insert(arrRecords,TableRecordItem)
        nAllCnt = tonumber(row.nAllCnt) or 0
    end

    local ClubTableRecordRsp = {}
    ClubTableRecordRsp.arrRecords = arrRecords
    ClubTableRecordRsp.nClubId = tData.nClubId
    ClubTableRecordRsp.nAllCnt = nAllCnt
    ClubTableRecordRsp.nUserId = tData.nUserId
    DbClubSendToServer(sReturnKey,"ClubTableRecordRsp",ClubTableRecordRsp)
end

--俱乐部牌桌参与玩家 请求
function ClubSink.OnClubTableUserReq(sReturnKey,Data,nLen)
    local strReq ="ClubTableUserReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetTableUser('%s',%d,%d)",tData.sTableId,tData.nIdOfStart,tData.nCnt)
    tBase.Log("OnClubTableUserReq sSql:%s",sSql)

    local nAllCnt = 0
    local arrUser = {}
    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local ClubTableUser = {}
        ClubTableUser.nId = tonumber(row.id) or 0
        ClubTableUser.nUserId = tonumber(row.UserId) or 0
        ClubTableUser.sFaceId = row.FaceID or ""
        ClubTableUser.sName = row.NickName or ""
        ClubTableUser.nSex = tonumber(row.Sex) or 0
        ClubTableUser.nClubId = tonumber(row.ClubId) or 0
        ClubTableUser.nIdentify = tonumber(row.Identify) or 0
        ClubTableUser.sShopAcc = row.ShopAccount or ""
        ClubTableUser.nPlayCnt = tonumber(row.PlayCnt) or 0
        ClubTableUser.nWinLose = tonumber(row.WinLose) or 0
        ClubTableUser.nContribution = tonumber(row.Contribution) or 0
        ClubTableUser.nItemId = tonumber(row.ItemId) or 0
        table.insert(arrUser,ClubTableUser)
        nAllCnt = tonumber(row.nAllCnt) or 0
    end

    local ClubTableUserRsp = {}
    ClubTableUserRsp.arrUser = arrUser
    ClubTableUserRsp.sTableId = tData.sTableId
    ClubTableUserRsp.nAllCnt = nAllCnt
    ClubTableUserRsp.nUserId = tData.nUserId
    DbClubSendToServer(sReturnKey,"ClubTableUserRsp",ClubTableUserRsp)
end

--俱乐部成员信息 请求
function ClubSink.OnClubMemberInfoReq(sReturnKey,Data,nLen)
    local strReq ="ClubMemberInfoReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetClubMemberInfo(%d,%d)",tData.nClubId,tData.nUserId)
    tBase.Log("OnClubMemberInfoReq sSql:%s",sSql)

    local ClubMemberInfoRsp = {}
    ClubMemberInfoRsp.nRlt = 0
    ClubMemberInfoRsp.nUserId = tData.nUserId
    ClubMemberInfoRsp.nClubId = tData.nClubId
    ClubMemberInfoRsp.nSendUserId = tData.nSendUserId

    local arrRows =AccountsDB_SqlExecute(sSql,true)
    local row = arrRows[1]
    if row then
        local nUserId = tonumber(row.UserId)
        if nUserId then
            local ClubUserInfo ={}
            ClubUserInfo.nUserId =tData.nUserId; --玩家id
            ClubUserInfo.sFaceId =row.FaceID or ""; -- url	  
            ClubUserInfo.sName =row.NickName or ""; -- 昵称 
            ClubUserInfo.nSex =tonumber(row.Sex) or 0; -- 性别 0:男 1:女
            ClubUserInfo.nClubId =tData.nClubId; -- 俱乐部id
            ClubUserInfo.nIdentify =tonumber(row.Identify) or 0; -- 身份
            ClubUserInfo.nContribution =tonumber(row.Contribution) or 0; --累计贡献(俱乐部币)
            ClubUserInfo.nClubGold=tonumber(row.ClubGold) or 0; --俱乐部币
            ClubUserInfo.sShopAcc = row.ShopAccount or ""
            ClubUserInfo.nGoldContribution =tonumber(row.GoldContribution) or 0; --累计贡献(金币部币)
            ClubMemberInfoRsp.tUserInfo = ClubUserInfo
        else
            ClubMemberInfoRsp.nRlt = 1
        end
    else
        ClubMemberInfoRsp.nRlt = 1
    end

    DbClubSendToServer(sReturnKey,"ClubMemberInfoRsp",ClubMemberInfoRsp)
end

--俱乐部管理员列表 请求
function ClubSink.OnClubAdminListReq(sReturnKey,Data,nLen)
    local strReq ="ClubAdminListReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetClubAdminList(%d,%d,%d)",tData.nClubId,tData.nCnt,tData.nPage)
    tBase.Log("OnClubAdminListReq sSql:%s",sSql)

    local arrAdminList = {}
    local nAllCnt = 0
    local arrRows =AccountsDB_SqlExecute(sSql,true)
    for _,row in ipairs(arrRows) do
        local ClubUserInfo ={}
        ClubUserInfo.nUserId =tonumber(row.UserId) or 0; --玩家id
        ClubUserInfo.sFaceId =row.FaceID or ""; -- url	  
        ClubUserInfo.sName =row.NickName or ""; -- 昵称 
        ClubUserInfo.nSex =tonumber(row.Sex) or 0; -- 性别 0:男 1:女
        ClubUserInfo.nClubId =tData.nClubId; -- 俱乐部id
        ClubUserInfo.nIdentify =tonumber(row.Identify) or 0; -- 身份  1:主席  10:管理员  20:普通成员
        ClubUserInfo.sShopAcc = row.ShopAccount or ""
        ClubUserInfo.sPower = GetUserPower(row) --权限
        nAllCnt = tonumber(row.AllCnt) or 0; --总人数
        table.insert(arrAdminList,ClubUserInfo)
    end

    local ClubAdminListRsp ={}
    ClubAdminListRsp.arrAdminList =arrAdminList
    ClubAdminListRsp.nPage = tData.nPage
    ClubAdminListRsp.nAllCnt = nAllCnt
    ClubAdminListRsp.nUserId = tData.nUserId
    ClubAdminListRsp.nClubId = tData.nClubId
    DbClubSendToServer(sReturnKey,"ClubAdminListRsp",ClubAdminListRsp)
end

--俱乐部增加删除管理员 请求
function ClubSink.OnClubAdminMgrReq(sReturnKey,Data,nLen)
    local strReq ="ClubAdminMgrReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local ClubAdminMgrRsp = {}
    ClubAdminMgrRsp.nRlt = 0
    ClubAdminMgrRsp.nSendUserId = tData.nSendUserId
    ClubAdminMgrRsp.nUserId = tData.nUserId
    ClubAdminMgrRsp.nOpType = tData.nOpType
    ClubAdminMgrRsp.nClubId = tData.nClubId

    if tData.nOpType==1 then
        local sSql = string.format("call Club_AddAdmin(%d,%d)",tData.nClubId,tData.nUserId)
        tBase.Log("OnClubAdminMgrReq sSql:%s",sSql)

        local arrRows =AccountsDB_SqlExecute(sSql)
        local row = arrRows[1]
        local nRlt = tonumber(row.ErrCode)
        ClubAdminMgrRsp.nRlt = nRlt
        if nRlt==0 then
            local ClubUserInfo ={}
            ClubUserInfo.nUserId =tData.nUserId; --玩家id
            ClubUserInfo.sFaceId =row.sFaceID or ""; -- url	  
            ClubUserInfo.sName =row.sNickName or ""; -- 昵称 
            ClubUserInfo.nSex =tonumber(row.Sex) or 0; -- 性别 0:男 1:女
            ClubUserInfo.nClubId =tData.nClubId; -- 俱乐部id
            ClubUserInfo.nIdentify =tonumber(row.nIdentify); -- 身份  1:主席  10:管理员  20:普通成员
            ClubUserInfo.sShopAcc = row.sShopAccount or "" 
            tBase.Log("OnClubAdminMgrReq ClubUserInfo: %s",cjson.encode(ClubUserInfo)) 
            ClubAdminMgrRsp.tAdmin = ClubUserInfo
        end
    elseif tData.nOpType==2 then
        local sSql = string.format("call Club_DelAdmin(%d,%d)",tData.nClubId,tData.nUserId)
        tBase.Log("OnClubAdminMgrReq sSql:%s",sSql)
        local arrRows =AccountsDB_SqlExecute(sSql)
        local row = arrRows[1]
        local nRlt = tonumber(row.ErrCode)
        ClubAdminMgrRsp.nRlt = nRlt
    else
        ClubAdminMgrRsp.nRlt = 3
    end

    if ClubAdminMgrRsp.nRlt==0 then
        local sSql1= string.format("call Club_WriteUserNotice(%d,%d,'%s')",tData.nUserId,1,tData.sExData)
        tBase.Log("OnClubAdminMgrReq sSql1:%s",sSql1)
        RecordDB_SqlExecute(sSql1)

        local nType = 2
        if tData.nOpType==2 then
            nType = 3
        end
        local sSql2 = string.format("call Club_SetOprationRecord(%d,%d,%d,%d,'%s')",tData.nClubId,nType,tData.nSendUserId,tData.nUserId,"")
        tBase.Log("OnClubAdminMgrReq sSql2:%s",sSql2)
        RecordDB_SqlExecute(sSql2)
    end

    DbClubSendToServer(sReturnKey,"ClubAdminMgrRsp",ClubAdminMgrRsp)
end

--修改管理员权限 请求
function ClubSink.OnClubChangeAdminPowerReq(sReturnKey,Data,nLen)
    local strReq ="ClubChangeAdminPowerReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local isSuccee,arrPower = pcall(cjson.decode,tData.sPower)
    if not isSuccee then
        arrPower = {}
        tBase.Log("OnClubChangeAdminPowerReq decode sPower fail")
        if type(arrPower) == "string" then 
            logger:error(arrPower)
        else 
            tBase.LogT(arrPower) 
        end
    end

    local sPower = ""
    local nRlt = 2

    for k,v in pairs(arrPower) do
        local sSql = string.format("call Club_ChangeAdminPower(%d,%d,%d,'%s')",tData.nClubId,tData.nUserId,v.nPowerType,tostring(v.isOpen))
        tBase.Log("OnClubChangeAdminPowerReq sSql:%s",sSql)
        local arrRows =AccountsDB_SqlExecute(sSql)
        local row = arrRows[1]
        local nErrCode = tonumber(row.ErrCode) or 99
        if nRlt==2 then
            nRlt = nErrCode
        elseif nRlt~=0 then
            nRlt = nErrCode
        end
        if nRlt==0 then
            sPower = GetUserPower(row)
        end
        tBase.Log("OnClubChangeAdminPowerReq after SqlExecute,nErrCode_%d sPower_%s",nErrCode,sPower)
    end

    if nRlt==0 then
        local sSql1= string.format("call Club_WriteUserNotice(%d,%d,'%s')",tData.nUserId,1,tData.sExData)
        tBase.Log("OnClubChangeAdminPowerReq sSql1:%s",sSql1)
        RecordDB_SqlExecute(sSql1)
        
        local sSql2 = string.format("call Club_SetOprationRecord(%d,%d,%d,%d,'%s')",tData.nClubId,4,tData.nSendUserId,tData.nUserId,tData.sPower)
        tBase.Log("OnClubChangeAdminPowerReq sSql2:%s",sSql2)
        RecordDB_SqlExecute(sSql2)
    end

    local ClubChangeAdminPowerRsp = {}
    ClubChangeAdminPowerRsp.nRlt = nRlt
    ClubChangeAdminPowerRsp.nSendUserId = tData.nSendUserId
    ClubChangeAdminPowerRsp.nUserId = tData.nUserId
    ClubChangeAdminPowerRsp.nClubId = tData.nClubId
    if sPower~="" then
        ClubChangeAdminPowerRsp.sPower = sPower
    end
    DbClubSendToServer(sReturnKey,"ClubChangeAdminPowerRsp",ClubChangeAdminPowerRsp)
end

--俱乐部申请列表请求 请求
function ClubSink.OnClubApplyListReq(sReturnKey,Data,nLen)
    local strReq ="ClubApplyListReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local nAllCnt = 0
    local arrApplyList = {}

    if tData.nType==1 or tData.nType==2 then
        local sSql = string.format("call Club_GetClubGoldApplyList(%d,%d,%d,%d)",tData.nClubId,tData.nType,tData.nIdOfStart,tData.nCnt)
        tBase.Log("OnClubApplyListReq sSql:%s",sSql)

        local arrRows = RecordDB_SqlExecute(sSql,true)
        for _,row in pairs(arrRows) do
            local ClubApplyItem = {}
            ClubApplyItem.nId = tonumber(row.id) or 0
            ClubApplyItem.nUserId = tonumber(row.UserId) or 0
            ClubApplyItem.sFaceId = row.FaceID or ""
            ClubApplyItem.sName = row.NickName or ""
            ClubApplyItem.nSex = tonumber(row.Sex) or 0
            ClubApplyItem.sTime = row.CreateTime or ""
            ClubApplyItem.nType = tonumber(row.nType) or 0
            ClubApplyItem.nChange = tonumber(row.nChange) or 0
            table.insert(arrApplyList,ClubApplyItem)
            nAllCnt = tonumber(row.nAllCnt) or 0
        end
    elseif tData.nType==3 then
        local sSql = string.format("call Club_GetApplyList(%d,%d,%d)",tData.nClubId,tData.nIdOfStart,tData.nCnt)
        tBase.Log("OnClubApplyListReq sSql:%s",sSql)

        local arrRows = RecordDB_SqlExecute(sSql,true)
        for _,row in pairs(arrRows) do
            local ClubApplyItem = {}
            ClubApplyItem.nId = tonumber(row.id) or 0
            ClubApplyItem.nUserId = tonumber(row.UserId) or 0
            ClubApplyItem.sFaceId = row.FaceID or ""
            ClubApplyItem.sName = row.NickName or ""
            ClubApplyItem.nSex = tonumber(row.Sex) or 0
            ClubApplyItem.sTime = row.CreateTime or ""
            ClubApplyItem.nType = tonumber(row.nType) or 0
            table.insert(arrApplyList,ClubApplyItem)
            nAllCnt = tonumber(row.nAllCnt) or 0
        end
    end
    

    local ClubApplyListRsp = {}
    ClubApplyListRsp.arrApplyList = arrApplyList
    ClubApplyListRsp.nClubId = tData.nClubId
    ClubApplyListRsp.nAllCnt = nAllCnt
    ClubApplyListRsp.nUserId = tData.nUserId
    ClubApplyListRsp.nType = tData.nType
    DbClubSendToServer(sReturnKey,"ClubApplyListRsp",ClubApplyListRsp)
end

--俱乐部申请处理 请求
function ClubSink.OnClubApplyHandleReq(sReturnKey,Data,nLen)
    local strReq ="ClubApplyHandleReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    --管理员的信息
    local tOpTUserinfo = tPubUsrApi.GetAllUserInfo(tData.nOpUserId) or {}

    local nRlt = 99
    local tExData = {
        nClubId=tData.nClubId,
        nType=tData.nType,
        nId=tData.nId,
        nTUserId=tData.nTUserId,
        nOpType=tData.nOpType,
        nOpUserId=tData.nOpUserId,
        sUserName=tOpTUserinfo.sNickName,
        sFaceId=tOpTUserinfo.sFaceID,
    }

    local nOpType = 10
    local sExtra = ""
    local nNoticeExtra = ""

    if tData.nType==1 or tData.nType==2 then
        --俱乐部币申请
        local sSql = string.format("call Club_HanleClubGoldApply(%d,%d,%d,%d,%d)",tData.nId,tData.nOpType,tData.nOpUserId,tData.nClubId,tData.nType)
        tBase.Log("OnClubApplyHandleReq sSql:%s",sSql)
        local arrRows = RecordDB_SqlExecute(sSql)
        local row = arrRows[1]
        nRlt = tonumber(row.ErrCode) or 99
        if nRlt==0 then
            tExData.nApplyCnt= tonumber(row.nApplyCnt) or 0
            tExData.nTUserId = tonumber(row.nTUserId) or 0
            tExData.nMaster = tonumber(row.nMaster)
            tExData.sClubName = row.sClubName
            local nChange = tonumber(row.nnChange) or 0

            local nNoticeType = 8
            if tData.nType==2 then
                nOpType = 11
                nNoticeType = 9
            end
            sExtra = cjson.encode({id=tData.nId,nOpType=tData.nOpType})
            nNoticeExtra = cjson.encode({
                id=tData.nId,
                isAgree=tData.nOpType,
                sClubName=tExData.sClubName,
                nClubId=tData.nClubId,
                nUserId=tData.nOpUserId,
                sUserName=tExData.sUserName,
                sFaceId=tExData.sFaceId,
                nOpType=nNoticeType,
                nChange=nChange,
            })
        end
    elseif tData.nType==3 then 
        --加入俱乐部申请
        local sSql = string.format("call Club_HanleApplyJoin(%d,%d,%d,%d)",tData.nId,tData.nOpType,tData.nOpUserId,tData.nMaxUserCnt)
        tBase.Log("OnClubApplyHandleReq sSql:%s",sSql)
        local arrRows = AccountsDB_SqlExecute(sSql)
        local row = arrRows[1]
        nRlt = tonumber(row.ErrCode) or 99
        if nRlt==0 then
            tExData.nApplyCnt = tonumber(row.nApplyCnt) or 0
            tExData.nUserApplyCnt = tonumber(row.nUserApplyCnt) or 0
            tExData.nMaster = tonumber(row.nMaster)
            tExData.sClubName = row.sClubName or ""
            tExData.nUserCnt = tonumber(row.nMembers) or 0
            tExData.nTUserId = tonumber(row.nTUserId) or 0
            if tData.nOpType==1 then
                --把新加入的玩家信息写入redis
                tPublicRedis.SetClubUserInfo(tData.nClubId,{{nUserId=tExData.nTUserId,nIdentify=20,sPower=GetUserPower({})}})
            end

            nOpType = 9
            sExtra = cjson.encode({id=tData.nId,nOpType=tData.nOpType})
            nNoticeExtra = cjson.encode({
                id=tData.nId,
                isAgree=tData.nOpType,
                sClubName=tExData.sClubName,
                nClubId=tData.nClubId,
                nUserId=tData.nOpUserId,
                sUserName=tExData.sUserName,
                sFaceId=tExData.sFaceId,
                nOpType=7,
            })
        end
    end

    if nRlt==0 then
        local sSql1 = string.format("call Club_SetOprationRecord(%d,%d,%d,%d,'%s')",tData.nClubId,nOpType,tData.nOpUserId,tData.nTUserId,sExtra)
        tBase.Log("OnClubApplyHandleReq sSql1:%s",sSql1)
        RecordDB_SqlExecute(sSql1) 

        local sSql2= string.format("call Club_WriteUserNotice(%d,%d,'%s')",tData.nTUserId,1,nNoticeExtra)
        tBase.Log("OnClubApplyHandleReq sSql2:%s",sSql2)
        local arrRows2 = RecordDB_SqlExecute(sSql2)
        local row2 = arrRows2[1]
        if tonumber(row2.ErrCode)==0 then
            local nNoticeId = tonumber(row2.nId) or 0
            local sSql3= string.format("call Club_GetUserNoticeInfo(%d)",nNoticeId)
            tBase.Log("OnClubApplyHandleReq sSql3:%s",sSql3)
            local arrRows3 = RecordDB_SqlExecute(sSql3)
            local row3 = arrRows3[1]
            if row3 then
                local tNoticesItem = {}
                tNoticesItem.nId = tonumber(row3.id) or 0
                tNoticesItem.nType = tonumber(row3.nType) or 0
                tNoticesItem.nStatus = tonumber(row3.nStatus) or 0
                tNoticesItem.sTime = row3.CreateTime or ""
                tNoticesItem.sData = row3.sData or ""
                tNoticesItem.nHadRead = 0
                tExData.tNoticesItem = tNoticesItem
            end

            local sSql5= string.format("call Club_GetUserUnReadNoticesCnt(%d,%d)",tData.nTUserId,1)
            tBase.Log("OnClubApplyHandleReq sSql5:%s",sSql5)
            local arrRows5 = RecordDB_SqlExecute(sSql5)
            local row5 = arrRows5[1]
            if row5 then
                tExData.nUnReadCnt = tonumber(row5.nUnReadCnt) or 0
            end
        end

        local sSql4 = string.format("call Club_GetUserApplyInfo(%d,%d)",tData.nId,tData.nType)
        tBase.Log("OnClubApplyInfoReq sSql4:%s",sSql4)
        local arrRows4 = RecordDB_SqlExecute(sSql4)
        local row4 = arrRows4[1]
        if row4 then
            local tApply = {}
            tApply.nId = tonumber(row4.id) or 0
            tApply.nClubId = tonumber(row4.ClubId) or 0
            tApply.sClubName = row4.ClubName
            tApply.sTime = row4.CreateTime or ""
            tApply.nType = tonumber(row4.nType) or 0
            tApply.nStatus = tonumber(row4.nStatus) or 0
            if tApply.nType==1 or tApply.nType==2 then
                tApply.nChange = tonumber(row4.nChange) or 0
            end
            tExData.tApply = tApply
        end
    end

    local ClubApplyHandleRsp = {}
    ClubApplyHandleRsp.nRlt = nRlt
    ClubApplyHandleRsp.sExData = cjson.encode(tExData)
    DbClubSendToServer(sReturnKey,"ClubApplyHandleRsp",ClubApplyHandleRsp)
end

--俱乐部邀请用户 请求
function ClubSink.OnClubInviteUserReq(sReturnKey,Data,nLen)
    local strReq ="ClubInviteUserReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_InviteUser(%d,%d,%d)",tData.nClubId,tData.nUserId,tData.nSendUserId)
    tBase.Log("OnClubInviteUserReq sSql:%s",sSql)
    local arrRows = RecordDB_SqlExecute(sSql)
    local row = arrRows[1]
    local nRlt = tonumber(row.ErrCode) or 99
    local tsData = {}
    local tExtData = {}
    if nRlt==0 then
        tsData.sClubName = row.sClubName or ""
        tsData.nMaster = tonumber(row.nMaster) or 0
        tsData.nClubId = tData.nClubId
        tsData.nUserId = tData.nSendUserId
        tsData.sUserName = row.sUserName or ""
        tsData.sFaceId = row.sFaceId or ""

        tExtData.nId = tonumber(row.nId) or 0
        tExtData.nType = 2
        tExtData.nStatus = 0
        tExtData.sTime = row.sCreateTime or ""
        tExtData.sData = cjson.encode(tsData)
        tExtData.nUserId = tData.nUserId

        tExtData.nInvationCnt = tonumber(row.nInvationCnt) or 0
    end

    local ClubInviteUserRsp = {}
    ClubInviteUserRsp.nRlt = nRlt
    ClubInviteUserRsp.nClubId = tData.nClubId
    ClubInviteUserRsp.nUserId = tData.nUserId
    ClubInviteUserRsp.nSendUserId = tData.nSendUserId
    ClubInviteUserRsp.sExtData = cjson.encode(tExtData)
    DbClubSendToServer(sReturnKey,"ClubInviteUserRsp",ClubInviteUserRsp)
end

--搜索用户 请求
function ClubSink.OnClubSearchUserReq(sReturnKey,Data,nLen)
    local strReq ="ClubSearchUserReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_SearchClubUser(%d,%d,'%s')",tData.nUserId,tData.nClubId,tData.str)
    tBase.Log("OnClubSearchUserReq sSql:%s",sSql)
    local arrRows = AccountsDB_SqlExecute(sSql,true)
    local arrUser = {}
    for _,row in pairs(arrRows) do
        local tItem = {}
        tItem.nUserId = tonumber(row.UserID) or 0
        tItem.sFaceId = row.FaceID or ""
        tItem.sName = row.NickName or ""
        tItem.nSex = tonumber(row.Sex) or 0
        tItem.nStatus = tonumber(row.nStatus) or 0
        tItem.sTime = row.RegisTime or ""
        if tItem.nUserId>0 then
            table.insert(arrUser,tItem)
        end
    end

    local nSendLen = 20
    local nAllLen = #arrUser
    if nAllLen > nSendLen then
        local arrTemp = {}
        local nPage = 1
        local nAllPage = math.ceil(nAllLen/nSendLen)
        for k,v in ipairs(arrUser) do
            table.insert(arrTemp,v)

            if k%nSendLen==0 or k==nAllLen then
                local ClubSearchUserRsp = {}
                ClubSearchUserRsp.arrUser = arrTemp
                ClubSearchUserRsp.nPage = nPage
                ClubSearchUserRsp.nAllPage = nAllPage
                ClubSearchUserRsp.nUserId = tData.nUserId
                DbClubSendToServer(sReturnKey,"ClubSearchUserRsp",ClubSearchUserRsp)

                arrTemp = {}
                nPage = nPage + 1
            end
        end
    else
        local ClubSearchUserRsp = {}
        ClubSearchUserRsp.arrUser = arrUser
        ClubSearchUserRsp.nPage = 1
        ClubSearchUserRsp.nAllPage = 1
        ClubSearchUserRsp.nUserId = tData.nUserId
        DbClubSendToServer(sReturnKey,"ClubSearchUserRsp",ClubSearchUserRsp)
    end
end

-- 俱乐部某条申请的信息 请求
function ClubSink.OnClubApplyInfoReq(sReturnKey,Data,nLen)
    local strReq ="ClubApplyInfoReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local tApplyInfo = {nId=tData.nId,nType=tData.nType}

    local sSql = string.format("call Club_GetClubApplyInfo(%d,%d)",tData.nId,tData.nType)
    tBase.Log("OnClubApplyInfoReq sSql:%s",sSql)
    local arrRows = RecordDB_SqlExecute(sSql,true)
    local row = arrRows[1]
    if row then
        local nType = tonumber(row.nType) or 0
        if nType==1 or nType==2 then
            tApplyInfo.nId = tonumber(row.id) or 0
            tApplyInfo.nClubId = tonumber(row.ClubId) or 0
            tApplyInfo.nUserId = tonumber(row.UserId) or 0
            tApplyInfo.nType = tonumber(row.nType) or 0
            tApplyInfo.nChange = tonumber(row.nChange) or 0
            tApplyInfo.nStatus = tonumber(row.nStatus) or 0
        elseif nType==3 then
            tApplyInfo.nId = tonumber(row.id) or 0
            tApplyInfo.nClubId = tonumber(row.ClubId) or 0
            tApplyInfo.nUserId = tonumber(row.UserId) or 0
            tApplyInfo.nType = tonumber(row.nType) or 0
            tApplyInfo.nStatus = tonumber(row.nStatus) or 0
        end
    end

    local sApplyInfo = cjson.encode(tApplyInfo)
    
    tBase.Log("OnClubApplyInfoReq sApplyInfo:%s",sApplyInfo)

    local ClubApplyInfoRsp = {}
    ClubApplyInfoRsp.sExData = tData.sExData
    ClubApplyInfoRsp.sApplyInfo = sApplyInfo
    DbClubSendToServer(sReturnKey,"ClubApplyInfoRsp",ClubApplyInfoRsp)
end

-- 写俱乐部玩家结算记录 请求
function ClubSink.OnClubWriteUserRecordReq(sReturnKey,Data,nLen)
    local strReq ="ClubWriteUserRecordReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    --服务费
    if tData.nServiceCharge>0 then
        local sSql1 = string.format("call Club_WriteUserContribRecord(%d,%d,%d,%.2f,%d,%d)",tData.nUserId,tData.nClubId,tData.nItemId,tData.nServiceCharge,1,tData.nGameId)
        tBase.Log("OnClubWriteUserRecordReq sSql1:%s",sSql1)
        RecordDB_SqlExecute(sSql1)
    end

    --道具
    if tData.arrItemWinLose then
        for k,v in pairs(tData.arrItemWinLose) do
            if v.nContrib and v.nContrib>0 then
                local sSql5 = string.format("call Club_WriteUserContribRecord(%d,%d,%d,%.2f,%d,%d)",tData.nUserId,tData.nClubId,v.nItemId,v.nContrib,2,tData.nGameId)
                tBase.Log("OnClubWriteUserRecordReq sSql5:%s",sSql5)
                RecordDB_SqlExecute(sSql5)
            end
        end
    end

    --保险贡献
    if tData.nISContribution and tData.nISContribution>0 then
        local sSql4 = string.format("call Club_WriteUserContribRecord(%d,%d,%d,%.2f,%d,%d)",tData.nUserId,tData.nClubId,tData.nItemId,tData.nISContribution,3,tData.nGameId)
        tBase.Log("OnClubWriteUserRecordReq sSql4:%s",sSql4)
        RecordDB_SqlExecute(sSql4)
    end

    local nIsPaiJu =1
    if tData.sPaiJuId==nil or #tData.sPaiJuId<1 then
        nIsPaiJu =0
    end
    --个人记录
    local sSql2 = string.format("call Club_WriteUserRecord_v2(%d,'%s',%d,%.2f,%.2f,%d,%d,%.2f,%d)",tData.nClubId,tData.sTableId,tData.nUserId,tData.nWinlose,tData.nContribution,tData.nItemId,tData.nGameId,tData.nInsurance,nIsPaiJu)
    tBase.Log("OnClubWriteUserRecordReq sSql2:%s",sSql2)
    RecordDB_SqlExecute(sSql2)

    if nIsPaiJu==0 then
        return
    end
   
    --牌局记录
    local sSql3 = string.format("call Club_WritePaiJuRecord(%d,'%s',%d,'%s',%d,%d,%d,'%s')",
        tData.nClubId,tData.sTableId,tData.nUserId,tData.sPaiJuId,tData.nJuShu,tData.nGameId,tData.nKeepTime,tData.sTableName)
    tBase.Log("OnClubWriteUserRecordReq sSql3:%s",sSql3)
    RecordDB_SqlExecute(sSql3)

end

-- 写俱乐部玩家结算记录2 请求(大厅)
function ClubSink.OnClubWriteUserRecord2Req(sReturnKey,Data,nLen)
    local strReq ="ClubWriteUserRecord2Req"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    --[[ --服务费
    if tData.nServiceCharge>0 then
        local sSql1 = string.format("call Club_WriteUserContribRecord2(%d,%d,%d,%.2f,%d,%d)",tData.nUserId,tData.nClubId,tData.nItemId,tData.nServiceCharge,1,tData.nGameId)
        tBase.Log("OnClubWriteUserRecordReq sSql1:%s",sSql1)
        RecordDB_SqlExecute(sSql1)
    end

    --道具
    if tData.arrItemWinLose then
        for k,v in pairs(tData.arrItemWinLose) do
            if v.nContrib and v.nContrib>0 then
                local sSql5 = string.format("call Club_WriteUserContribRecord2(%d,%d,%d,%.2f,%d,%d)",tData.nUserId,tData.nClubId,v.nItemId,v.nContrib,2,tData.nGameId)
                tBase.Log("OnClubWriteUserRecordReq sSql5:%s",sSql5)
                RecordDB_SqlExecute(sSql5)
            end
        end
    end ]]

    --保险贡献
    if tData.nISContribution and tData.nISContribution>0 then
        local sSql4 = string.format("call Club_WriteUserContribRecord(%d,%d,%d,%.2f,%d,%d)",
            tData.nUserId,tData.nClubId,tData.nItemId,tData.nISContribution,3,tData.nGameId)
        tBase.Log("OnClubWriteUserRecordReq sSql4:%s",sSql4)
        RecordDB_SqlExecute(sSql4)
    end

    local nIsPaiJu =1
    if tData.sPaiJuId==nil or #tData.sPaiJuId<1 then
        nIsPaiJu =0
    end

    --个人记录
    local sSql2 = string.format("call Club_WriteUserRecordHall_v2(%d,'%s',%d,%.2f,%.2f,%d,%d,%.2f,%d)",
        tData.nClubId,tData.sTableName,tData.nUserId,tData.nWinlose,tData.nContribution,tData.nItemId,tData.nGameId,tData.nInsurance,nIsPaiJu)
    tBase.Log("OnClubWriteUserRecordReq sSql2:%s",sSql2)
    RecordDB_SqlExecute(sSql2)

    if nIsPaiJu==0 then
        return
    end

    --牌局记录
    local nGroupId =tPubUsrApi.Get_User_GroupId(tData.nUserId)
    local sSql3 = string.format("call Club_WritePaiJuRecordHall(%d,'%s',%d,'%s',%d,%d,%d)",
        tData.nClubId,tData.sTableName,tData.nUserId,tData.sPaiJuId,tData.nJuShu,tData.nGameId,nGroupId)
    tBase.Log("OnClubWriteUserRecordReq sSql3:%s",sSql3)
    RecordDB_SqlExecute(sSql3)

    --牌局记录(新增 把所有牌桌的记录信息都记录到同一张表 方便查询牌谱)
    local sSql4 = string.format("call Club_WritePaiJuRecord(%d,'%s',%d,'%s',%d,%d,%d,'%s')",
        tData.nClubId,tData.sTableId,tData.nUserId,tData.sPaiJuId,tData.nJuShu,tData.nGameId,tData.nKeepTime,tData.sTableName)
    tBase.Log("OnClubWriteUserRecordReq sSql3:%s",sSql4)
    RecordDB_SqlExecute(sSql4)
end

-- 写俱乐部牌桌记录 请求
function ClubSink.OnClubWriteTableRecordReq(sReturnKey,Data,nLen)
    local strReq ="ClubWriteTableRecordReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local nType = 1
    if tData.isEnd then
        nType = 2
    end

    local sSql = string.format("call Club_WriteTableRecord(%d,'%s','%s',%d,%d,%d,%d)",tData.nClubId,tData.sTableId,tData.sTableInfo,tData.nKeepSec,nType,tData.nLiveUserID,tData.nGameId)
    tBase.Log("OnClubWriteTableRecordReq sSql:%s",sSql)
    local arrRows = RecordDB_SqlExecute(sSql)

    local tTableInfo = cjson.decode(tData.sTableInfo)
    if tTableInfo and tTableInfo.nKeepTime == -1 then
        --永久牌桌
        local sTableName = tTableInfo.sTableName or "NoName"
        local sSql = string.format("call Club_WriteTableRecordHall(%d,'%s','%s',%d,%d,%d,%d,%d)",
            tData.nClubId,sTableName,tData.sTableInfo,tTableInfo.nKeepTime,nType,tData.nLiveUserID,tData.nGameId,tData.nGroupId)
        tBase.Log("OnClubWriteTableRecordHallReq sSql:%s",sSql)
        local arrRows = RecordDB_SqlExecute(sSql)
    end
end

-- 牌谱请求 请求
function ClubSink.OnClubPaiPuReq(sReturnKey,Data,nLen)
    local strReq ="ClubPaiPuReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetPaiPu(%d,%d,%d,%d,%d)",tData.nType,tData.nIdOfStart,tData.nCnt,tData.nUserId,tData.nGameId)
    tBase.Log("OnClubPaiPuReq sSql:%s",sSql)
    local arrRows = RecordDB_SqlExecute(sSql,true)
    local arrRecords = {}
    local nAllCnt = 0
    for _,row in pairs(arrRows) do
        local tHandCards,tTableInfo = {},{}
        local isSuccee1,tUsersInfo = pcall(cjson.decode,row.UsersInfo)
        if not isSuccee1 then
            tUsersInfo = {}
            Base.Log("_OnClubPaiPuReq decode UsersInfo fail PaiJuId_%s",row.PaiJuId or "")
        end
        local isSuccee2,tDealCardInfo = pcall(cjson.decode,row.DealCardInfo)
        if not isSuccee2 then
            tDealCardInfo = {}
            Base.Log("_OnClubPaiPuReq decode DealCardInfo fail PaiJuId_%s",row.PaiJuId or "")
        end
        local isSuccee3,tElseInfo = pcall(cjson.decode,row.ElseInfo)
        if not isSuccee3 then
            tElseInfo = {}
            Base.Log("_OnClubPaiPuReq decode ElseInfo fail PaiJuId_%s",row.PaiJuId or "")
        end
        --手牌信息
        local nSitId = -1
        for _,tUserInfo in pairs(tUsersInfo) do
            if tUserInfo.nUserId==tData.nUserId then
                nSitId = tUserInfo.nSitId
                break
            end
        end
        for _,tCardInfo in pairs(tDealCardInfo) do
            if tCardInfo.nSitId==nSitId or tCardInfo.nUserId==tData.nUserId then
                tHandCards.nCardType = tCardInfo.nCardType
                tHandCards.arrCard = tCardInfo.arrCard
                break
            end
        end
        --牌桌配置信息
        tTableInfo = tElseInfo.tTableInfo or {}
        tTableInfo.nPool = 0 --总底池
        for _,nPool in pairs(tElseInfo.arrPool or {}) do
            tTableInfo.nPool = tTableInfo.nPool + nPool
        end


        local tClubPaiJuRecordItem = {}
        tClubPaiJuRecordItem.nId = tonumber(row.id) or 0
        tClubPaiJuRecordItem.sPaiJuID = row.PaiJuId or ""
        tClubPaiJuRecordItem.nWinLose = tonumber(row.WinLose) or 0
        tClubPaiJuRecordItem.nGameId = tonumber(row.GameType) or 0
        tClubPaiJuRecordItem.sTime = row.CreateTime or ""
        tClubPaiJuRecordItem.sTableInfo = cjson.encode(tTableInfo)
        tClubPaiJuRecordItem.sHandCards = cjson.encode(tHandCards)
        tClubPaiJuRecordItem.nClubId = tonumber(row.ClubId) or 0
        tClubPaiJuRecordItem.nCollect = tonumber(row.nCollect) or 0
        table.insert(arrRecords,tClubPaiJuRecordItem)
        nAllCnt = tonumber(row.nAllCnt) or 0
    end

    local ClubPaiPuResp = {}
    ClubPaiPuResp.arrRecords = arrRecords
    ClubPaiPuResp.nType = tData.nType
    ClubPaiPuResp.nAllCnt = nAllCnt
    ClubPaiPuResp.nUserId = tData.nUserId
    ClubPaiPuResp.nSendUserId = tData.nSendUserId
    ClubPaiPuResp.nGameId = tData.nGameId
    DbClubSendToServer(sReturnKey,"ClubPaiPuResp",ClubPaiPuResp)
end

-- 操作牌谱请求 请求
function ClubSink.OnClubOpratePaiPuReq(sReturnKey,Data,nLen)
    local strReq ="ClubOpratePaiPuReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_PaiPuOprate(%d,'%s',%d)",tData.nType,tData.sPaiJuID,tData.nUserId)
    tBase.Log("OnClubOpratePaiPuReq sSql:%s",sSql)
    local arrRows = RecordDB_SqlExecute(sSql)
    local row = arrRows[1]

    local nRlt = row and tonumber(row.ErrCode) or 99

    local ClubOpratePaiPuResp = {}
    ClubOpratePaiPuResp.nRlt = nRlt
    ClubOpratePaiPuResp.nType = tData.nType
    ClubOpratePaiPuResp.sPaiJuID = tData.sPaiJuID
    ClubOpratePaiPuResp.nUserId = tData.nUserId
    DbClubSendToServer(sReturnKey,"ClubOpratePaiPuResp",ClubOpratePaiPuResp)
end

-- 玩家个人通知 请求
function ClubSink.OnClubUserNoticeReq(sReturnKey,Data,nLen)
    local strReq ="ClubUserNoticeReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrNotices = {}
    local nAllCnt = 0
    local arrApplyList = {}
    local nUnReadCnt = nil

    if tData.nType==1 then
        local sSql = string.format("call Club_GetUserNotices(%d,%d,%d,%d)",tData.nIdOfStart,tData.nCnt,tData.nUserId,tData.nType)
        tBase.Log("OnClubUserNoticeReq sSql:%s",sSql)
        local tType ={}
        local arrRows = RecordDB_SqlExecute(sSql,true)
        for _,row in pairs(arrRows) do
            local tNoticesItem = {}
            tNoticesItem.nId = tonumber(row.id) or 0
            tNoticesItem.nType = tonumber(row.nType) or 0
            tNoticesItem.nStatus = tonumber(row.nStatus) or 0
            tNoticesItem.sTime = row.CreateTime or ""
            tNoticesItem.sData = row.sData or ""
            tNoticesItem.nUserId = tonumber(row.UserId) or 0
            tNoticesItem.nHadRead = tonumber(row.HasRead) or 0
            table.insert(arrNotices,tNoticesItem)
            nAllCnt = tonumber(row.nAllCnt) or 0
            tType[tNoticesItem.nType]=true
        end

        --设置已读
        for nType,_ in pairs(tType) do
            local sSql2 = string.format("call Club_SetUserNoticesRead(%d,%d,%d,%d)",tData.nIdOfStart,tData.nCnt,tData.nUserId,nType)
            tBase.Log("OnClubUserNoticeReq sSql2:%s",sSql2)
            local arrRows2 = RecordDB_SqlExecute(sSql2)
            local row2 = arrRows2[1]
            if row2 then
                nUnReadCnt =nUnReadCnt or 0
                nUnReadCnt = nUnReadCnt +tonumber(row2.nUnReadCnt)
            end
        end
    elseif tData.nType==2 then
        local sSql = string.format("call Club_GetUserInvitation(%d,%d,%d)",tData.nIdOfStart,tData.nCnt,tData.nUserId)
        tBase.Log("OnClubUserNoticeReq sSql:%s",sSql)
        local arrRows = RecordDB_SqlExecute(sSql,true)
        for _,row in pairs(arrRows) do
            local tExtData = {}
            tExtData.nMaster = tonumber(row.MasterId)
            tExtData.sClubName = row.ClubName
            tExtData.nClubId = tonumber(row.ClubId)
            tExtData.sFaceId = row.FaceID
            tExtData.sUserName = row.NickName
            tExtData.nUserId = tonumber(row.Invitee)

            local tNoticesItem = {}
            tNoticesItem.nId = tonumber(row.id) or 0
            tNoticesItem.nType = tData.nType
            tNoticesItem.nStatus = tonumber(row.nStatus) or 0
            tNoticesItem.sTime = row.CreateTime or ""
            tNoticesItem.sData = cjson.encode(tExtData)
            tNoticesItem.nUserId = tonumber(row.UserId) or 0
            table.insert(arrNotices,tNoticesItem)
            nAllCnt = tonumber(row.nAllCnt) or 0
        end
    elseif tData.nType==3 then
        local sSql = string.format("call Club_GetUserApplyList(%d,%d,%d)",tData.nIdOfStart,tData.nCnt,tData.nUserId)
        tBase.Log("OnClubUserNoticeReq sSql:%s",sSql)
        local arrRows = RecordDB_SqlExecute(sSql,true)
        for _,row in pairs(arrRows) do
            local tApplyInfo = {}
            tApplyInfo.nId = tonumber(row.id) or 0
            tApplyInfo.nClubId = tonumber(row.ClubId) or 0
            tApplyInfo.nType = 3
            tApplyInfo.sTime = row.CreateTime or ""
            tApplyInfo.sClubName = row.ClubName or ""
            tApplyInfo.nStatus = tonumber(row.nStatus) or 0
            table.insert(arrApplyList,tApplyInfo)
            nAllCnt = tonumber(row.nAllCnt) or 0
        end
    end

    local ClubUserNoticeRsp = {}
    ClubUserNoticeRsp.arrNotices = arrNotices
    ClubUserNoticeRsp.nAllCnt = nAllCnt
    ClubUserNoticeRsp.nUserId = tData.nUserId
    ClubUserNoticeRsp.nType = tData.nType
    ClubUserNoticeRsp.arrApplyList = arrApplyList
    ClubUserNoticeRsp.nUnReadCnt = nUnReadCnt
    DbClubSendToServer(sReturnKey,"ClubUserNoticeRsp",ClubUserNoticeRsp)
end

-- 处理个人通知请求 请求
function ClubSink.OnClubUserNoticeHandleReq(sReturnKey,Data,nLen)
    local strReq ="ClubUserNoticeHandleReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local tExtData = cjson.decode(tData.sExData)
    local nRlt = 0

    if tExtData.nType==2 then
        local sSql = string.format("call Club_HandleInvitation(%d,%d)",tData.nId,tData.nOpType)
        tBase.Log("OnClubUserNoticeHandleReq sSql:%s",sSql)
        RecordDB_SqlExecute(sSql)

        if tExtData.nType==2 and tData.nOpType==1 then
            --同意受邀请加入俱乐部
            --加入俱乐部
            local sSql1 = string.format("call Club_AgreeInviteToJoinInClub(%d,%d,%d)",tExtData.nClubId,tData.nUserId,tExtData.nMaxUserCnt)
            tBase.Log("OnClubUserNoticeHandleReq sSql1:%s",sSql1)
            local arrRows1 = AccountsDB_SqlExecute(sSql1)
            local row = arrRows1[1]
            nRlt = tonumber(row.ErrCode) or 99
            tExtData.nUserCnt = tonumber(row.nMembers) or 0 --俱乐部总人数
            tExtData.nMaster = tonumber(row.nMaster) or 0 --主席id
            tExtData.sClubName = row.sClubName or "" --俱乐部名字

            --把新加入的玩家信息写入redis
            tPublicRedis.SetClubUserInfo(tExtData.nClubId,{{nUserId=tData.nUserId,nIdentify=20,sPower=GetUserPower({})}})
        end
    end

    local ClubUserNoticeHandleRsp = {}
    ClubUserNoticeHandleRsp.nRlt = nRlt
    ClubUserNoticeHandleRsp.nUserId = tData.nUserId
    ClubUserNoticeHandleRsp.sExData = cjson.encode(tExtData)
    DbClubSendToServer(sReturnKey,"ClubUserNoticeHandleRsp",ClubUserNoticeHandleRsp)
end

-- 获取某条个人通知信息 请求
function ClubSink.OnClubGetUserNoticeInfoReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetUserNoticeInfoReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local tExData = cjson.decode(tData.sExtData)
    local tNoticesInfo = nil
    if tExData.nType==2 then
        local sSql = string.format("call Club_GetInvitationInfo(%d)",tData.nId)
        tBase.Log("OnClubGetUserNoticeInfoReq sSql:%s",sSql)
        local arrRows = RecordDB_SqlExecute(sSql,true)
        local row = arrRows[1]
        if row and tonumber(row.id) then
            local tExtData = {}
            tExtData.nMaster = tonumber(row.MasterId)
            tExtData.sClubName = row.ClubName
            tExtData.nClubId = tonumber(row.ClubId)
            tExtData.sFaceId = row.FaceID
            tExtData.sUserName = row.NickName
            tExtData.nUserId = tonumber(row.Invitee)

            tNoticesInfo = {}
            tNoticesInfo.nId = tonumber(row.id) or 0
            tNoticesInfo.nType = tExData.nType
            tNoticesInfo.nStatus = tonumber(row.nStatus) or 0
            tNoticesInfo.sTime = row.CreateTime or ""
            tNoticesInfo.sData = cjson.encode(tExtData)
            tNoticesInfo.nUserId = tonumber(row.UserId) or 0
        end
    end

    local ClubGetUserNoticeInfoRsp = {}
    ClubGetUserNoticeInfoRsp.nId = tData.nId
    ClubGetUserNoticeInfoRsp.sExtData = tData.sExtData
    ClubGetUserNoticeInfoRsp.tNoticesInfo = tNoticesInfo
    DbClubSendToServer(sReturnKey,"ClubGetUserNoticeInfoRsp",ClubGetUserNoticeInfoRsp)
end

-- 申请失效处理请求 请求
function ClubSink.OnClubApplyInvalidReq(sReturnKey,Data,nLen)
    local strReq ="ClubApplyInvalidReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_HandleOverTimeApply(%d)",tData.nClubId)
    tBase.Log("OnClubApplyInvalidReq sSql:%s",sSql)
    local arrRows = RecordDB_SqlExecute(sSql)
    local row = arrRows[1]
    if tonumber(row.ErrCode)==0 then
        local ClubApplyInvalidRsp = {}
        ClubApplyInvalidRsp.nClubId = tData.nClubId
        ClubApplyInvalidRsp.nApplyJionCnt = tonumber(row.nApplyJionCnt) or 0 --加入申请数量
        ClubApplyInvalidRsp.nApplyAddGoldCnt = tonumber(row.nApplyAddGoldCnt) or 0 --俱乐部币申请数量
        ClubApplyInvalidRsp.nApplyCutGoldCnt = tonumber(row.nApplyCutGoldCnt) or 0 --退还俱乐部币申请数量
        DbClubSendToServer(sReturnKey,"ClubApplyInvalidRsp",ClubApplyInvalidRsp)
    else
        tBase.Log("OnClubApplyInvalidReq ErrorCode:%s ErrorInfo:%s",row.ErrCode,row.ErrorInfo or "")
    end
end

-- 玩家俱乐部币申请（玩家个人） 请求
function ClubSink.OnClubGetApplyListReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetApplyListReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrApplyList = {}
    local nAllCnt = 0

    local sSql = string.format("call Club_GetUserClubGoldApplyList(%d,%d,%d,%d)",tData.nIdOfStart,tData.nCnt,tData.nUserId,tData.nClubId)
    tBase.Log("OnClubGetApplyListReq sSql:%s",sSql)
    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local tApplyInfo = {}
            tApplyInfo.nId = tonumber(row.id) or 0
            tApplyInfo.nClubId = tonumber(row.ClubId) or 0
            tApplyInfo.nType = tonumber(row.nType) or 0
            tApplyInfo.sTime = row.CreateTime or ""
            tApplyInfo.sClubName = row.ClubName or ""
            tApplyInfo.nStatus = tonumber(row.nStatus) or 0
            tApplyInfo.nChange = tonumber(row.nChange) or 0
            table.insert(arrApplyList,tApplyInfo)
            nAllCnt = tonumber(row.nAllCnt) or 0
    end

    local ClubGetApplyListRsp = {}
    ClubGetApplyListRsp.arrApplyList = arrApplyList
    ClubGetApplyListRsp.nType = tData.nType
    ClubGetApplyListRsp.nAllCnt = nAllCnt
    ClubGetApplyListRsp.nUserId = tData.nUserId
    ClubGetApplyListRsp.nClubId = tData.nClubId
    DbClubSendToServer(sReturnKey,"ClubGetApplyListRsp",ClubGetApplyListRsp)
end

-- 玩家申请处理 请求
function ClubSink.OnClubUserApplyOpReq(sReturnKey,Data,nLen)
    local strReq ="ClubUserApplyOpReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local tExData = {}
    local nRlt = {}

    if tData.nType==1 or tData.nType==2 or tData.nType==3 then
        local sSql = string.format("call Club_RecallUserApply(%d,%d,%d,%d)",tData.nId,tData.nUserId,tData.nOpType,tData.nType)
        tBase.Log("OnClubUserApplyOpReq sSql:%s",sSql)
        local arrRows = RecordDB_SqlExecute(sSql)
        local row = arrRows[1]
        nRlt = tonumber(row.ErrCode) or 99
        if nRlt==0 then
            tExData.nClubId = tonumber(row.nClubId) or 0
            tExData.nApplyCnt = tonumber(row.nApplyCnt) or 0
        end
    else
        nRlt = 1
    end
    
    local ClubUserApplyOpRsp = {}
    ClubUserApplyOpRsp.nRlt = nRlt
    ClubUserApplyOpRsp.nId = tData.nId
    ClubUserApplyOpRsp.nOpType = tData.nOpType
    ClubUserApplyOpRsp.nUserId = tData.nUserId
    ClubUserApplyOpRsp.nType = tData.nType
    ClubUserApplyOpRsp.sExData = cjson.encode(tExData)
    DbClubSendToServer(sReturnKey,"ClubUserApplyOpRsp",ClubUserApplyOpRsp)
end

-- 玩家个人信息 请求
function ClubSink.OnClubUserInfoReq(sReturnKey,Data,nLen)
    local strReq ="ClubUserInfoReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local tUserInfo = nil
    local nRlt = 99

    local sSql = string.format("call Club_GetUserPublicInfo(%d)",tData.nUserId)
    tBase.Log("OnClubUserInfoReq sSql:%s",sSql)
    local arrRows = AccountsDB_SqlExecute(sSql,true)
    local row = arrRows[1] or {}
    local UserID = tonumber(row.UserID) or 0
    if UserID>0 then
        nRlt = 0
        tUserInfo = {}
        tUserInfo.nUserId = UserID
        tUserInfo.sFaceId = row.FaceID or "1"
        tUserInfo.sName = row.NickName or ""
        tUserInfo.nSex = tonumber(row.Sex) or 0
        tUserInfo.nGold = tonumber(row.Gold) or 0
        tUserInfo.sTime = row.RegisTime or ""
        tUserInfo.sPhone = row.Bin_Ding_PHone or ""
        tUserInfo.nAllCount = tonumber(row.nCount) or 0
        tUserInfo.nMaxProfit = tonumber(row.MaxProfit) or 0
        tUserInfo.sPersonality = row.Personality or ""
        tUserInfo.nHandCount = tonumber(row.PaiJuCnt) or 0
        tUserInfo.nMaxHandProfit = tonumber(row.MaxPaiJuProfit) or 0
        tUserInfo.nVip = tonumber(row.Vip) or 0
        tUserInfo.nExp = tonumber(row.Exp) or 0
        tUserInfo.nGloryLevel = tonumber(row.GloryLevel) or 0
        tUserInfo.nLevelStart = tonumber(row.LevelStart) or 0
        local SafePassWord = row.SafePassWord or ""
        local nOpenProtection = tonumber(row.OpenSafe)
        if not nOpenProtection or nOpenProtection==-1 then
            nOpenProtection = 0
        end
        if #SafePassWord > 1 then  -- 密码已经设置
           nOpenProtection = 1
        end
        tBase.Log("OnClubUserInfoReq #SafePassWord:%d", #SafePassWord)
        tUserInfo.nOpenProtection = nOpenProtection
        tUserInfo.nReviewedGold = tonumber(row.ReviewedGold) or 0
        tUserInfo.sMail =row.Mail
    else
        --玩家不存在
        nRlt = 2
    end
    
    local ClubUserInfoRsp = {}
    ClubUserInfoRsp.nRlt = nRlt
    ClubUserInfoRsp.tUserInfo = tUserInfo
    ClubUserInfoRsp.nSendUserId = tData.nSendUserId
    DbClubSendToServer(sReturnKey,"ClubUserInfoRsp",ClubUserInfoRsp)
end

--修改玩家个人信息 请求
function ClubSink.OnClubChangeUserInfoReq(sReturnKey,Data,nLen)
    local strReq ="ClubChangeUserInfoReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local ClubChangeUserInfoRsp = {}
    ClubChangeUserInfoRsp.nUserId = tData.nUserId
    ClubChangeUserInfoRsp.arrRlt = {}

    local arrItem =tData.arrChange
    local sFaceId = "nil"
    local sName = "nil"
    local sPhone = "nil"
    local nSex = -1
    local sPersonality = "nil"
    local sSafePassWard = "nil"

    for k,v in pairs(arrItem) do
        if v.sKey == "sFaceId" then
            sFaceId = v.sVal
        end
    
        if v.sKey == "nSex" then
            nSex = tonumber(v.sVal) or 0
        end
    
        if v.sKey == "sName" then
            sName = v.sVal
        end

        if v.sKey == "sPhone" then
            sPhone = v.sVal
        end

        if v.sKey == "sPersonality" then
            sPersonality = v.sVal
        end

        if v.sKey == "sSafePassWard" then
            sSafePassWard = v.sVal
        end
    end
    local sSql = string.format("call Club_ChangeUserInfo(%d,'%s','%s','%s',%d,'%s','%s')",tData.nUserId,sFaceId,sName,sPhone,nSex,sPersonality,sSafePassWard)
    tBase.Log("OnClubChangeUserInfoReq sSql:%s",sSql)
    local arrRows =AccountsDB_SqlExecute(sSql)
    local row = arrRows[1]
    local nRlt = tonumber(row.ErrCode) or 99
    if nRlt == 0 then
        if tonumber(row.IsChangeName)==1 then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=0,sKey="sName",sVal=sName})
        end
        if tonumber(row.IsChangeFace)==1 then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=0,sKey="sFaceId",sVal=sFaceId})
        end
        if tonumber(row.IsChangeSex)==1 then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=0,sKey="nSex",sVal=tostring(nSex)})
        end
        if tonumber(row.IsChangePhone)==1 then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=0,sKey="sPhone",sVal=sPhone})
        end
        if tonumber(row.IsChangePersonality)==1 then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=0,sKey="sPersonality",sVal=sPersonality})
        end
        if tonumber(row.IsChangeSafePassWard)==1 then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=0,sKey="sSafePassWard",sVal=sSafePassWard})
        end
        if tonumber(row.IsSetSafePassWard)==1 then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=0,sKey="nOpenProtection",sVal="1"})
        end
    elseif nRlt==1 then
        --名字被占用
        table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=2,sKey="sName"})
    elseif nRlt==2 then
        --头像新旧值相同
        table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=4,sKey="sFaceId"})
    elseif nRlt==3 then
        --名字新旧值相同
        table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=4,sKey="sName"})
    elseif nRlt==4 then
        --性别新旧值相同
        table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=4,sKey="nSex"})
    elseif nRlt==5 then
        --电话新旧值相同
        table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=4,sKey="sPhone"})
    elseif nRlt==6 then
        --个性签名新旧值相同
        table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=4,sKey="sPersonality"})
    elseif nRlt==7 then
        --安全密码新旧值相同
        table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=4,sKey="sSafePassWard"})
    else
        if sFaceId~="nil" then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=99,sKey="sFaceId"})
        end
        if nSex~=-1 then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=99,sKey="nSex"})
        end
        if sName~=-1 then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=99,sKey="sName"})
        end
        if sPhone~="nil" then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=99,sKey="sPhone"})
        end
        if sPersonality~="nil" then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=99,sKey="sPersonality"})
        end
        if sSafePassWard~="nil" then
            table.insert(ClubChangeUserInfoRsp.arrRlt,{nRlt=99,sKey="sSafePassWard"})
        end
    end
    DbClubSendToServer(sReturnKey,"ClubChangeUserInfoRsp",ClubChangeUserInfoRsp)  
end

--修改登录密码 请求
function ClubSink.OnClubChangeLoginPassWardReq(sReturnKey,Data,nLen)
    local strReq ="ClubChangeLoginPassWardReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    
    local sSql = string.format("call Club_ChangeLoginPassWard(%d,'%s','%s')",tData.nUserId,tData.sOldPassWord,tData.sNewPassWord)
    tBase.Log("OnClubChangeLoginPassWardReq sSql:%s",sSql)
    local arrRows =AccountsDB_SqlExecute(sSql)
    local row = arrRows[1]
    local nRlt = tonumber(row.ErrCode) or 99

    local ClubChangeLoginPassWardRsp = {}
    ClubChangeLoginPassWardRsp.nUserId = tData.nUserId
    ClubChangeLoginPassWardRsp.nRlt = nRlt
    DbClubSendToServer(sReturnKey,"ClubChangeLoginPassWardRsp",ClubChangeLoginPassWardRsp)  
end

--回放数据请求 请求
function ClubSink.OnClubPlaybackDataReq(sReturnKey,Data,nLen)
    local strReq ="ClubPlaybackDataReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    
    local sSql = string.format("call Club_GetPlaybackData('%s')",tData.sPaiJuID)
    tBase.Log("OnClubPlaybackDataReq sSql:%s",sSql)
    local arrRows =RecordDB_SqlExecute(sSql,true)
    local row = arrRows[1]
    local nRlt = 1
    local sJson = nil
    local nGameId = nil
    local sTime = nil
    if row and tonumber(row.id) and tonumber(row.id)>0 then
        nRlt = 0
        sJson = row.PlayBackData
        nGameId = tonumber(row.GameId) or 0
        sTime = row.CreateTime
        local LookData = row.LookData
        if #LookData > 2 then  -- 默认'[]'不处理
            local jData = cjson.decode(LookData)
            local jBack = cjson.decode(sJson)
            jBack.lookData = jData
            sJson = cjson.encode(jBack)
        end
    end
    row =row or {}

    local ClubPlaybackDataRsp = {}
    ClubPlaybackDataRsp.nUserId = tData.nUserId
    ClubPlaybackDataRsp.nRlt = nRlt
    ClubPlaybackDataRsp.sPaiJuID = tData.sPaiJuID
    ClubPlaybackDataRsp.nGameId = nGameId
    ClubPlaybackDataRsp.sJson = sJson
    ClubPlaybackDataRsp.sTime = sTime
    ClubPlaybackDataRsp.sTableName =row.TableName
    DbClubSendToServer(sReturnKey,"ClubPlaybackDataRsp",ClubPlaybackDataRsp)  
end

--写入回放数 请求
function ClubSink.OnClubWritePlaybackDataReq(sReturnKey,Data,nLen)
    local strReq ="ClubWritePlaybackDataReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    
    tBase.Log("OnClubWritePlaybackDataReq %s",string.sub(tData.sSql,1,math.min(100,#tData.sSql)))
    local arrRows =RecordDB_SqlExecute(tData.sSql)
end

--更新回放数 请求
function ClubSink.OnCluUpdatePlaybackDataReq(sReturnKey,Data,nLen)
    local strReq ="CluUpdatePlaybackDataReq"
    local tData =DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sql = string.format("call Club_UpdatePlayBackData(%d,%d,'%s')", tData.nUserId, tData.nType, tData.sPaiJuID)
    tBase.Log("OnCluUpdatePlaybackDataReq %s",sql)
    local arrRows =RecordDB_SqlExecute(sql)
end

--玩家红点数据 请求
function ClubSink.OnClubUserRedDotReq(sReturnKey,Data,nLen)
    local strReq ="ClubUserRedDotReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    
    local connection =dbSink.GetDbConnectForRead("DJH_RecordDB")
    local sTimeZone,nGroupId =SetTimeZone(connection,tData.nUserId)  --设置使用的时区
   
    local sSql = string.format("call Club_GetUserRedot(%d)",tData.nUserId)
    tBase.Log("OnClubUserRedDotReq sSql:%s",sSql)
    local arrRows =SqlExecut(sSql,connection)
    local row = arrRows[1]
    local arrRedot = {}
    if row then
        local nApplyCnt = tonumber(row.nApplyCnt) or 0
        table.insert(arrRedot,{nType=1,nCount=nApplyCnt})

        local nInviteCnt = tonumber(row.nInviteCnt) or 0
        table.insert(arrRedot,{nType=2,nCount=nInviteCnt})

        local nUnReadCnt = tonumber(row.nUnReadCnt) or 0
        table.insert(arrRedot,{nType=3,nCount=nUnReadCnt})

        local nUnclaimedCnt = tonumber(row.nUnclaimedCnt) or 0
        table.insert(arrRedot,{nType=4,nCount=nUnclaimedCnt})
    end

    local ClubUserRedDotRsp = {}
    ClubUserRedDotRsp.arrRedot = arrRedot
    ClubUserRedDotRsp.nUserId = tData.nUserId
    DbClubSendToServer(sReturnKey,"ClubUserRedDotRsp",ClubUserRedDotRsp)  
end

--获取牌桌的牌局id 请求
function ClubSink.OnClubGetTablePaiJuIdReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetTablePaiJuIdReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = string.format("call Club_GetTablePaiJuId('%s')",tData.sTableId)
    tBase.Log("OnClubGetTablePaiJuIdReq sSql:%s",sSql)
    local arrRows =RecordDB_SqlExecute(sSql,true)
    local nCnt = tData.nCnt or 30
    local nPage = tData.nPage or 0
    if nPage == 0 then
        nPage = 1
    end
    if nCnt == 0 then
        nCnt = 30
    end
    local arrPaiJuID = {}
    local nGameId = 0
    local nAllCnt = 0
    for _,row in pairs(arrRows) do
        nGameId = tonumber(row.GameId) or 0
        nAllCnt = tonumber(row.nAllCnt) or 0
        local nId = tonumber(row.id) or 0
        local sPaiJuID = row.PaiJuId or ""
        table.insert(arrPaiJuID,{nId=nId,sPaiJuID=sPaiJuID})
    end

    table.sort(arrPaiJuID,function (a, b)
        return a.nId > b.nId
    end)
    local nAllPage = math.ceil(nAllCnt / nCnt)
    nPage = math.max(1, math.min(nPage, nAllPage))
    local nStartIndex = (nPage - 1) * nCnt + 1
    local nEndIndex = math.min(nPage * nCnt, nAllCnt)
    -- 提取当前页的数据
    local arrCurrentPage = {}
    for i = nStartIndex, nEndIndex do
        if arrPaiJuID[i] then
            table.insert(arrCurrentPage, arrPaiJuID[i])
        end
    end
    local ClubGetTablePaiJuIdResp = {}
    ClubGetTablePaiJuIdResp.arrPaiJuID = arrCurrentPage  -- 只返回当前页的数据
    ClubGetTablePaiJuIdResp.nUserId = tData.nUserId
    ClubGetTablePaiJuIdResp.sTableId = tData.sTableId
    ClubGetTablePaiJuIdResp.nGameId = nGameId
    ClubGetTablePaiJuIdResp.nAllCnt = nAllCnt
    ClubGetTablePaiJuIdResp.nNowPage = nPage  -- 当前页码
    ClubGetTablePaiJuIdResp.nAllPage = nAllPage  -- 总页数
    DbClubSendToServer(sReturnKey,"ClubGetTablePaiJuIdResp",ClubGetTablePaiJuIdResp)
end

--设置安全密码开启关闭 请求
function ClubSink.OnClubSetSafePassWardOpenReq(sReturnKey,Data,nLen)
    local strReq ="ClubSetSafePassWardOpenReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end    
    local sSql = string.format("call Club_SetSafePassWardOpen(%d,%d)",tData.nUserId,tData.nOpen)
    tBase.Log("OnClubSetSafePassWardOpenReq sSql:%s",sSql)
    local arrRows =AccountsDB_SqlExecute(sSql)
    local nRlt = 99
    local isNeedSet = nil
    local row = arrRows[1]
    if row then
        nRlt = tonumber(row.ErrCode) or 99
        if tData.nOpen==1 and tonumber(row.IsNeedSet)==1 then
            isNeedSet = true
        end
    end
    local ClubSetSafePassWardOpenRsp = {}
    ClubSetSafePassWardOpenRsp.nRlt = nRlt
    ClubSetSafePassWardOpenRsp.nUserId = tData.nUserId
    ClubSetSafePassWardOpenRsp.isNeedSet = isNeedSet
    ClubSetSafePassWardOpenRsp.nOpen = tData.nOpen
    DbClubSendToServer(sReturnKey,"ClubSetSafePassWardOpenRsp",ClubSetSafePassWardOpenRsp)
end

--获取玩家个人牌桌记录 请求
function ClubSink.OnClubGetPersonTableRecordReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetPersonTableRecordReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrRecords = {}
    local tStatics = nil

    local sSql = string.format("call Club_GetPersonTableRecord(%d,%d,%d,%d,%d,%d)",tData.nUserId,tData.nGameId,tData.nIdOfStart,tData.nCnt,tData.nGoldType,tData.nClubId)
    tBase.Log("OnClubGetPersonTableRecordReq sSql:%s",sSql)
    local arrRows =RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local tRecord = {}
        tRecord.nId = tonumber(row.id) or 0
        tRecord.nWinLose = tonumber(row.WinLose) or 0
        tRecord.nLiveUserID = tonumber(row.LiveUserId) or 0
        tRecord.sTableInfo = row.TableInfo or ""
        tRecord.sFaceId = row.FaceId or ""
        tRecord.sTime = row.UpdateTime or ""
        tRecord.sTableId = row.TableId or ""
        table.insert(arrRecords,tRecord)
    end

    if tData.nIdOfStart==0 then
        if tApi.IsTexasClassGame(tData.nGameId) then --德州，奥马哈，短牌
            local sSql1 = string.format("call Club_GetTexaStatistic(%d,%d,%d,%d)",tData.nUserId,tData.nGameId,tData.nGoldType,tData.nClubId)
            tBase.Log("OnClubGetPersonTableRecordReq sSql1:%s",sSql1)
            local arrRows1 =RecordDB_SqlExecute(sSql1,true)
            local row1 = arrRows1[1]
            if row1 then
                tStatics ={}
                tStatics.nPaiJuCnt=tonumber(row1.PaiJuCnt) or 0
                tStatics.nPlayCount=tonumber(row1.PlayCount) or 0
                tStatics.nProfitSum=tonumber(row1.ProfitSum)  or 0
                tStatics.nInPoolCount=tonumber(row1.InPoolCount)  or 0
                tStatics.nRaiseCountBFlop=tonumber(row1.RaiseCountBFlop) or 0
                tStatics.nAllInAndWinCount=tonumber(row1.AllInAndWinCount) or 0
            end
        end
    end

    local ClubGetPersonTableRecordRsp = {}
    ClubGetPersonTableRecordRsp.arrRecords = arrRecords
    ClubGetPersonTableRecordRsp.tStatics = tStatics
    ClubGetPersonTableRecordRsp.nGameId = tData.nGameId
    ClubGetPersonTableRecordRsp.nUserId = tData.nUserId
    ClubGetPersonTableRecordRsp.nClubId = tData.nClubId
    ClubGetPersonTableRecordRsp.nGoldType = tData.nGoldType
    ClubGetPersonTableRecordRsp.nIdOfStart = tData.nIdOfStart
    DbClubSendToServer(sReturnKey,"ClubGetPersonTableRecordRsp",ClubGetPersonTableRecordRsp)
end

--获取玩家个人牌桌记录2 请求(大厅永久牌桌)
function ClubSink.OnClubGetPersonTableRecord2Req(sReturnKey,Data,nLen)
    local strReq ="ClubGetPersonTableRecord2Req"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrRecords = {}
    local tStatics = nil

    local nGroupId =tPubUsrApi.Get_User_GroupId(tData.nUserId)
    local sSql = string.format("call Club_GetPersonTableRecordHall(%d,%d,%d,%d,%d,%d,%d,%d)",
        tData.nUserId,tData.nGameId,tData.nIdOfStart,tData.nCnt,tData.nGoldType,tData.nClubId,tData.nDay,nGroupId)
    tBase.Log("OnClubGetPersonTableRecord2Req sSql:%s",sSql)
    local arrRows =RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local tRecord = {}
        tRecord.nId = tonumber(row.id) or 0
        tRecord.nWinLose = tonumber(row.WinLose) or 0
        tRecord.nLiveUserID = tonumber(row.LiveUserId) or 0
        tRecord.sTableInfo = row.TableInfo or ""
        tRecord.sFaceId = row.FaceId or ""
        tRecord.sTime = row.UpdateTime or ""
        tRecord.sTableId = row.TableId or ""
        tRecord.nTableIndex =tonumber(row.TableTimeStep) or 0
        table.insert(arrRecords,tRecord)
    end

    if tData.nIdOfStart==0 then
        local sSql1 = string.format("call Club_GetHallStatistic(%d,%d,%d,%d,%d)",tData.nUserId,tData.nGameId,tData.nGoldType,tData.nClubId,tData.nDay)
        tBase.Log("OnClubGetPersonTableRecord2Req sSql1:%s",sSql1)
        local arrRows1 =RecordDB_SqlExecute(sSql1,true)
        local row1 = arrRows1[1]
        if row1 then
            tStatics ={}
            tStatics.nPaiJuCnt=tonumber(row1.PaiJuCnt) or 0
            tStatics.nPlayCount=tonumber(row1.PlayCount) or 0
            tStatics.nProfitSum=tonumber(row1.ProfitSum)  or 0
            tStatics.nInPoolCount=tonumber(row1.InPoolCount)  or 0
            tStatics.nRaiseCountBFlop= 0
            tStatics.nAllInAndWinCount= 0
        end
    end

    local ClubGetPersonTableRecord2Rsp = {}
    ClubGetPersonTableRecord2Rsp.arrRecords = arrRecords
    ClubGetPersonTableRecord2Rsp.tStatics = tStatics
    ClubGetPersonTableRecord2Rsp.nGameId = tData.nGameId
    ClubGetPersonTableRecord2Rsp.nUserId = tData.nUserId
    ClubGetPersonTableRecord2Rsp.nClubId = tData.nClubId
    ClubGetPersonTableRecord2Rsp.nGoldType = tData.nGoldType
    ClubGetPersonTableRecord2Rsp.nIdOfStart = tData.nIdOfStart
    ClubGetPersonTableRecord2Rsp.nDay = tData.nDay
    DbClubSendToServer(sReturnKey,"ClubGetPersonTableRecord2Rsp",ClubGetPersonTableRecord2Rsp)
end

--获取玩家个人牌桌记录2 请求(大厅普通桌)
function ClubSink.OnClubGetPersonTableRecord2Req_Normal(sReturnKey,Data,nLen)
    local strReq ="ClubGetPersonTableRecord2Req"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrRecords = {}
    local tStatics = nil

    local nGroupId =tPubUsrApi.Get_User_GroupId(tData.nUserId)
    local sSql = string.format("call Club_GetPersonTableRecordHallv4(%d,%d,%d,%d,%d,%d,%d,%d,'%s','%s')",
        tData.nUserId,tData.nGameId,tData.nIdOfStart,tData.nCnt,tData.nGoldType,tData.nClubId,tData.nDay,nGroupId,tData.nStartTime,tData.nEndTime)
    tBase.Log("OnClubGetPersonTableRecord2Req sSql:%s",sSql)
    local arrRows =RecordDB_SqlExecute(sSql,true)
    -- tBase.Log("GetPersonTableRecordHallv2Result userId=%d gameId=%d day=%d result={%s}",tData.nUserId,tData.nGameId,tData.nDay,cjson.encode(arrRows))
    for _,row in pairs(arrRows) do
        local tRecord = {}
        tRecord.nId = tonumber(row.id) or 0
        tRecord.nWinLose = tonumber(row.WinLose) or 0
        tRecord.nLiveUserID = tonumber(row.LiveUserId) or 0
        tRecord.sTableInfo = row.TableInfo or ""
        tRecord.sFaceId = row.FaceId or ""
        tRecord.sTime = row.UpdateTime or ""
        tRecord.sTableId = row.TableId or ""
        -- tRecord.nTableIndex =tonumber(row.TableTimeStep) or 0
        tRecord.nFaceIdList = row.FaceIdList or ""
        table.insert(arrRecords,tRecord)
    end

    -- if tData.nIdOfStart == 0 then
    --     local sSql1 = string.format("call Club_GetHallStatisticV2(%d,%d,%d,%d,%d)",tData.nUserId,tData.nGameId,tData.nGoldType,tData.nClubId,tData.nDay)
    --     tBase.Log("OnClubGetPersonTableRecord2Req sSql1:%s",sSql1)
    --     local arrRows1 =RecordDB_SqlExecute(sSql1,true)
    --     -- tBase.Log("GetHallStatisticV2Result userId=%d gameId=%d day=%d result={%s}",tData.nUserId,tData.nGameId,tData.nDay,cjson.encode(arrRows1))
    --     local row1 = arrRows1[1]
    --     if row1 then
    --         tStatics ={}
    --         tStatics.nPaiJuCnt=tonumber(row1.PaiJuCnt) or 0
    --         tStatics.nPlayCount=tonumber(row1.PlayCount) or 0
    --         tStatics.nProfitSum=tonumber(row1.ProfitSum)  or 0
    --         tStatics.nInPoolCount=tonumber(row1.InPoolCount)  or 0
    --         tStatics.nRaiseCountBFlop= 0
    --         tStatics.nAllInAndWinCount= 0
    --     end
    -- end
    if tData.nIdOfStart==0 then
        if tApi.IsTexasClassGame(tData.nGameId) then --德州，奥马哈，短牌
            local sSql1 = string.format("call Club_GetTexaStatistic_time(%d,%d,%d,%d,'%s','%s')",tData.nUserId,tData.nGameId,tData.nGoldType,tData.nClubId,tData.nStartTime,tData.nEndTime)
            tBase.Log("OnClubGetPersonTableRecord2Req sSql1:%s",sSql1)
            local arrRows1 =RecordDB_SqlExecute(sSql1,true)
            local row1 = arrRows1[1]
            if row1 then
                tStatics ={}
                tStatics.nPaiJuCnt=tonumber(row1.PaiJuCnt) or 0
                tStatics.nPlayCount=tonumber(row1.PlayCount) or 0
                tStatics.nProfitSum=tonumber(row1.ProfitSum)  or 0
                tStatics.nInPoolCount=tonumber(row1.InPoolCount) or 0
                tStatics.nRaiseCountBFlop=tonumber(row1.RaiseCountBFlop) or 0
                tStatics.nAllInAndWinCount=tonumber(row1.AllInAndWinCount) or 0
                tStatics.nWinCount=tonumber(row1.WinCount) or 0
                tStatics.nQiPaiCount=tonumber(row1.ReachShowdown) or 0
                tStatics.nHandProfit=tonumber(row1.HandProfit) or 0
                tStatics.nAllInCount = tonumber(row1.AllInCount) or 0
            end
        end
    end
    if next(arrRecords) == nil then
        local ClubGetPersonTableRecord2Rsp = {}
        tBase.Log("hhhhhhhhhhhhhhhhhhhhhhhh %d",#arrRecords)
        ClubGetPersonTableRecord2Rsp.arrRecords = {}
        ClubGetPersonTableRecord2Rsp.tStatics = tStatics
        ClubGetPersonTableRecord2Rsp.nGameId = tData.nGameId
        ClubGetPersonTableRecord2Rsp.nUserId = tData.nUserId
        ClubGetPersonTableRecord2Rsp.nClubId = tData.nClubId
        ClubGetPersonTableRecord2Rsp.nGoldType = tData.nGoldType
        ClubGetPersonTableRecord2Rsp.nIdOfStart = tData.nIdOfStart
        ClubGetPersonTableRecord2Rsp.nDay = tData.nDay
        ClubGetPersonTableRecord2Rsp.nStartTime = tData.nStartTime
        ClubGetPersonTableRecord2Rsp.nEndTime = tData.nEndTime
        DbClubSendToServer(sReturnKey,"ClubGetPersonTableRecord2Rsp",ClubGetPersonTableRecord2Rsp)
        return
    end
    
    local arr = {}
    for k,v in pairs(arrRecords) do
        if v then 
            table.insert(arr,v)
            if #arr >= 5 or k == #arrRecords then 
                local ClubGetPersonTableRecord2Rsp = {}
                -- tBase.Log("recordsReturn userId=%d gameId=%d day=%d arr={%s} tStatics={%s}",tData.nUserId,tData.nGameId,tData.nDay,cjson.encode(arr),cjson.encode(tStatics))
                ClubGetPersonTableRecord2Rsp.arrRecords = arr
                ClubGetPersonTableRecord2Rsp.tStatics = tStatics
                ClubGetPersonTableRecord2Rsp.nGameId = tData.nGameId
                ClubGetPersonTableRecord2Rsp.nUserId = tData.nUserId
                ClubGetPersonTableRecord2Rsp.nClubId = tData.nClubId
                ClubGetPersonTableRecord2Rsp.nGoldType = tData.nGoldType
                ClubGetPersonTableRecord2Rsp.nIdOfStart = tData.nIdOfStart
                ClubGetPersonTableRecord2Rsp.nDay = tData.nDay
                ClubGetPersonTableRecord2Rsp.nStartTime = tData.nStartTime
                ClubGetPersonTableRecord2Rsp.nEndTime = tData.nEndTime
                DbClubSendToServer(sReturnKey,"ClubGetPersonTableRecord2Rsp",ClubGetPersonTableRecord2Rsp)
                arr={}
            end 
        end 
    end 
    
end

--输入兑换码 请求
function ClubSink.OnClubInputRedeemCodeReq(sReturnKey,Data,nLen)
    local strReq ="ClubInputRedeemCodeReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
   
    local tExData = {}
    local sSql = string.format("call Club_InputRedeemCode(%d,'%s')",tData.nUserId,tData.sRedeemCode)
    tBase.Log("ClubInputRedeemCodeReq sSql:%s",sSql)
    local arrRows =RecordDB_SqlExecute(sSql)
    local row = arrRows[1]
    local nRlt = 99
    if row then
        nRlt = tonumber(row.ErrCode) or 99
        tExData.sName = row.sName  --兑换物品的名称
        tExData.nGiftBagId = tonumber(row.nGiftBagId)    --奖励组ID
        tExData.nItemId = tonumber(row.nItemId)    --奖励道具ID
        tExData.nCount = tonumber(row.nCount)    --道具数量
        tExData.sRemark = row.sRemark    --兑换物品描述
    end

    local ClubInputRedeemCodeRsp = {}
    ClubInputRedeemCodeRsp.nRlt = nRlt
    ClubInputRedeemCodeRsp.sExData = cjson.encode(tExData)
    ClubInputRedeemCodeRsp.nUserId = tData.nUserId
    DbClubSendToServer(sReturnKey,"ClubInputRedeemCodeRsp",ClubInputRedeemCodeRsp)  
end

--安全密码校验请求
function ClubSink.OnClubSearchSecuPwdReq(sReturnKey,Data,nLen)
    local strReq ="ClubSearchSecuPwdReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = string.format("call Club_SearchSecuPwd(%d)",tData.nUserId)
    local arrRows =AccountsDB_SqlExecute(sSql)
    local row = arrRows[1]
    
    local nRlt = 1
    if row then
        tBase.Log("数据库安全密码:%s",row.SecuPwd)
        tBase.Log("输入的安全密码:%s",tData.SecuPwd)
        if row.SecuPwd == tData.SecuPwd then
            nRlt = 0
        end
    end

    local ClubSearchSecuPwdRsp = {}
    ClubSearchSecuPwdRsp.nRlt = nRlt
    ClubSearchSecuPwdRsp.sKey = tData.sKey
    ClubSearchSecuPwdRsp.nUserId = tData.nUserId
    DbClubSendToServer(sReturnKey,"ClubSearchSecuPwdRsp",ClubSearchSecuPwdRsp)
end

--安全密码录入请求
function ClubSink.OnClubSecuPwdReq(sReturnKey,Data,nLen)
    local strReq ="ClubSecuPwdReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = string.format("call Club_WirteUserSecuPwd(%d,'%s')",tData.nUserId,tData.SecuPwd)
    RecordDB_SqlExecute(sSql)
    local ClubSecuPwdRsp = {}
    ClubSecuPwdRsp.nUserId = tData.nUserId
    ClubSecuPwdRsp.nRlt = 0
    DbClubSendToServer(sReturnKey,"ClubSecuPwdRsp",ClubSecuPwdRsp)
end

--用户额外信息录入请求
function ClubSink.OnClubAddiInfoChangeReq(sReturnKey,Data,nLen)
    local strReq ="ClubAddiInfoChangeReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = string.format("call Club_WriteUserAddiInfo(%d,'%s')",tData.nUserId,tData.nAddiInfo)
    RecordDB_SqlExecute(sSql)
    local ClubAddiInfoChangeRsp = {}
    ClubAddiInfoChangeRsp.nRlt = 0
    ClubAddiInfoChangeRsp.nUserId = tData.nUserId
    DbClubSendToServer(sReturnKey,"ClubAddiInfoChangeRsp",ClubAddiInfoChangeRsp)
end

--获取牌桌详细记录 请求
function ClubSink.OnClubGetTableDetailReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetTableDetailReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local tTexas = nil
    if tApi.IsTexasClassGame(tData.nGameId) or tApi.IsNiuNiuClassGame(tData.nGameId) then
        --获取德州类游戏的牌桌详情
        local sSql = string.format("call Club_GetTexasTableDetail('%s')",tData.sTableId)
        tBase.Log("OnClubGetTableDetailReq sSql:%s",sSql)
        local arrRows =RecordDB_SqlExecute(sSql,true)
        local row = arrRows[1]
        if row then
            --房主
            local tLiver = {}
            tLiver.nUserId = tonumber(row.nLiverUserId) or 0
            tLiver.sFaceId = row.sLiverFaceId or ""
            tLiver.sName = row.sLiverName or ""
            --MVP
            local tMVPUser = {}
            tMVPUser.nUserId = tonumber(row.nMVPUserId) or 0
            tMVPUser.sFaceId = row.sMVPFaceId or ""
            tMVPUser.sName = row.sMVPName or ""
            --土豪
            local tTHUser = {}
            tTHUser.nUserId = tonumber(row.sTHFaceId) or 0
            tTHUser.sFaceId = row.sTHFaceId or ""
            tTHUser.sName = row.sTHName or ""
            
            --大鱼
            local tDYUser = {}
            tDYUser.nUserId = tonumber(row.nDYUserId) or 0
            tDYUser.sFaceId = row.sDYFaceId or ""
            tDYUser.sName = row.sDYName or ""

            tTexas = {}
            tTexas.tLiver = tLiver
            tTexas.tMVPUser = tMVPUser
            tTexas.tTHUser = tTHUser
            tTexas.tDYUser = tDYUser
            tTexas.nHandCnt = tonumber(row.nHandCnt) or 0
            tTexas.nTakeIn = tonumber(row.nTakeIn) or 0
            tTexas.nJournalAccount = tonumber(row.nJournalAccount) or 0
            tTexas.nMaxPool = tonumber(row.nMaxPool) or 0
            tTexas.nGameId = tData.nGameId
            tTexas.sTime = row.sTime or ""
            tTexas.nKeepTime = tonumber(row.nKeepTime) or 0
            tTexas.nInsurancePool = tonumber(row.nInsurancePool) or 0
            tTexas.sTableInfo = row.sTableInfo or ""
            tTexas.nSumBet = tonumber(row.nSumBet) or 0
        end
    end

    local ClubGetTableDetailRsp = {}
    ClubGetTableDetailRsp.tTexas = tTexas
    ClubGetTableDetailRsp.nGameId = tData.nGameId
    ClubGetTableDetailRsp.nUserId = tData.nUserId
    ClubGetTableDetailRsp.sTableId = tData.sTableId
    DbClubSendToServer(sReturnKey,"ClubGetTableDetailRsp",ClubGetTableDetailRsp)
end

--获取牌桌详细记录2 请求
function ClubSink.OnClubGetTableDetail2Req(sReturnKey,Data,nLen)
    local strReq ="ClubGetTableDetail2Req"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local tTexas = nil
    local nGroupId =tPubUsrApi.Get_User_GroupId(tData.nUserId)
    if tApi.IsTexasClassGame(tData.nGameId) or tApi.IsNiuNiuClassGame(tData.nGameId) then
        --获取德州类游戏的牌桌详情
        local sSql = string.format("call Club_GetTexasTableDetailHall(%d,'%s',%d,%d)",tData.nTableIndex,tData.sTableName,tData.nGameId,nGroupId)
         tBase.Log("OnClubGetTableDetailReq sSql:%s",sSql)
        local arrRows =RecordDB_SqlExecute(sSql,true)
        local row = arrRows[1]
        if row then
            --房主
            local tLiver = {}
            tLiver.nUserId = tonumber(row.nLiverUserId) or 0
            tLiver.sFaceId = row.sLiverFaceId or ""
            tLiver.sName = row.sLiverName or ""
            --MVP
            local tMVPUser = {}
            tMVPUser.nUserId = tonumber(row.nMVPUserId) or 0
            tMVPUser.sFaceId = row.sMVPFaceId or ""
            tMVPUser.sName = row.sMVPName or ""
            --土豪
            local tTHUser = {}
            tTHUser.nUserId = tonumber(row.nTHUserId) or 0
            tTHUser.sFaceId = row.sTHFaceId or ""
            tTHUser.sName = row.sTHName or ""
            --tBase.Log("土豪---OnClubGetTableDetailReq nUserId:%s",tTHUser.nUserId)
            --大鱼
            local tDYUser = {}
            tDYUser.nUserId = tonumber(row.nDYUserId) or 0
            tDYUser.sFaceId = row.sDYFaceId or ""
            tDYUser.sName = row.sDYName or ""

            tTexas = {}
            tTexas.tLiver = tLiver
            tTexas.tMVPUser = tMVPUser
            tTexas.tTHUser = tTHUser
            tTexas.tDYUser = tDYUser
            tTexas.nHandCnt = tonumber(row.nHandCnt) or 0
            tTexas.nTakeIn = tonumber(row.nTakeIn) or 0
            tTexas.nJournalAccount = tonumber(row.nJournalAccount) or 0
            tTexas.nMaxPool = tonumber(row.nMaxPool) or 0
            tTexas.nGameId = tData.nGameId
            tTexas.sTime = row.sTime or ""
            tTexas.nKeepTime = tonumber(row.nKeepTime) or 0
            tTexas.nInsurancePool = tonumber(row.nInsurancePool) or 0
            tTexas.sTableInfo = row.sTableInfo or ""
        end
    end

    local ClubGetTableDetail2Rsp = {}
    ClubGetTableDetail2Rsp.tTexas = tTexas
    ClubGetTableDetail2Rsp.nGameId = tData.nGameId
    ClubGetTableDetail2Rsp.nUserId = tData.nUserId
    ClubGetTableDetail2Rsp.sTableName = tData.sTableName
    ClubGetTableDetail2Rsp.nTableIndex = tData.nTableIndex
    DbClubSendToServer(sReturnKey,"ClubGetTableDetail2Rsp",ClubGetTableDetail2Rsp)
end

--获取牌桌牌谱 请求 当前版本
function ClubSink.OnClubGetTablePaiPuReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetTablePaiPuReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrPaiJu = {}
    local nAllCnt = 0
    local nBegin = (tData.nPage-1)*tData.nCnt
    local nJuShu = nBegin + 1

    if tApi.IsTexasClassGame(tData.nGameId) or tApi.IsNiuNiuClassGame(tData.nGameId) then
        local sSql = string.format("call Club_GetTexasTablePaiPuV2('%s',%d,%d,%d)",tData.sTableId,nBegin,tData.nCnt,tData.nUserId)
        tBase.Log("OnClubGetTablePaiPuReq sSql:%s",sSql)
        local arrRows =RecordDB_SqlExecute(sSql,true)
        for _,row in pairs(arrRows) do
            local tHandCards,tTableInfo = {},{}
            local isSuccee1,tUsersInfo = pcall(cjson.decode,row.UsersInfo)
            if not isSuccee1 then
                tUsersInfo = {}
                Base.Log("_OnClubPaiPuReq decode UsersInfo fail PaiJuId_%s",row.PaiJuId or "")
            end
            local isSuccee2,tDealCardInfo = pcall(cjson.decode,row.DealCardInfo)
            if not isSuccee2 then
                tDealCardInfo = {}
                Base.Log("_OnClubPaiPuReq decode DealCardInfo fail PaiJuId_%s",row.PaiJuId or "")
            end
            local isSuccee3,tElseInfo = pcall(cjson.decode,row.ElseInfo)
            if not isSuccee3 then
                tElseInfo = {}
                Base.Log("_OnClubPaiPuReq decode ElseInfo fail PaiJuId_%s",row.PaiJuId or "")
            end
            local tBetInfo = {}
            if row.BetInfo then
                local isSuccee4, info = pcall(cjson.decode, row.BetInfo)
                if not isSuccee4 then
                    Base.Log("_OnClubPaiPuReq decode BetInfo fail PaiJuId_%s",row.PaiJuId or "")
                end
                tBetInfo = info
            end
            --手牌信息
            local nSitId = -1
            for _,tUserInfo in pairs(tUsersInfo) do
                if tUserInfo.nUserId==tData.nUserId then
                    nSitId = tUserInfo.nSitId
                    break
                end
            end
            local sumBet = 0
            local nUserBet = 0
            for _, bet in pairs(tBetInfo) do
                if bet.nBet then
                    sumBet = sumBet + bet.nBet
                end
                if nSitId == bet.nSitId then
                    nUserBet = nUserBet + bet.nBet
                end
            end
            for _,tCardInfo in pairs(tDealCardInfo) do
                if tCardInfo.nSitId==nSitId or tCardInfo.nUserId==tData.nUserId then
                    tHandCards.nCardType = tCardInfo.nCardType
                    tHandCards.arrCard = tCardInfo.arrCard
                    break
                end
            end
            --牌桌配置信息
            tTableInfo = {}
            tTableInfo.nPool = 0 --总底池
            local tWinInfo = {}
            if tApi.IsTexasClassGame(tData.nGameId) then
                for _,nPool in pairs(tElseInfo.arrPool or {}) do
                    tTableInfo.nPool = tTableInfo.nPool + nPool
                end
                if tElseInfo.tTableInfo then
                    tTableInfo.nSmallBlind = tElseInfo.tTableInfo.nSmallBlind
                    tTableInfo.nBigBlind = tElseInfo.tTableInfo.nBigBlind
                end
                --赢家信息
                if tElseInfo.tWinUserInfo then
                    tWinInfo.sName = tElseInfo.tWinUserInfo.sName
                    tWinInfo.nCardType = tElseInfo.tWinUserInfo.nCardType
                    tWinInfo.isWinByGiveup = (tElseInfo.tWinUserInfo.nCardType==0)
                    tWinInfo.isPingJu = (tElseInfo.tWinUserInfo.nCardType==nil)
                    tWinInfo.sWin = tElseInfo.tWinUserInfo.nWin or 0
                end
            elseif tApi.IsNiuNiuClassGame(tData.nGameId) then
            end
            local nDrawWater =tonumber(row.DrawWater) or 0
            local isScc,tRElseInfo = pcall(cjson.decode,row.RElseInfo)
            if not isScc then
                tRElseInfo = {}
                Base.Log("_OnClubPaiPuReq decode RElseInfo fail PaiJuId_%s",row.PaiJuId or "")
            end
            local nInsur =tRElseInfo.nInsur or 0
            local nWinLose =tonumber(row.WinLose) or 0
            tTableInfo.nCreateTime = row.CreateTime or ""
            tTableInfo.nSumBet = sumBet

            local tClubPaiJuRecordItem = {}
            tClubPaiJuRecordItem.nId = tonumber(row.id) or 0
            tClubPaiJuRecordItem.sPaiJuID = row.PaiJuId or ""
            tClubPaiJuRecordItem.sTableInfo = cjson.encode(tTableInfo)
            tClubPaiJuRecordItem.sHandCards = cjson.encode(tHandCards)
            -- tClubPaiJuRecordItem.nWinLose = nWinLose +nDrawWater -nInsur  --不计算抽水和保险
            tClubPaiJuRecordItem.nWinLose = nWinLose
            tClubPaiJuRecordItem.nUserBet = nUserBet
            tClubPaiJuRecordItem.nJuShu = nJuShu
            tClubPaiJuRecordItem.sWinInfo = cjson.encode(tWinInfo)
            tClubPaiJuRecordItem.nCollect = tonumber(row.nCollect) or 0
            table.insert(arrPaiJu,tClubPaiJuRecordItem)
            nAllCnt = tonumber(row.nAllCnt) or 0
            nJuShu = nJuShu + 1
        end
    end

    local ClubGetTablePaiPuRsp = {}
    ClubGetTablePaiPuRsp.arrPaiJu = arrPaiJu
    ClubGetTablePaiPuRsp.nGameId = tData.nGameId
    ClubGetTablePaiPuRsp.nUserId = tData.nUserId
    ClubGetTablePaiPuRsp.sTableId = tData.sTableId
    ClubGetTablePaiPuRsp.nAllCnt = nAllCnt
    ClubGetTablePaiPuRsp.nPage = tData.nPage
    DbClubSendToServer(sReturnKey,"ClubGetTablePaiPuRsp",ClubGetTablePaiPuRsp)
end

--获取牌桌牌谱2 请求(大厅永久牌桌)
function ClubSink.OnClubGetTablePaiPu2Req(sReturnKey,Data,nLen)
    local strReq ="ClubGetTablePaiPu2Req"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local arrPaiJu = {}
    local nAllCnt = 0
    local nBegin = (tData.nPage-1)*tData.nCnt
    local nJuShu = nBegin + 1

    local nGroupId =tPubUsrApi.Get_User_GroupId(tData.nUserId)
    if tApi.IsTexasClassGame(tData.nGameId) or tApi.IsNiuNiuClassGame(tData.nGameId) then
        local sSql = string.format("call Club_GetTexasTablePaiPuHall('%s',%d,%d,%d,%d,%d,%d)",
            tData.sTableName,nBegin,tData.nCnt,tData.nUserId,tData.nTableIndex,tData.nGameId,nGroupId)
        tBase.Log("OnClubGetTablePaiPuReq sSql:%s",sSql)
        local arrRows =RecordDB_SqlExecute(sSql,true)
        for _,row in pairs(arrRows) do
            local tHandCards,tTableInfo = {},{}
            local isSuccee1,tUsersInfo = pcall(cjson.decode,row.UsersInfo)
            if not isSuccee1 then
                tUsersInfo = {}
                Base.Log("_OnClubPaiPuReq decode UsersInfo fail PaiJuId_%s",row.PaiJuId or "")
            end
            local isSuccee2,tDealCardInfo = pcall(cjson.decode,row.DealCardInfo)
            if not isSuccee2 then
                tDealCardInfo = {}
                Base.Log("_OnClubPaiPuReq decode DealCardInfo fail PaiJuId_%s",row.PaiJuId or "")
            end
            local isSuccee3,tElseInfo = pcall(cjson.decode,row.ElseInfo)
            if not isSuccee3 then
                tElseInfo = {}
                Base.Log("_OnClubPaiPuReq decode ElseInfo fail PaiJuId_%s",row.PaiJuId or "")
            end
            --手牌信息
            local nSitId = -1
            for _,tUserInfo in pairs(tUsersInfo) do
                if tUserInfo.nUserId==tData.nUserId then
                    nSitId = tUserInfo.nSitId
                    break
                end
            end
            for _,tCardInfo in pairs(tDealCardInfo) do
                if tCardInfo.nSitId==nSitId or tCardInfo.nUserId==tData.nUserId then
                    tHandCards.nCardType = tCardInfo.nCardType
                    tHandCards.arrCard = tCardInfo.arrCard
                    break
                end
            end
            --牌桌配置信息
            tTableInfo = {}
            tTableInfo.nPool = 0 --总底池
            local tWinInfo = {}
            if tApi.IsTexasClassGame(tData.nGameId) then
                for _,nPool in pairs(tElseInfo.arrPool or {}) do
                    tTableInfo.nPool = tTableInfo.nPool + nPool
                end
                if tElseInfo.tTableInfo then
                    tTableInfo.nSmallBlind = tElseInfo.tTableInfo.nSmallBlind or 0
                    tTableInfo.nBigBlind = tElseInfo.tTableInfo.nBigBlind or 0
                end
                --赢家信息
                if tElseInfo.tWinUserInfo then
                    tWinInfo.sName = tElseInfo.tWinUserInfo.sName
                    tWinInfo.nCardType = tElseInfo.tWinUserInfo.nCardType
                    tWinInfo.isWinByGiveup = (tElseInfo.tWinUserInfo.nCardType==0)
                    tWinInfo.isPingJu = (tElseInfo.tWinUserInfo.nCardType==nil)
                end
            elseif tApi.IsNiuNiuClassGame(tData.nGameId) then
            end
            local tClubPaiJuRecordItem = {}
            tClubPaiJuRecordItem.nId = tonumber(row.id) or 0
            tClubPaiJuRecordItem.sPaiJuID = row.PaiJuId or ""
            tClubPaiJuRecordItem.sTableInfo = cjson.encode(tTableInfo)
            tClubPaiJuRecordItem.sHandCards = cjson.encode(tHandCards)
            tClubPaiJuRecordItem.nWinLose = tonumber(row.WinLose) or 0
            tClubPaiJuRecordItem.nJuShu = nJuShu
            tClubPaiJuRecordItem.sWinInfo = cjson.encode(tWinInfo)
            tClubPaiJuRecordItem.nCollect = tonumber(row.nCollect) or 0
            table.insert(arrPaiJu,tClubPaiJuRecordItem)
            nAllCnt = tonumber(row.nAllCnt) or 0
            nJuShu = nJuShu + 1
        end
    end

    local ClubGetTablePaiPu2Rsp = {}
    ClubGetTablePaiPu2Rsp.arrPaiJu = arrPaiJu
    ClubGetTablePaiPu2Rsp.nGameId = tData.nGameId
    ClubGetTablePaiPu2Rsp.nUserId = tData.nUserId
    ClubGetTablePaiPu2Rsp.sTableName = tData.sTableName
    ClubGetTablePaiPu2Rsp.nAllCnt = nAllCnt
    ClubGetTablePaiPu2Rsp.nPage = tData.nPage
    ClubGetTablePaiPu2Rsp.nTableIndex = tData.nTableIndex
    DbClubSendToServer(sReturnKey,"ClubGetTablePaiPu2Rsp",ClubGetTablePaiPu2Rsp)
end

--获取牌桌保险明细 请求
function ClubSink.OnClubGetTableInsuranceReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetTableInsuranceReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrUserDetail = {}
    local nBegin = (tData.nPage-1)*tData.nCnt
    local nAllCnt = 0

    local sSql = string.format("call Club_GetTexasTableInsurance('%s',%d,%d)",tData.sTableId,nBegin,tData.nCnt)
    tBase.Log("OnClubGetTableInsuranceReq sSql:%s",sSql)
    local arrRows =RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local t = {}
        t.nUserId = tonumber(row.UserId) or 0
        t.sFaceId = row.FaceID or ""
        t.sName = row.NickName or ""
        if #t.sFaceId==0 then
            t.sFaceId = row.ssFaceID or ""
        end
        if #t.sName==0 then
            t.sName = row.ssNickName or ""
        end
        t.nInsurance = tonumber(row.Insurance) or 0
        table.insert(arrUserDetail,t)
        nAllCnt = tonumber(row.nAllCnt) or 0
    end

    local ClubGetTableInsuranceRsp = {}
    ClubGetTableInsuranceRsp.arrUserDetail = arrUserDetail
    ClubGetTableInsuranceRsp.nPage = tData.nPage
    ClubGetTableInsuranceRsp.nAllCnt = nAllCnt
    ClubGetTableInsuranceRsp.nUserId = tData.nUserId
    ClubGetTableInsuranceRsp.sTableId = tData.sTableId
    DbClubSendToServer(sReturnKey,"ClubGetTableInsuranceRsp",ClubGetTableInsuranceRsp)
end

--获取牌桌保险明细2 请求(大厅永久牌桌)
function ClubSink.OnClubGetTableInsurance2Req(sReturnKey,Data,nLen)
    local strReq ="ClubGetTableInsurance2Req"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrUserDetail = {}
    local nBegin = (tData.nPage-1)*tData.nCnt
    local nAllCnt = 0

    local nGroupId =tPubUsrApi.Get_User_GroupId(tData.nUserId)
    local sSql = string.format("call Club_GetTexasTableInsuranceHall('%s',%d,%d,%d,%d,%d)",
        tData.sTableName,nBegin,tData.nCnt,tData.nTableIndex,tData.nGameId,nGroupId)
    tBase.Log("OnClubGetTableInsurance2Req sSql:%s",sSql)
    local arrRows =RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local t = {}
        t.nUserId = tonumber(row.UserId) or 0
        t.sFaceId = row.FaceID or ""
        t.sName = row.NickName or ""
        t.nInsurance = tonumber(row.Insurance) or 0
        table.insert(arrUserDetail,t)
        nAllCnt = tonumber(row.nAllCnt) or 0
    end

    local ClubGetTableInsurance2Rsp = {}
    ClubGetTableInsurance2Rsp.arrUserDetail = arrUserDetail
    ClubGetTableInsurance2Rsp.nPage = tData.nPage
    ClubGetTableInsurance2Rsp.nAllCnt = nAllCnt
    ClubGetTableInsurance2Rsp.nUserId = tData.nUserId
    ClubGetTableInsurance2Rsp.sTableName = tData.sTableName
    ClubGetTableInsurance2Rsp.nTableIndex = tData.nTableIndex
    ClubGetTableInsurance2Rsp.nGameId = tData.nGameId
    DbClubSendToServer(sReturnKey,"ClubGetTableInsurance2Rsp",ClubGetTableInsurance2Rsp)
end

--获取牌局明细查询请求(抢庄牛)
function ClubSink.OnClubGetPaijuDetailReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetPaijuDetailReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql =string.format("call PaiJuDetail_Read_v6('%s')",tData.sPaiJuID)
    tBase.Log("OnClubGetPaijuDetailReq sSql:%s",sSql)
    local arrRows =RecordDB_SqlExecute(sSql,true)
    local tRow =arrRows[1] or {}
 
    local ClubGetPaijuDetailRsp={}
    ClubGetPaijuDetailRsp.GameId =tonumber(tRow.GameId) or -1
    ClubGetPaijuDetailRsp.nAnte =tonumber(tRow.Ante) or -1
    ClubGetPaijuDetailRsp.tUsersInfo =tRow.UsersInfo or "{}"
    ClubGetPaijuDetailRsp.nZhuang =tonumber(tRow.Zhuang) or -1 
    ClubGetPaijuDetailRsp.tDealCardInfo =tRow.DealCardInfo or "{}"
    ClubGetPaijuDetailRsp.tBetInfo=tRow.BetInfo or "{}"
    ClubGetPaijuDetailRsp.sTime =tRow.PaiJuTime or ""
    ClubGetPaijuDetailRsp.sPaiJuID =tData.sPaiJuID or ""
    ClubGetPaijuDetailRsp.nUserId =tData.nUserId

    DbClubSendToServer(sReturnKey,"ClubGetPaijuDetailRsp",ClubGetPaijuDetailRsp)
end

--充值账单查询请求
function ClubSink.OnDBClubGetPayOrderReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetPayOrderReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then 
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    -- 只需要成功
    local sSql =string.format("select * from DJH_RecordDB.Pay_History_Record WHERE UserID = %d AND PayType in(1,2) ORDER BY CreateTime DESC ;",tData.nUserId) 
    local arrRows =RecordDB_SqlExecute(sSql,true)    
    local arrPayRecord = {}   
    for k,row in pairs(arrRows) do  
        local tRecord = {}
        tRecord.sCreateTime = row.CreateTime or ""
        tRecord.nPayType = tonumber(row.PayType) or 0
        tRecord.nChannelType = tonumber(row.ChannelType) or 0
        tRecord.nGoldType = tonumber(row.GoldType) or 0
        tRecord.nCount = tonumber(row.Count) or 0
        tRecord.nGoldChange = tonumber(row.GoldChange) or 0
        tRecord.nBalance = tonumber(row.Balance) or 0  
        tRecord.id = tonumber(row.id) or 0  
        tRecord.nAuditStatus = tonumber(row.AuditStatus) or 0   
        tRecord.nExchangeRate = tonumber(row.ExchangeRate) or 0     
        tRecord.sBankAccount = row.BankAccount or ""    
        tRecord.nState = tonumber(row.State) or 0     
        table.insert(arrPayRecord,tRecord)
        if #arrPayRecord >= 60 or #arrRows == k then 
            local ClubGetPayOrderRep={}
            ClubGetPayOrderRep.nUserId = tData.nUserId
            ClubGetPayOrderRep.arrPayRecord = arrPayRecord
            DbClubSendToServer(sReturnKey,"ClubGetPayOrderRep",ClubGetPayOrderRep)
            arrPayRecord = {}
        end 
    end
    if #arrRows == 0 then 
        local ClubGetPayOrderRep={}
        ClubGetPayOrderRep.nUserId = tData.nUserId
        ClubGetPayOrderRep.arrPayRecord = arrPayRecord
        DbClubSendToServer(sReturnKey,"ClubGetPayOrderRep",ClubGetPayOrderRep)
    end 
    tBase.Log("_OnDBClubGetPayOrderReq  arrPayRecord: %d  sSql:%s",#arrPayRecord,sSql)
end


--获取牌桌玩家列表 请求
function ClubSink.OnClubGetTableUserListReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetTableUserListReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrUserDetail = {}
    local nAllCnt = 0

    local nBegin = (tData.nPage-1)*tData.nCnt

    if tApi.IsTexasClassGame(tData.nGameId) or tApi.IsNiuNiuClassGame(tData.nGameId) then
        local sSql = string.format("call Club_GetTexasTableUserList('%s',%d,%d)",tData.sTableId,nBegin,tData.nCnt)
        tBase.Log("OnClubGetTableUserListReq sSql:%s",sSql)
        local arrRows =RecordDB_SqlExecute(sSql,true)
        local nRank = nBegin + 1
        for _,row in ipairs(arrRows) do
            local nProfitSum = tonumber(row.ProfitSum) or 0
            local nInsurance = tonumber(row.Insurance) or 0
            local t = {}
            t.nUserId = tonumber(row.UserId) or 0
            t.sFaceId = row.FaceID or ""
            t.sName = row.NickName or ""
            t.nWinLose = nProfitSum     --包含了抽水和保险
            t.nPlayCnt = tonumber(row.PlayCount) or 0
            t.nRank = nRank
            t.nTakeIn = tonumber(row.TakeInTotal) or 0
            t.nInPoolCount = tonumber(row.InPoolCount) or 0
            table.insert(arrUserDetail,t)
            nAllCnt = tonumber(row.nAllCnt) or 0
            nRank = nRank + 1
        end
    end

    local ClubGetTableUserListRsp = {}
    ClubGetTableUserListRsp.arrUserDetail = arrUserDetail
    ClubGetTableUserListRsp.nPage = tData.nPage
    ClubGetTableUserListRsp.nAllCnt = nAllCnt
    ClubGetTableUserListRsp.nUserId = tData.nUserId
    ClubGetTableUserListRsp.nGameId = tData.nGameId
    ClubGetTableUserListRsp.sTableId = tData.sTableId
    DbClubSendToServer(sReturnKey,"ClubGetTableUserListRsp",ClubGetTableUserListRsp)
end

--获取牌桌玩家列表2 请求(大厅永久牌桌)
function ClubSink.OnClubGetTableUserList2Req(sReturnKey,Data,nLen)
    local strReq ="ClubGetTableUserList2Req"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrUserDetail = {}
    local nAllCnt = 0

    local nBegin = (tData.nPage-1)*tData.nCnt

    local nGroupId =tPubUsrApi.Get_User_GroupId(tData.nUserId)
    if tApi.IsTexasClassGame(tData.nGameId) or tApi.IsNiuNiuClassGame(tData.nGameId) then
        local sSql = string.format("call Club_GetTexasTableUserListHall('%s',%d,%d,%d,%d,%d)",
            tData.sTableName,nBegin,tData.nCnt,tData.nTableIndex,tData.nGameId,nGroupId)
        tBase.Log("OnClubGetTableUserList2Req sSql:%s",sSql)
        local arrRows =RecordDB_SqlExecute(sSql,true)
        local nRank = nBegin + 1
        for _,row in ipairs(arrRows) do
            local nProfitSum = tonumber(row.ProfitSum) or 0
            local nInsurance = tonumber(row.Insurance) or 0
            local t = {}
            t.nUserId = tonumber(row.UserId) or 0
            t.sFaceId = row.FaceID or ""
            t.sName = row.NickName or ""
            t.nWinLose = nProfitSum-nInsurance
            t.nPlayCnt = tonumber(row.PlayCount) or 0
            t.nRank = nRank
            t.nTakeIn = tonumber(row.TakeInTotal) or 0
            t.nInPoolCount = tonumber(row.InPoolCount) or 0
            table.insert(arrUserDetail,t)
            nAllCnt = tonumber(row.nAllCnt) or 0
            nRank = nRank + 1
        end
    end

    local ClubGetTableUserList2Rsp = {}
    ClubGetTableUserList2Rsp.arrUserDetail = arrUserDetail
    ClubGetTableUserList2Rsp.nPage = tData.nPage
    ClubGetTableUserList2Rsp.nAllCnt = nAllCnt
    ClubGetTableUserList2Rsp.nUserId = tData.nUserId
    ClubGetTableUserList2Rsp.nGameId = tData.nGameId
    ClubGetTableUserList2Rsp.sTableName = tData.sTableName
    ClubGetTableUserList2Rsp.nTableIndex = tData.nTableIndex
    DbClubSendToServer(sReturnKey,"ClubGetTableUserList2Rsp",ClubGetTableUserList2Rsp)
end

--记录玩家的GPS 请求
function ClubSink.OnClubWriteUserGPS(sReturnKey,Data,nLen)
    local strReq ="ClubWriteUserGPS"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    
    tBase.Log("OnClubWriteUserGPS %s",tData.sSql)
    AccountsDB_SqlExecute(tData.sSql)
end
----------------------------------- 俱乐部总资产-------------------------------------

-- 通知俱乐部中心服   同步 总资产 
function SendClubCenterAsset(nClubId,nClubGold,nItemId) 
    local arrServKey = tPublicRedis.GetClubCenterSrvKey(nClubId)
    if #arrServKey>0 then
        for _,sClubCenterKey in pairs(arrServKey) do
            sClubCenterKey=sClubCenterKey..":0"
            local ClubAssetChangeNotify = {}
            ClubAssetChangeNotify.nClubId = nClubId
            ClubAssetChangeNotify.nClubGold = nClubGold or 0
            ClubAssetChangeNotify.nItemId = nItemId
            DbClubSendToServer(sClubCenterKey,"ClubAssetChangeNotify",ClubAssetChangeNotify)
            tBase.Log("_SendClubCenterAsset  通知俱乐部同步总资产nClubId: %d nItemId:%d nClubGold: %f %s ",nClubId,nItemId,nClubGold,sClubCenterKey)
        end
    else 
        tBase.Log("_SendClubCenterAsset  通知俱乐部同步总资产nClubId: %d nItemId:%d nClubGold: %f  sClubCenterKey is nil ",nClubId,nItemId,nClubGold) 
    end         
end

-- 俱乐部总资产 充值 
function ClubSink.ClubAssetRecharge(tData)  
    tBase.Log("_ClubAssetRecharge nUserId:%d sSerialNumber:%s sResultKey:%s ",tData.nUserId,tData.sSerialNumber,tData.sResultKey)
    local sSql =string.format("select UserID,Amount,ItemId,AssetType FROM Bill_Record WHERE id=%s",tData.sSerialNumber)
    local sFailSql =string.format('Call GSP_Bill_Fail("%s")',tData.sSerialNumber)

    local arrRows =AccountsDB_SqlExecute(sSql)
    tBase.LogT("_ClubAssetRecharge  arrRows: ",arrRows)
    if arrRows==nil or #arrRows~=1 then
        tBase.Log("_ClubAssetRecharge ERROR 21 sql:%s fail",sSql)
        SetWebRedisResulte(tData.sResultKey,{nRlt=21,sErr="sql ERROR"})
        AccountsDB_SqlExecute(sFailSql)
        return
    end
    local tRow =arrRows[1]
    local nClubId =tonumber(tRow.UserID) or 0
    local nAmount =tonumber(tRow.Amount)
    local nItemId = tonumber(tRow.ItemId) or 1      
    local nAssetType = tonumber(tRow.AssetType) or 1   -- 资产类型: 1 个人,其他资产
    
    --判断UserId是否正确
    if nClubId~=tData.nUserId then
        tBase.Log("_ClubAssetRecharge  UserId wrong:%d ~= %d",nClubId,tData.nUserId)
        SetWebRedisResulte(tData.sResultKey,{nRlt=22,sErr="UserId wrong"})
        AccountsDB_SqlExecute(sFailSql)
        return 
    end
    --如果是扣钱，先锁住同等数量金币
    local nLockGold =0
    if nAmount<0 and math.abs(nAmount) >1e-6 then
        nLockGold = -nAmount
    end
    local isLockSuccee,sErr =tPublicUserGold.Lock(nClubId,nLockGold,nItemId,nAssetType)
    if not isLockSuccee and sErr~="sKeyNotExist" then
        local nRlt = 24  --24 有锁金币导致 
        local tUserGold =tPublicUserGold.GetUserGoldInfo(nClubId,nItemId,nAssetType)
        if tUserGold and tUserGold.nFreezeGoldSum == 0 then 
            nRlt = 27   --  27，余额不足
        end 
        tBase.Log("_ClubAssetRecharge LockGold Fail,nClubId:%d nLockGold:%.2f sErr:%s  nRlt: %d(24:有锁金币导致,27:余额不足) nItemId: %d nAssetType: %d ",
        nClubId,nLockGold,sErr,nRlt,nItemId,nAssetType)
        SetWebRedisResulte(tData.sResultKey,{nRlt=nRlt,sErr="LockGold Fail"})
        AccountsDB_SqlExecute(sFailSql)
        return
    end
    
    --更新数据库 资产
    -- local sql =string.format('select ClubGold from DJH_AccountsDB.Club where ClubId = %d ',nClubId)
    -- local arrRows =AccountsDB_SqlExecute(sql) 
    -- tBase.LogT("_ClubAssetRecharge  查询数据:  "..sSql,arrRows)
    
    local sql =string.format('Call GSP_UpdateAssetGold("%s")',tData.sSerialNumber)
    local arrRows =AccountsDB_SqlExecute(sql) 
    tBase.LogT("_ClubAssetRecharge  arrRows: ",arrRows)
    if arrRows==nil or #arrRows ~=1 then
        tBase.Log("_ClubAssetRecharge  ERROR 25 sql:%s fail",sql)
        SetWebRedisResulte(tData.sResultKey,{nRlt=25,sErr="sql ERROR"})
        local isUnLockSuccee,sErr =tPublicUserGold.UnLock(nClubId,nLockGold,nItemId,nAssetType)
        if not isUnLockSuccee and sErr~="sKeyNotExist" then
            tBase.Log("_ClubAssetRecharge  ERROR 25 UnLock nClubId:%d nLockGold:%.2f fail,sErr:%s nItemId: %d %d ",nClubId,nLockGold,sErr,nItemId,nAssetType)
        end
        AccountsDB_SqlExecute(sFailSql)
        return
    end
    local tRow =arrRows[1]
    local nError =tonumber(tRow.Error)
    local nAmount =tonumber(tRow.Amounts) or 0
    local nNowAmounts =tonumber(tRow.NowAmounts) or 0 --玩家当前金币
    if nError ~=0 then
        tBase.Log("_ClubAssetRecharge GSP_UpdateAssetGold return fail,nError:%d",nError)
        SetWebRedisResulte(tData.sResultKey,{nRlt=26,sErr="GSP_UpdateGold return fail"})
        local isUnLockSuccee,sErr,nClubGold =tPublicUserGold.UnLock(nClubId,nLockGold,nItemId,nAssetType)
        if not isUnLockSuccee and sErr~="sKeyNotExist" then
            tBase.Log("_ClubAssetRecharge  ERROR 26 UnLock nClubId:%d nLockGold:%.2f fail,sErr:%s nItemId: %d nAssetType: %d %f ",nClubId,nLockGold,sErr,nItemId,nAssetType,nClubGold)
        end
        AccountsDB_SqlExecute(sFailSql)
        return
    else
        tBase.Log("_ClubAssetRecharge GSP_UpdateAssetGold Succee")
        SetWebRedisResulte(tData.sResultKey,{nRlt=0})
    end
    local nClubId =tonumber(tRow.nClubId) or 0
    local isSuccee,sErr,nClubGold =false,"",0
    if nLockGold~=0 then
        isSuccee,sErr,nClubGold =tPublicUserGold.UnLockAndMinus(nClubId,nLockGold,nItemId,nAssetType)
    else
        isSuccee,sErr,nClubGold =tPublicUserGold.Change(nClubId,nAmount,nItemId,nAssetType)
    end
    if not isSuccee then
        tBase.Log("_ClubAssetRecharge Warining chang gold to redis fail,but change to db,sErr:%s nItemId: %d nClubGold_%f ",sErr,nItemId,nClubGold)
        return
    else
        tBase.Log("_ClubAssetRecharge  Change Gold Succee nClubId: %d nItemId: %d nClubGold: %f  ",nClubId,nItemId,nClubGold)
    end

    SendClubCenterAsset(nClubId,nNowAmounts,nItemId) 
    return 1 
end

--  修改 俱乐部总资产 
function ClubSink.OnClubAssetChangeRsq(sReturnKey,Data,nLen)
    local strReq ="ClubAssetChangeRsq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = tData.sSql
    tBase.Log("_OnClubAssetChangeRsq sSql:%s",sSql)
    local arrRows =AccountsDB_SqlExecute(sSql)
    local row = arrRows[1]
    if row then
        local nRlt = tonumber(row.nRlt) or 99
        local nClubId = tonumber(row.nClubId) or 0
        local nNewClubGold = tonumber(row.nNewClubGold) or 0 
        local nItemId = tonumber(row.nItemId) or 0  
        if nRlt==0 then  -- 成功 
            tBase.Log("_OnClubAssetChangeRsq 修改俱乐部总资产 Success nClubId: %d nNewClubGold: %f %d ",nClubId,nNewClubGold,nRlt)
            SendClubCenterAsset(nClubId,nNewClubGold,nItemId)  
        else
            tBase.Log("_OnClubAssetChangeRsq 修改俱乐部总资产 ErrorMsg sSql:%s  nNewClubGold： %f nRlt: %d ",sSql,nNewClubGold,nRlt)
        end 
    end 
end 
 
--管理员操作 请求
function ClubSink.OnClubAdminOperateReq(sReturnKey,Data,nLen)
    local strReq ="ClubAdminOperateReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local nRlt = 0
    local tExtra = {}
    if tData.nType==1 then
        local nOpType = 7
        local sExtra = cjson.encode({nChange = tData.nChange})
        local sSql = string.format("call Club_SetOprationRecord(%d,%d,%d,%d,'%s')",tData.nClubId,nOpType,tData.nOpUserId,tData.nTUserId,sExtra)
        tBase.Log("OnClubAdminOperateReq sSql:%s",sSql)
        local arrRows = RecordDB_SqlExecute(sSql)
    elseif tData.nType==2 then
        local nOpType = 8
        local sExtra = cjson.encode({nChange = -tData.nChange})
        local sSql = string.format("call Club_SetOprationRecord(%d,%d,%d,%d,'%s')",tData.nClubId,nOpType,tData.nOpUserId,tData.nTUserId,sExtra)
        tBase.Log("OnClubAdminOperateReq sSql:%s",sSql)
        local arrRows = RecordDB_SqlExecute(sSql)
    elseif tData.nType==3 then
        local sSql = string.format("call Club_KickOutUser(%d,%d,%d)",tData.nClubId,tData.nOpUserId,tData.nTUserId)
        tBase.Log("OnClubAdminOperateReq sSql:%s",sSql)

        local arrRows =AccountsDB_SqlExecute(sSql)
        local row = arrRows[1] or {}
        nRlt = tonumber(row.ErrCode) or 99
        if nRlt==0 then
            local nUserCnt = tonumber(row.nUserCnt) or 0
            local nApplyAddGoldCnt = tonumber(row.nApplyAddGoldCnt) or 0
            local nApplyCutGoldCnt = tonumber(row.nApplyCutGoldCnt) or 0
            tBase.Log("KickOutUser Success nUserCnt:%d nApplyAddGoldCnt_%d nApplyCutGoldCnt_%d",nUserCnt,nApplyAddGoldCnt,nApplyCutGoldCnt)
            tExtra = {nUserCnt=nUserCnt,nApplyAddGoldCnt=nApplyAddGoldCnt,nApplyCutGoldCnt=nApplyCutGoldCnt}
        end
    end

    if nRlt==0 then
        local sSql1= string.format("call Club_WriteUserNotice(%d,%d,'%s')",tData.nTUserId,1,tData.sExData)
        tBase.Log("OnClubAdminOperateReq sSql1:%s",sSql1)
        local arrRows1 = RecordDB_SqlExecute(sSql1)
        local row1 = arrRows1[1]
        if tonumber(row1.ErrCode)==0 then
            local nNoticeId = tonumber(row1.nId) or 0
            local sSql2= string.format("call Club_GetUserNoticeInfo(%d)",nNoticeId)
            tBase.Log("OnClubAdminOperateReq sSql2:%s",sSql2)
            local arrRows2 = RecordDB_SqlExecute(sSql2)
            local row2 = arrRows2[1]
            if row2 then
                local tNoticesItem = {}
                tNoticesItem.nId = tonumber(row2.id) or 0
                tNoticesItem.nType = tonumber(row2.nType) or 0
                tNoticesItem.nStatus = tonumber(row2.nStatus) or 0
                tNoticesItem.sTime = row2.CreateTime or ""
                tNoticesItem.sData = row2.sData or ""
                tNoticesItem.nHadRead = 0
                tExtra.tNoticesItem = tNoticesItem
            end

            local sSql3= string.format("call Club_GetUserUnReadNoticesCnt(%d,%d)",tData.nTUserId,1)
            tBase.Log("OnClubAdminOperateReq sSql3:%s",sSql3)
            local arrRows3 = RecordDB_SqlExecute(sSql3)
            local row3 = arrRows3[1]
            if row3 then
                tExtra.nUnReadCnt = tonumber(row3.nUnReadCnt) or 0
            end
        end
    end

    local ClubAdminOperateRsp = {}
    ClubAdminOperateRsp.nRlt = nRlt
    ClubAdminOperateRsp.nTUserId = tData.nTUserId
    ClubAdminOperateRsp.nType = tData.nType
    ClubAdminOperateRsp.nOpUserId = tData.nOpUserId
    ClubAdminOperateRsp.nClubId = tData.nClubId
    ClubAdminOperateRsp.sExtra = cjson.encode(tExtra)
    DbClubSendToServer(sReturnKey,"ClubAdminOperateRsp",ClubAdminOperateRsp)
end

--俱乐部账户的俱乐部币流水 请求
function ClubSink.OnClubGoldChangeRecordReq(sReturnKey,Data,nLen)
    local strReq ="ClubGoldChangeRecordReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetClubGoldChangeRecord(%d,%d,%d)",tData.nClubId,tData.nIdOfStart,tData.nCnt)
    tBase.Log("OnClubGoldChangeRecordReq sSql:%s",sSql)

    local nAllCnt = 0
    local arrRecords = {}

    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local ClubGoldChangeRecordItem = {}
        ClubGoldChangeRecordItem.nId = tonumber(row.id) or 0
        ClubGoldChangeRecordItem.nUserId = tonumber(row.UserId) or 0
        ClubGoldChangeRecordItem.nChange = tonumber(row.nChange) or 0
        ClubGoldChangeRecordItem.sTime = row.CreateTime or ""
        ClubGoldChangeRecordItem.sName = row.sName or ""
        table.insert(arrRecords,ClubGoldChangeRecordItem)
        nAllCnt = tonumber(row.nAllCnt) or 0
    end

    local ClubGoldChangeRecordRsp = {}
    ClubGoldChangeRecordRsp.arrRecords = arrRecords
    ClubGoldChangeRecordRsp.nClubId = tData.nClubId
    ClubGoldChangeRecordRsp.nAllCnt = nAllCnt
    ClubGoldChangeRecordRsp.nUserId = tData.nUserId
    DbClubSendToServer(sReturnKey,"ClubGoldChangeRecordRsp",ClubGoldChangeRecordRsp)
end

-- 个人俱乐部币 
--个人俱乐部币增加退还 请求
function ClubSink.OnTransferClubGoldReq(sReturnKey,Data,nLen)
    local strReq ="TransferClubGoldReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = string.format("call Club_TransferClubGold(%d,%d,%d,%.2f,%d)",tData.nClubId,tData.nUserId,tData.nType,tData.nChange,tData.nLimitCnt)
    tBase.Log("OnTransferClubGoldReq sSql:%s",sSql)
    local arrRows = RecordDB_SqlExecute(sSql)
    local row = arrRows[1]
    local TransferClubGoldRsp = {}
    TransferClubGoldRsp.nRlt = tonumber(row.ErrCode) or 99
    TransferClubGoldRsp.nUserId = tData.nUserId
    TransferClubGoldRsp.nClubId = tData.nClubId
    TransferClubGoldRsp.nType = tData.nType
    TransferClubGoldRsp.nApplyCnt = tonumber(row.ApplyCnt) or 0

    -- tBase.Log("OnTransferClubGoldReq TransferClubGoldRsp:%s",cjson.encode(TransferClubGoldRsp))

    DbClubSendToServer(sReturnKey,"TransferClubGoldRsp",TransferClubGoldRsp)
end

--个人俱乐部币流水记录 请求
function ClubSink.OnTransferRecordReq(sReturnKey,Data,nLen)
    local strReq ="TransferRecordReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end

    local sSql = string.format("call Club_GetUserTransferRecord(%d,%d,%d,%d)",tData.nClubId,tData.nUserId,tData.nIdOfStart,tData.nCnt)
    tBase.Log("OnTransferRecordReq sSql:%s",sSql)

    local nAllCnt = 0
    local arrRecords = {}

    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local tClubTransferRecordItem = {}
        tClubTransferRecordItem.nId = tonumber(row.id) or 0
        tClubTransferRecordItem.nChange = tonumber(row.nChange) or 0
        tClubTransferRecordItem.nClubGold = tonumber(row.NewUserGold) or 0
        tClubTransferRecordItem.sTime = row.CreateTime or ''
        tClubTransferRecordItem.nSourceType = tonumber(row.SourceType) or 0
        nAllCnt = tonumber(row.AllCnt) or 0
        table.insert(arrRecords,tClubTransferRecordItem)
    end
    local TransferRecordRsp = {}
    TransferRecordRsp.arrRecords = arrRecords
    TransferRecordRsp.nClubId = tData.nClubId
    TransferRecordRsp.nAllCnt = nAllCnt
    TransferRecordRsp.nUserId = tData.nUserId
    DbClubSendToServer(sReturnKey,"TransferRecordRsp",TransferRecordRsp)
end

--加载商城配置
function ClubSink.OnLoadStoreConfigReq(sReturnKey,Data,nLen)
    local strReq ="LoadStoreConfigReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local function Load_GiftBag_Config()
        local sSql = "call Load_Config_GiftBag()" 
        local arrRows = PlatformDB_SqlExecute(sSql,true)
        if arrRows then             
            local arr = {}
            for k,row in pairs(arrRows) do 
                local nGiftBagId = tonumber(row.GiftBagId)   
                local t = {}
                t.nItemId = tonumber(row.ItemId)  
                t.nCount = tonumber(row.Count)   
                t.sGiftBagName = row.GiftBagName                 
                if not arr[nGiftBagId] then 
                    arr[nGiftBagId] = {}
                end             
                table.insert(arr[nGiftBagId],t)                
            end 
            local nCnt =  0
            for nGiftBagId,arrItem in pairs(arr) do
                nCnt = nCnt + 1
                -- tBase.Log("OnLoadStoreConfigReq  加载礼包配置  nGiftBagId_%d  arrItem_%d nCnt_%d",nGiftBagId,#arrItem,nCnt)
            end 
            local arrGiftBagConfig = {}
            local nGiftCnt = 0
            for nGiftBagId,arrItem in pairs(arr) do
                local t={}
                t.nGiftBagId = nGiftBagId
                t.arrItem = arrItem
                nGiftCnt = nGiftCnt + 1 
                table.insert(arrGiftBagConfig,t)
                if #arrGiftBagConfig >= 200 or nGiftCnt == nCnt then 
                    local LoadStoreConfigRep = {}
                    LoadStoreConfigRep.arrStoreConfig =  {}
                    LoadStoreConfigRep.arrGiftBagConfig = arrGiftBagConfig
                    DbClubSendToServer(sReturnKey,"LoadStoreConfigRep",LoadStoreConfigRep)    
                    arrGiftBagConfig = {}
                end
            end 
            tBase.Log("OnLoadStoreConfigReq  加载礼包配置  nGiftCnt_%d  arrRows_%d nCnt_%d",nGiftCnt,#arrRows,nCnt)
        end 
    end 

    local function Load_Store_Config()
        local sSql = "call Load_Config_Store()" 
        local arrRows = PlatformDB_SqlExecute(sSql,true)
        local arrStoreConfig = {}
        local nStoreCnt = 0 
        if arrRows then 
            for k,row in pairs(arrRows) do
                local t = {}
                t.nGoodId = tonumber(row.GoodId) 
                t.nPayType = tonumber(row.PayType) 
                t.nPayCount = tonumber(row.PayCount) 
                t.nGiftBagId = tonumber(row.GiftBagId) 
                t.nLimitStatus = tonumber(row.LimitStatus)     
                t.sLimitStart = row.LimitStart
                t.sLimitEnd =  row.LimitEnd
                t.nGroupId = tonumber(row.GroupId)
                t.sGoodName = row.GoodName   
                t.nDisplaySort = tonumber(row.DisplaySort)
                table.insert(arrStoreConfig,t)
                if #arrStoreConfig >= 50 or #arrRows == k then   -- 分包下发
                    local LoadStoreConfigRep = {}
                    LoadStoreConfigRep.arrStoreConfig =  arrStoreConfig
                    LoadStoreConfigRep.arrGiftBagConfig = {}
                    DbClubSendToServer(sReturnKey,"LoadStoreConfigRep",LoadStoreConfigRep)    
                    arrStoreConfig = {}
                end        
                nStoreCnt = nStoreCnt + 1 
            end 
            tBase.Log("OnLoadStoreConfigReq  加载商城配置  nStoreCnt_%d ",nStoreCnt) 
        end 
    end 
    
    Load_GiftBag_Config()
    
    Load_Store_Config()

end 

--创建订单
function ClubSink.OnPayOrder_CreateReq(sReturnKey,Data,nLen)
    local strReq ="PayOrder_CreateReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local nUserId = tData.nUserId     
    local arrRow = AccountsDB_SqlExecute(tData.sSql)
    local row = arrRow[1]
    local nFlag = tonumber(row.nFlag)
    local nId = -1
    local tExData = {}
    local isSuccee = false
    if nFlag == 0 then 
        nId = tonumber(row.nId)
        local sOrderid = row.sOrderid or ""
        isSuccee,tExData = pcall(cjson.decode,tData.sExData)
        if not isSuccee then
            tExData = {}
        end
        tExData.sOrderid = sOrderid
    else        
        local SendSMS = string.format("创建订单失败,nUserId_%d sSql:%s  ",nUserId,tData.sSql)
        tBase._OnMonitorInfo(SendSMS)        
    end 
    local PayOrder_CreateRep ={}
    PayOrder_CreateRep.nUserId = nUserId
    PayOrder_CreateRep.nFlag = nFlag
    PayOrder_CreateRep.nId = nId
    PayOrder_CreateRep.sExData = cjson.encode(tExData)  
    DbClubSendToServer(sReturnKey,"PayOrder_CreateRep",PayOrder_CreateRep) 
    tBase.Log("OnPayOrder_CreateReq   创建订单  nUserId: %d  nId_%d nFlag_%d   sSql: %s",nUserId,nId,nFlag,tData.sSql)
end 
 
--处理订单
function ClubSink.OnPayOrder_DealReq(sReturnKey,Data,nLen)
    local strReq ="PayOrder_DealReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"OnPayOrder_DealReq Err happen ,Parse error strReq:"..strReq)
        return
    end
    local nType = tData.nType  
    if nType == 2 then   --购买记录
        local nUserId = tData.nId    
        local arrRow = RecordDB_SqlExecute(tData.sSql)  
        tBase.Log("OnPayOrder_DealReq   购买记录  nUserId: %d sSql: %s",nUserId,tData.sSql)   
        return 
    end 
    local nId = tData.nId     
    local arrRow = AccountsDB_SqlExecute(tData.sSql)
    local row = arrRow[1]
    local nFlag = tonumber(row.nFlag)  -- 状态 0:未支付,2:已给道具,3支付取消,4支付失败,5重复使用过的苹果订单无效的订单
    local nUserId = tonumber(row.nUserId)
    local nGoodId = tonumber(row.nGoodId) 
    if nFlag ~= 1 then 
        local tStatus ={[2] = "已给道具",[3] = "支付取消",[4] = "支付失败",[5] = "重复使用过的苹果订单无效的订单"}
        local sStatus = tStatus[nFlag] or "未支付"
        local SendSMS = string.format("处理订单失败,nUserId_%d nOrderId_%d sStatus_%s sSql:%s  ",nUserId,nId,sStatus,tData.sSql)
        tBase._OnMonitorInfo(SendSMS)       
        tBase.Log(SendSMS)         
    end 
    local PayOrder_DealRep ={}
    PayOrder_DealRep.nUserId = nUserId
    PayOrder_DealRep.nId = nId  
    PayOrder_DealRep.nFlag = nFlag
    PayOrder_DealRep.nGoodId = nGoodId  
    DbClubSendToServer(sReturnKey,"PayOrder_DealRep",PayOrder_DealRep) 
    tBase.Log("OnPayOrder_DealReq   处理订单  nUserId: %d nId_%d nGoodId_%d nFlag_%d  sSql: %s",nUserId,nId,nGoodId,nFlag,tData.sSql)    
    return 
end 

function ClubSink.OnClubNotifyRecordReq(sReturnKey,Data,nLen)
    local strReq ="ClubNotifyRecordReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"ClubNotifyRecordReq Err happen ,Parse error strReq:"..strReq)
        return
    end
    local nExData = {}
    nExData.resType = tData.nType
    local exData = cjson.encode(nExData)
    local sSql1= string.format("call Club_WriteUserNotice(%d,%d,'%s')",tData.nUserId,1,exData)
    tBase.Log("ClubNotifyRecordReq sSql1:%s",sSql1)
    RecordDB_SqlExecute(sSql1)

    local ClubNotifyRecordRsp = {}
    ClubNotifyRecordRsp.nUserId = tData.nUserId
    ClubNotifyRecordRsp.nType = tData.nType
    DbClubSendToServer(sReturnKey,"ClubNotifyRecordRsp",ClubNotifyRecordRsp)
end

--是否可以签到
local function isCanSignToday(nUserId)
    local connection =dbSink.GetDbConnectForRead("DJH_RecordDB")
    local sTimeZone,nGroupId =SetTimeZone(connection,nUserId)  --设置使用的时区
    local sql =string.format("call ClubSignInfoRead(%d)",nUserId)
    local arrRows= SqlExecut(sql,connection)
    local tRow =arrRows[1]
    assert(tRow~=nil)
    local isSign =(tonumber(tRow.nIsSign)==1)
    local nDaysCur =tonumber(tRow.nDaysCur)
    local nPlayToday =tonumber(tRow.nPlayToday)
    local nPlayCntMax =tonumber(tRow.nPlayCntMax)
    return (isSign==false and nPlayToday>=nPlayCntMax)
end
--获取绑定手机的状态
local function GetBindPhoneAward(nUserId)
    local connection =dbSink.GetDbConnectForRead("DJH_RecordDB")
    local sql =string.format("select BindPhoneAward(%d) as award;",nUserId)
    local arrRows= SqlExecut(sql,connection)
    local tRow =arrRows[1] or {award=-100}
    assert(tRow~=nil)
    local nAward =tonumber(tRow.award) or -101
    return nAward       -- 0:可领取(红点) 1:已领取 2:审核中 3:审核不通过 4:未申请过绑定 -10:错误
end
 
--获取活动信息
function ClubSink.OnClubGetActiInfoReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetActiInfoReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"ClubNotifyRecordReq Err happen ,Parse error strReq:"..strReq)
        return
    end

    local arrActiInfo = {}

    local sSql = string.format("call ActivityAward_GetByType(%d,%d)",tData.nUserId,tData.nActivityType)
    tBase.Log("OnClubGetActiInfoReq sSql:%s",sSql)
    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in ipairs(arrRows) do
        local ActiInfo = {}
        ActiInfo.nId = tonumber(row.Id) or 0
        ActiInfo.nActivityType = tonumber(row.ActivityType) or 0
        ActiInfo.nAwardCount = tonumber(row.AwardCount) or 0
        ActiInfo.nGetStatus = tonumber(row.GetStatus) or -1
        ActiInfo.nAging = tonumber(row.Aging) or 0
        ActiInfo.sCreateTime = row.CreateTime or ""
        ActiInfo.sExpand = row.Expand or ""
        ActiInfo.sGetTime = row.GetTime or ""
        table.insert(arrActiInfo,ActiInfo)
    end

    --签到活动
    if tData.nActivityType==3 or tData.nActivityType==0 then
        local ActiInfo = {}
        ActiInfo.nId = 0
        ActiInfo.nActivityType = 3
        ActiInfo.nAwardCount = 0
        ActiInfo.nGetStatus = isCanSignToday(tData.nUserId) and 0 or 1  --0:有红点 1:没红点
        ActiInfo.nAging = 0
        ActiInfo.sCreateTime = ""
        ActiInfo.sExpand =""
        ActiInfo.sGetTime =""
        table.insert(arrActiInfo,ActiInfo)
        tBase.Log("IsSign %d nGetStatus:%d",tData.nUserId,ActiInfo.nGetStatus)
    end
    --绑定手机活动
    if tData.nActivityType==5 or tData.nActivityType==0 then
        local nWard= GetBindPhoneAward(tData.nUserId)     -- 0:可领取(红点) 1:已领取 2:审核中 3:审核不通过 4:未申请过绑定 -10:错误
        if nWard>=0 and  nWard<=3 then
            local ActiInfo = {}
            ActiInfo.nId = 0
            ActiInfo.nActivityType = 5
            ActiInfo.nAwardCount =200                        --这字段当前没意义
            ActiInfo.nGetStatus = nWard                      --0:没领取(红点) 1:已领取 2:审核中 3:审核不通过
            ActiInfo.nAging = 0
            ActiInfo.sCreateTime = ""
            ActiInfo.sExpand =""
            ActiInfo.sGetTime =""
            table.insert(arrActiInfo,ActiInfo)
        end
        tBase.Log("BindPhoneSS %d nWard:%d",tData.nUserId,nWard)
    end

    local ClubGetActiInfoRsp = {}
    ClubGetActiInfoRsp.nUserId = tData.nUserId
    ClubGetActiInfoRsp.arrActiInfos = arrActiInfo
    DbClubSendToServer(sReturnKey,"ClubGetActiInfoRsp",ClubGetActiInfoRsp)
end

-- 领取活动奖励 
function ClubSink.OnClubActivityAwardGrantReq(sReturnKey,Data,nLen)
    local strReq ="ClubActivityAwardGrantReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end 
    local arrRows =RecordDB_SqlExecute(tData.sSql)
    local nActivityId = -1
    local nAwardCount = 0
    local row = arrRows[1]
    if row then
        nActivityId = tonumber(row.nActivityId) or -1         -- 结果: -1失败、大于0 其他成功 
    end 
    tBase.Log("_OnClubActivityHandleReq nRequest_%d  nActivityId_%d  sSql: %s"
    ,tData.nRequest,nAwardCount,nActivityId,tData.sSql)

    local ClubActivityAwardGrantRsp = {}
    ClubActivityAwardGrantRsp.nRequest = tData.nRequest 
    ClubActivityAwardGrantRsp.nActivityId = nActivityId  
    DbClubSendToServer(sReturnKey,"ClubActivityAwardGrantRsp",ClubActivityAwardGrantRsp)
end

-- 领取活动奖励 
function ClubSink.OnClubActivityHandleReq(sReturnKey,Data,nLen)
    local strReq ="ClubActivityHandleReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local arrRows =RecordDB_SqlExecute(tData.sSql)
    local nRlt = -1
    local nJushu = 0
    local nActivityType = -1
    local nAwardCount = 0 
    local row = arrRows[1]
    if row then
        nRlt = tonumber(row.nRlt) or -1         -- 结果: 1成功、-1失败 -2已领取、-3无数据 -4未达到局数
        nJushu = tonumber(row.nJushu)
        if nRlt == 1 then
            nAwardCount = tonumber(row.nAwardCount) 
        end
        nActivityType = tonumber(row.nActivityType)  
    end 
    tBase.Log("_OnClubActivityHandleReq nRequest_%d ActivityType_%d  nAwardCount_%f nRlt_%d  sSql: %s"
    ,tData.nRequest,nActivityType,nAwardCount,nRlt,tData.sSql)

    local ClubActivityHandleRsp = {}
    ClubActivityHandleRsp.nRequest = tData.nRequest 
    ClubActivityHandleRsp.nUserId = tData.nUserId
    ClubActivityHandleRsp.nRlt = nRlt
    ClubActivityHandleRsp.nActivityType = nActivityType
    ClubActivityHandleRsp.nAwardCount = nAwardCount
    ClubActivityHandleRsp.nJushu = nJushu
    DbClubSendToServer(sReturnKey,"ClubActivityHandleRsp",ClubActivityHandleRsp)
end

-- 活动公共操作 
function ClubSink.OnClubActivityPublicReq(sReturnKey,Data,nLen)
    local strReq ="ClubActivityPublicReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end 
    local arrRows =RecordDB_SqlExecute(tData.sSql)  
    if arrRows and arrRows[1] and arrRows[1].ErrorCode and arrRows[1].ErrorInfo then
        return 
    end 
    tBase.Log("_OnClubActivityPublicReq nRequest_%d  sSql: %s",tData.nRequest,tData.sSql)
    if tData.nRequest == 0 then  -- 无需回调
        tBase.Log("_OnClubActivityPublicReq 无需回调  %s  ",cjson.encode(arrRows))
        return  
    end 
    local ClubActivityPublicRsp = {}
    ClubActivityPublicRsp.nRequest = tData.nRequest 
    ClubActivityPublicRsp.sArrRows = cjson.encode(arrRows)  
    DbClubSendToServer(sReturnKey,"ClubActivityPublicRsp",ClubActivityPublicRsp)
end

-- 推荐操作请求 
function ClubSink.OnClubRecommendHandleReq(sReturnKey,Data,nLen)
    local strReq ="ClubRecommendHandleReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end 
    local arrRows =RecordDB_SqlExecute(tData.sSql)  
    if arrRows and arrRows[1] and arrRows[1].ErrorCode and arrRows[1].ErrorInfo then
        return 
    end 
    local t = cjson.decode(tData.sJson)
    if tData.nHandle == 1 then 
        if not arrRows then 
            tBase.Log("_OnClubRecommendHandleReq  无推荐人 sSql: %s",tData.sSql)
            return 
        end 
        local nRecommendId
        local nRecommendCnt
        local row = arrRows[1]
        if row then
            nRecommendId = tonumber(row.nRecommendId)           --  推荐人ID
            nRecommendCnt = tonumber(row.nRecommendCnt)         --  推荐数量
            t.nRecommendId = nRecommendId
            t.nRecommendCnt = nRecommendCnt
            tBase.Log("_OnClubRecommendHandleReq  nRecommendId_%d nRecommendCnt_%d  sSql: %s",nRecommendId,nRecommendCnt,tData.sSql)
        else
            tBase.Log("_OnClubRecommendHandleReq  无推荐人 sSql: %s",tData.sSql)
            return 
        end 
    end 
    tBase.Log("_OnClubRecommendHandleReq  %s sSql: %s",cjson.encode(t),tData.sSql)
 
    local ClubRecommendHandleRsp = {}
    ClubRecommendHandleRsp.nHandle = tData.nHandle 
    ClubRecommendHandleRsp.sJson = cjson.encode(t)  
    DbClubSendToServer(sReturnKey,"ClubRecommendHandleRsp",ClubRecommendHandleRsp)
end

-- 写审核数据请求 
function ClubSink.OnClubActivityReviewDataReq(sReturnKey,Data,nLen)
    local strReq ="ClubActivityReviewDataReq"
    local tData =DbClubProtoParse(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local arrRows = RecordDB_SqlExecute(tData.sSql)
    local row = arrRows[1]
    local nRlt = tonumber(row.ErrCode)
    tBase.Log("_OnClubActivityReviewDataReq sSql: %s",tData.sSql)

    local ClubActivityReviewDataRsp = {}
    ClubActivityReviewDataRsp.nUserId = tData.nUserId
    ClubActivityReviewDataRsp.nRlt = nRlt

    DbClubSendToServer(sReturnKey,"ClubActivityReviewDataRsp",ClubActivityReviewDataRsp)
end


-- 获取活动列表
function ClubSink.OnClubGetActivityListReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetActivityListReq"
    local tData =DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen, Parse error strReq:"..strReq)
        return
    end

    local arrRecords = {}
    local nGroupId = tPubUsrApi.Get_User_GroupId(tData.nUserId)
    local sSql = string.format("call Load_ActivityList(%d)", nGroupId)
    tBase.Log("ClubGetActivityListReq sSql:%s", sSql)
    local arrRows =PlatformDB_SqlExecute(sSql, true)
    for _, row in pairs(arrRows) do
        local tRecord = {}
        tRecord.nActId = tonumber(row.nActId)
        tRecord.nName = row.nName or ""
        tRecord.nSort = tonumber(row.nSort) or 0
        tRecord.nStartTime = row.nStartTime or ""
        tRecord.nEndTime = row.nEndTime or ""
        tRecord.nConfig = row.nConfig or ""
        tRecord.nBaseConfig = row.nBaseConfig or ""
        tRecord.nImage = row.nImage or ""
        tRecord.nRecharge = tonumber(row.nRecharge) or 0
        tRecord.nTitle = row.nTitle or ""
        table.insert(arrRecords, tRecord)
    end

    local ClubGetActivityListRsp = {}
    ClubGetActivityListRsp.arrRecords = arrRecords
    ClubGetActivityListRsp.nUserId = tData.nUserId
    DbClub1SendToServer(sReturnKey, "ClubGetActivityListRsp", ClubGetActivityListRsp)
end

--大厅信息统计
function ClubSink.OnClubGetPersonTableStaticReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetPersonTableStaticReq"
    local tData =DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local tStatics = nil
    if tApi.IsTexasClassGame(tData.nGameId) then --德州，奥马哈，短牌
        local sSql1 = string.format("call Club_GetTexaStatistic(%d,%d,%d,%d)",tData.nUserId,tData.nGameId,tData.nGoldType,tData.nClubId)
        tBase.Log("ClubGetPersonTableStaticReq sSql1:%s",sSql1)
        local arrRows1 =RecordDB_SqlExecute(sSql1,true)
        local row1 = arrRows1[1]
        if row1 then
            tStatics ={}
            tStatics.nPaiJuCnt=tonumber(row1.PaiJuCnt) or 0
            tStatics.nPlayCount=tonumber(row1.PlayCount) or 0
            tStatics.nProfitSum=tonumber(row1.ProfitSum)  or 0
            tStatics.nInPoolCount=tonumber(row1.InPoolCount)  or 0
            tStatics.nRaiseCountBFlop=tonumber(row1.RaiseCountBFlop) or 0
            tStatics.nAllInAndWinCount=tonumber(row1.AllInAndWinCount) or 0
            tStatics.nWinCount=tonumber(row1.WinCount) or 0
            tStatics.nQiPaiCount=tonumber(row1.ReachShowdown) or 0
            tStatics.nHandProfit=tonumber(row1.HandProfit) or 0
            tStatics.nAllInCount = tonumber(row1.AllInCount) or 0
        end
    end
    local ClubGetPersonTableStaticRsp = {}
    ClubGetPersonTableStaticRsp.tStatics = tStatics
    ClubGetPersonTableStaticRsp.nGameId = tData.nGameId
    ClubGetPersonTableStaticRsp.nUserId = tData.nUserId
    ClubGetPersonTableStaticRsp.nClubId = tData.nClubId
    ClubGetPersonTableStaticRsp.nGoldType = tData.nGoldType
    tBase.LogT(ClubGetPersonTableStaticRsp)
    DbClub1SendToServer(sReturnKey,"ClubGetPersonTableStaticRsp",ClubGetPersonTableStaticRsp)
end

--账变记录
function ClubSink.OnClubGetGoldHistoryReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetGoldHistoryReq"
    local tData =DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = string.format("call Club_GetUserTransferRecord_All(%d,%d,%d,'%s','%s','%s')",tData.nUserId,tData.nIdOfStart,tData.nCnt,tData.nStartTime,tData.nEndTime,"(10006,10007,10008)")
    tBase.Log("OnClubGetGoldHistoryReq sSql:%s",sSql)

    local nAllCnt = 0
    local arrRecords = {}

    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local tClubTransferRecordItem = {}
        tClubTransferRecordItem.nId = tonumber(row.id) or 0
        tClubTransferRecordItem.nChange = tonumber(row.nChange) or 0
        tClubTransferRecordItem.nClubGold = tonumber(row.NewUserGold) or 0
        tClubTransferRecordItem.sTime = row.CreateTime or ''
        tClubTransferRecordItem.nSourceType = tonumber(row.SourceType) or 0
        nAllCnt = tonumber(row.AllCnt) or 0
        table.insert(arrRecords,tClubTransferRecordItem)
    end
    local ClubGetGoldHistoryRsp = {}
    ClubGetGoldHistoryRsp.arrRecord = arrRecords
    ClubGetGoldHistoryRsp.nIdOfStart = tData.nIdOfStart
    ClubGetGoldHistoryRsp.nAllCnt = nAllCnt
    ClubGetGoldHistoryRsp.nStartTime = tData.nStartTime
    ClubGetGoldHistoryRsp.nEndTime = tData.nEndTime
    DbClub1SendToServer(sReturnKey,"ClubGetGoldHistoryRsp",ClubGetGoldHistoryRsp)
end

--局内消耗
function ClubSink.OnClubGetGameGoldReq(sReturnKey,Data,nLen)
    local strReq ="ClubGetGameGoldReq"
    local tData =DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = string.format("call Club_GetPaiJuWinLoseRecord(%d,%d,%d,'%s','%s')",tData.nUserId,tData.nIdOfStart,tData.nCnt,tData.nStartTime,tData.nEndTime)
    tBase.Log("OnClubGetGameGoldReq sSql:%s",sSql)

    local nAllCnt = 0
    local arrRecords = {}

    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        local tGameGoldItem = {}
        tGameGoldItem.nId = tonumber(row.id) or 0
        tGameGoldItem.nChange = tonumber(row.nChange) or 0
        tGameGoldItem.sTableId = row.TableId or ''
        tGameGoldItem.sTableName = row.TableName or ''
        tGameGoldItem.sTime = row.CreatetTime or ''
        tGameGoldItem.nGameId = tonumber(row.GameType) or 0
        tGameGoldItem.nGoldType = tonumber(row.GoldType) or 0
        tGameGoldItem.sPaiJuId = row.PaiJuId or ''
        nAllCnt = tonumber(row.AllCnt) or 0
        table.insert(arrRecords,tGameGoldItem)
    end
    local ClubGetGameGoldRsp = {}
    ClubGetGameGoldRsp.arrRecord = arrRecords
    ClubGetGameGoldRsp.nIdOfStart = tData.nIdOfStart
    ClubGetGameGoldRsp.nAllCnt = nAllCnt
    ClubGetGameGoldRsp.nStartTime = tData.nStartTime
    ClubGetGameGoldRsp.nEndTime = tData.nEndTime
    ClubGetGameGoldRsp.nUserId = tData.nUserId
    DbClub1SendToServer(sReturnKey,"ClubGetGameGoldRsp",ClubGetGameGoldRsp)
end

--局内消耗详情
function ClubSink.OnClubGetGameGoldDetailReq(sReturnKey,Data,nLen)
    tBase.Log("OnClubGetGameGoldDetailReq")
    local strReq ="ClubGetGameGoldDetailReq"
    local tData =DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = string.format("call Club_GetPaiJuCostRecord('%s','%s','%s',%d)",tData.sTableId,tData.sPaiJuId,tData.nStartTime,tData.nUserId)
    tBase.Log("OnClubGetGameGoldDetailReq sSql:%s",sSql)

    local arrRecords = {}

    local arrRows = RecordDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        if row.id and tonumber(row.id) > 0 then
            local tGameGoldItem = {}
            tGameGoldItem.nId = tonumber(row.id) or 0
            tGameGoldItem.nChange = tonumber(row.Change) or 0
            tGameGoldItem.sTime = row.STime or ''
            tGameGoldItem.nSourceType = tonumber(row.SourceType) or 0
            table.insert(arrRecords,tGameGoldItem)
        end
    end
    local ClubGetGameGoldDetailRsp = {}
    ClubGetGameGoldDetailRsp.arrRecord = arrRecords
    ClubGetGameGoldDetailRsp.nUserId = tData.nUserId
    DbClub1SendToServer(sReturnKey,"ClubGetGameGoldDetailRsp",ClubGetGameGoldDetailRsp)
end

local function isPlayerInLookData(lookData, playerId)
    if not lookData or lookData == "" then
        return false
    end
    -- 将玩家ID转为字符串
    local idStr = tostring(playerId)
    -- 使用模式匹配查找，确保完全匹配
    return string.find("," .. lookData .. ",", "," .. idStr .. ",") ~= nil
end

--Hash指定局牌序列请求
function ClubSink.OnClubGetHashListReq(sReturnKey, Data, nLen)
    -- tBase.Log("OnClubGetHashListReq")
    local strReq ="ClubGetHashListReq"
    local tData = DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        tBase.Log("Err happen ,Parse error  strReq:"..strReq)
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    tBase.Log("OnClubGetHashListReq sTableId::%s sPaiJuId:%s", tData.sTableId, tData.sPaiJuId)
    local sql = string.format("CALL PaiJuHashRecord_get('%s','%s')", tData.sTableId, tData.sPaiJuId)
    local arrRows = RecordDB_SqlExecute(sql, true)
    tBase.LogT(arrRows)
    arrRows1 = arrRows and arrRows[1] or {}
    local lookData = arrRows1.LookData or ""
    local isLook = isPlayerInLookData(lookData, tostring(math.floor(tData.nUserId)))
    tBase.Log("nUserId:%s isLook:%s", tostring(math.floor(tData.nUserId)), tostring(isLook))
    local item = {}
    item.nCards = ""
    item.nDetail = ""
    item.seed = arrRows1.Seed or ""
    item.nPlayCnt = tonumber(arrRows1.Hand) or 0
    item.show = tonumber(arrRows1.IsShow) or 0
    if isLook then
        item.show = 1
    end
    item.sPaiJuId = arrRows1.PaiJuId or ""
    item.sTime = arrRows1.STime or ""
    item.hash = arrRows1.HashVal or ""
    item.cards = arrRows1.CardHash or ""
    item.fTime = arrRows1.fTime or ""
    if item.show == 1 then
        item.nCards = arrRows1.Cards or ""
        item.nDetail = arrRows1.ExData or ""
    end

    local ClubGetHashListRsp = {}
    ClubGetHashListRsp.nUserId = tData.nUserId
    ClubGetHashListRsp.item = item
    DbClub1SendToServer(sReturnKey,"ClubGetHashListRsp",ClubGetHashListRsp)
end

--Hash指定局牌序列请求
function ClubSink.OnClubGetHashCardReq(sReturnKey, Data, nLen)
    local strReq ="ClubGetHashCardReq"
    local tData = DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        tBase.Log("Err happen ,Parse error  strReq:"..strReq)
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    -- tBase.Log("OnClubGetHashCardReq sTableId::%s sPaiJuId:%s nUserId:%d", tData.sTableId, tData.sPaiJuId, tData.nUserId)
    local sql = string.format("CALL PaiJuHashRecord_get('%s','%s')", tData.sTableId, tData.sPaiJuId)
    local arrRows = RecordDB_SqlExecute(sql, true)
    tBase.LogT(arrRows)
    arrRows1 = arrRows and arrRows[1] or {}
    local lookData = arrRows1.LookData or ""
    local isLook = isPlayerInLookData(lookData, tostring(math.floor(tData.nUserId)))
    tBase.Log("nUserId:%s isLook:%s", tostring(math.floor(tData.nUserId)), tostring(isLook))
    local item = {}
    item.nCards = ""
    item.nDetail = ""
    item.nIsShow = tonumber(arrRows1.IsShow) or 0
    local ClubGetHashCardRsp = {}
    ClubGetHashCardRsp.nRlt = 0
    ClubGetHashCardRsp.nUserId = tData.nUserId
    if isLook then
        item.nIsShow = 1
    end
    if item.nIsShow == 1 then
        item.nCards = arrRows1.Cards or ""
        item.nDetail = arrRows1.ExData or ""
    else
        if not isLook then
            local ok = tPubUsrApi.ChangeUserTreasure({
                nUserID = tData.nUserId,
                nItemID = 1,
                nDel = -0.1,
                nSourceType = 100009,
            })
            if not ok then
                tBase.Log("OnClubGetHashCardReq error sTableId::%s sPaiJuId:%s nUserId:%d", tData.sTableId, tData.sPaiJuId, tData.nUserId)
                ClubGetHashCardRsp.nRlt = 1
            else
                local sql1 = string.format("call PaiJuHashRecord_Update(%d,'%s')", tData.nUserId, tData.sPaiJuId)
                RecordDB_SqlExecute(sql1, false)
            end
        end
    end
    ClubGetHashCardRsp.nCards = item.nCards
    ClubGetHashCardRsp.nDetail = item.nDetail
    DbClub1SendToServer(sReturnKey,"ClubGetHashCardRsp",ClubGetHashCardRsp)
end

--更新牌局hash
function ClubSink.OnDbPaiJuHashRecordUpdateReq(sReturnKey, Data, nLen)
    tBase.Log("OnDbPaiJuHashRecordUpdateReq")
    local strReq ="DbPaiJuHashRecordUpdateReq"
    local tData = DbProtoParse1(Data, nLen,strReq)
    if not tData then
        tBase.Log("Err happen ,Parse error  strReq:"..strReq)
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sql = tData.sSql
    tBase.Log("OnDbPaiJuHashRecordUpdateReq sSql:"..tData.sSql)
    local arrRows = RecordDB_SqlExecute(sql, false)
    tBase.LogT(arrRows)
    -- DbSendToServer1(sReturnKey,"ServerGroupRelationRsp",ServerGroupRelationRsp)
end

--内部转币
function ClubSink.OnClubGoldTransUserReq(sReturnKey, Data, nLen)
    local strReq ="ClubGoldTransUserReq"
    local tData = DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        tBase.Log("Err happen ,Parse error  strReq:"..strReq)
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    tBase.Log("OnClubGoldTransUserReq nUserId:%d nAmount:%.2f nTUserId:%d", tData.nUserId, tData.nAmount, tData.nTUserId)
    local rsp = {}
    rsp.nRlt = 0
    rsp.nUserId = tData.nUserId

    local nGold = tData.nAmount
    local nItemId = 1
    local nSourceType = 100006  -- 内部转账
    local nChannel = -1
    local nRoomId = -1

    local ok1 = tPubUsrApi.ChangeUserTreasure({
        nUserID = tData.nUserId,
        nItemID = nItemId,
        nDel = -nGold,
        nSourceType = nSourceType,
        nNoNotice = true,
    })
    if not ok1 then
        tBase.Log("OnClubGoldTransUserReq not ok1")
        ClubGoldTransUserRsp.nRlt = 2
        DbClub1SendToServer(sReturnKey, "ClubGoldTransUserRsp", rsp)
        return
    end
    -- 加钱（接收方）
    local ok2 = false
    repeat
        local tUser = tPubUsrApi.GetUserInfo(tData.nTUserId) or {}
        if next(tUser) == nil then -- 离线玩家操作
            tBase.Log("OnClubGoldTransUserReq nTUserId:%d offlin", tData.nTUserId)
            local sql = string.format("select * from Accounts_Treasure where UserID = %d and ItemID = 1", tData.nTUserId)
            local arrRows =AccountsDB_SqlExecute(sql)
            tBase.LogT(arrRows)
            if arrRows==nil or #arrRows ~=1 then
                tBase.Log("OnClubGoldTransUserReq  ERROR 25 sql:%s fail",sql)
                break
            end
            local tRow = arrRows[1]
            local nNowAmounts =tonumber(tRow.Count) or 0 --玩家当前金币
            tBase.Log("OnClubGoldTransUserReq nTUserId:%d nNowAmounts:%.2f",tData.nTUserId,nNowAmounts)
            local sSql =string.format("Call WriteUserTreasure2(%d,%d,%d,%.3f,%d,%d,'%s',%d)",tData.nTUserId,nChannel,nItemId,nGold,100007,nRoomId,"",tData.nUserId)
            arrRows = AccountsDB_SqlExecute(sSql)
            tBase.LogT(arrRows)
            if arrRows == nil or #arrRows ~=1 then
                tBase.Log("OnClubGoldTransUserReq  ERROR 26 sql:%s fail",sql)
                break
            end
            tRow = arrRows[1]
            local nResult = tonumber(tRow.Result)
            if nResult ~= -1 then
                ok2 = true
            else
                tBase.Log("OnClubGoldTransUserReq  nResult:%d", nResult)
            end
        else
            tBase.Log("OnClubGoldTransUserReq nTUserId:%d online", tData.nTUserId)
            ok2 = tPubUsrApi.ChangeUserTreasure({
                nUserID = tData.nTUserId,
                nItemID = nItemId,
                nDel = nGold,
                nSourceType = 100007,
            })
        end
    until true
    tBase.Log("OnClubGoldTransUserReq ok2:%s", tostring(ok2))
    if not ok2 then
        tBase.Log("OnClubGoldTransUserReq not ok2")
        rsp.nRlt = 1
        -- 回滚转出方
        local ok3 = tPubUsrApi.ChangeUserTreasure({
            nUserID = tData.nUserId,
            nItemID = nItemId,
            nDel = nGold, -- 回退扣款
            nSourceType = 100008,
        })
        tBase.Log("OnClubGoldTransUserReq back gold nUserId:%d ok3:%s", tData.nUserId, tostring(ok3))
    else
        local LobbyNotifyRecordReq = {}
        LobbyNotifyRecordReq.nUserId = tData.nTUserId
        LobbyNotifyRecordReq.nMsgType = 1
        LobbyNotifyRecordReq.sMsg = string.format("收到玩家:%d 转币:%0.1f USDT", tData.nUserId, nGold)
        local packet = DbProtoEncode("LobbyNotifyRecordReq", LobbyNotifyRecordReq)
        tBase.PostDatasByType(tname.db, 0, 0, packet:GetData(), packet:GetSize())
    end
    rsp.nRlt = ok2 == true and 0 or 1
    DbClub1SendToServer(sReturnKey,"ClubGoldTransUserRsp", rsp)
end


--牌桌模板列表
function ClubSink.OnClubGetTableModuleListReq(sReturnKey,Data,nLen)
    tBase.Log("OnClubGetTableModuleListReq")
    local strReq ="ClubGetTableModuleListReq"
    local tData =DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local sSql = string.format("call Load_UserDeskTemplate(%d)", tData.nUserId)
    local arrRecords = {}

    local arrRows = PlatformDB_SqlExecute(sSql,true)
    for _,row in pairs(arrRows) do
        if row.id and tonumber(row.id) > 0 then
            local deskModule = {}
            deskModule.nId = tonumber(row.id) or 0
            deskModule.nGameId = tonumber(row.nGameId) or 0
            deskModule.name = row.nName or ''
            deskModule.content = row.content or ''
            table.insert(arrRecords,deskModule)
        end
    end
    local ClubGetTableModuleListRsp = {}
    ClubGetTableModuleListRsp.nList = arrRecords
    ClubGetTableModuleListRsp.nUserId = tData.nUserId
    DbClub1SendToServer(sReturnKey,"ClubGetTableModuleListRsp",ClubGetTableModuleListRsp)
end

--牌桌模板保存
function ClubSink.OnClubTableModuleSaveReq(sReturnKey,Data,nLen)
    tBase.Log("ClubTableModuleSaveReq")
    local strReq ="ClubTableModuleSaveReq"
    local tData =DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local nRlt = 0
    local nId = tData.nId
    local sSql = string.format("call Deal_UserDeskTemplate(%d,'%s','%s',%d,%d)",tData.nGameId,tData.name,tData.content,tData.nUserId,nId)
    tBase.Log("OnClubTableModuleSaveReq sSql:%s",sSql)

    local arrRows = PlatformDB_SqlExecute(sSql,true)
    tBase.LogT(arrRows)
    arrRows1 = arrRows and arrRows[1] or {}
    local id = tonumber(arrRows1.tmpId) or 0
    local nModule = nil
    if id == 0 then
        nRlt = 1
    else
        nModule = {
            nId = id,
            name = tData.name,
            content = tData.content,
            nGameId = tData.nGameId
        }
    end

    local ClubTableModuleSaveRsp = {}
    ClubTableModuleSaveRsp.nRlt = nRlt
    ClubTableModuleSaveRsp.nUserId = tData.nUserId
    ClubTableModuleSaveRsp.nModule = nModule
    DbClub1SendToServer(sReturnKey,"ClubTableModuleSaveRsp",ClubTableModuleSaveRsp)
end


--标记玩家请求
function ClubSink.OnClubMarkUserReq(sReturnKey,Data,nLen)
    tBase.Log("ClubMarkUserReq")
    local strReq ="ClubMarkUserReq"
    local tData = DbClubProtoParse1(Data, nLen,strReq)
    if not tData then
        assert(false,"Err happen ,Parse error strReq:"..strReq)
        return
    end
    local nRlt = 0
    local nTarUid = tData.nTarUid
    local nText = tData.nText
    local nColorId = tData.nColorId or 0
    local nUserId = tData.nUserId
    local nIsMark = tData.nIsMark
    local sSql = ""
    if nIsMark then
        local mInfo = tPubUsrApi.GetUserMarkInfo(nUserId) or {}
        local tInfo = nil
        local index = -1
        for i, v in ipairs(mInfo) do
            if v.nUserID == nTarUid then
                tInfo = v
                index = i
                break
            end
        end
        if tInfo then
            table.remove(mInfo, index)
        end
        table.insert(mInfo, {nUserID = nTarUid, nText = nText, nColorId = nColorId})
        local nValue = cjson.encode(mInfo)
        tPubUsrApi.SetUserMarkInfo(nUserId, nValue)
        sSql = string.format("call Update_UserMarkInfo(%d,'%s')", nUserId, nValue)
        tBase.Log("OnClubMarkUserReq sSql:%s", sSql)
    else
        local info = tPubUsrApi.GetUserNameInfo(nUserId)
        info.need_save = false
        local nValue = cjson.encode(info)
        sSql = string.format("call Update_UserMarkInfo_Change(%d,'%s')", nUserId, nValue)
        tBase.Log("OnClubMarkUserReq 22 sSql:%s", sSql)
    end

    local arrRows = AccountsDB_SqlExecute(sSql)
    tBase.LogT(arrRows)
    arrRows1 = arrRows and arrRows[1] or {}
    local ok = tonumber(arrRows1.affected_rows) or 0
    nRlt = ok > 0 and 0 or 1
    local ClubMarkUserRsp = {}
    ClubMarkUserRsp.nRlt = nRlt
    ClubMarkUserRsp.nUserId = nUserId
    ClubMarkUserRsp.nText = tData.nText
    ClubMarkUserRsp.nColorId = nColorId
    DbClub1SendToServer(sReturnKey,"ClubMarkUserRsp",ClubMarkUserRsp)
end

return ClubSink