package.path = require("./lua/DB_s/Head").path

local m = require("base") -- 基础功能接口
local tname = require("typename") -- 类弄定义接口
local ProtoMgr = require("ProtoManager") -- 协议管理对象 
local tlogging = require("logging") -- 日志等级接口
local dbInfo = require("DBInfo") -- 数据库连接信息
local mlogger = require("logger") -- 日志对象 
local tTreasureSink = require("TreasureSink")   -- 财富数据库接口
local lg = require("LogonSink") -- 登录相关数据库操作
local tAndroidSink  = require("AndroidSink") -- 机器人配置加载
local tSafeBoxSink = require("SafeBoxSink") -- 银行模块
local tReqHandle= require("ReqHandle")
local tRecordSink   = require("RecordSink")     -- 日志数据库接口
local tProtoAux =require("ProtoCoder").Aux
local tPublicRedis = require("PublicRedis")
local MiniGameSink = require("MiniGameSink")
local cjson     = require("cjson")
local PublicHandle     = require("PublicHandle")



require("HttpNB")
ClubSink = require("ClubSink")

local DbServer_pb =ProtoMgr.DbServer_pb
local DbServer1_pb =ProtoMgr.DbServer1_pb
local DbServerClub_pb =ProtoMgr.DbServerClub_pb
local DbServerClub1_pb =ProtoMgr.DbServerClub1_pb
local tDbNameToReadConnections ={}
local tDbNameToMainConnections ={}

local pb_Backstage =ProtoMgr.Backstage_pb
local CMD_Backstage =ProtoMgr.Backstage_pb.Backstage_Proto()
local ToCMD_Backstage =function(strProto)
  return CMD_Backstage.Main_CMD,CMD_Backstage[strProto..'_CMD']
end
BackstageAux =tProtoAux:New(pb_Backstage,ToCMD_Backstage)


-- 玩家功能回调
dbSink = { LevelLog = nil } 
dbSink.tToReadConnections = {}  --从库连接
dbSink.tToMainConnections = {}  --从库连接
dbSink.nUserReadBDIndex = nil  --使用的从库index


local function _AddDbConnectionToReadPool(connection,sDbName)
    tDbNameToReadConnections[sDbName] =tDbNameToReadConnections[sDbName] or {}
    table.insert(tDbNameToReadConnections[sDbName],connection)
    if dbSink.tToReadConnections[sDbName] == nil then 
       dbSink.tToReadConnections[sDbName] = connection
    end 
end
local function _AddDbConnectionToMainPool(connection,sDbName)
    tDbNameToMainConnections[sDbName] =tDbNameToMainConnections[sDbName] or {}
    table.insert(tDbNameToMainConnections[sDbName],connection)
    if dbSink.tToMainConnections[sDbName] == nil then 
       dbSink.tToMainConnections[sDbName] = connection
    end 
end
local function _GetConnectionFromReadPool(sDbName)
    local arr =tDbNameToReadConnections[sDbName] or {}
    if #arr ==0 then
        return nil
    end
    local randomDex =math.random(1,#arr)
    return  arr[randomDex]
end
local function _GetConnectionFromMainPool(sDbName)
    local arr =tDbNameToMainConnections[sDbName] or {}
    if #arr ==0 then
        return nil
    end
    local randomDex =math.random(1,#arr)
    return  arr[randomDex]
end
local function _CloseReadPoolConnection()
    for _,arrConn in pairs(tDbNameToReadConnections) do
        for _,conn in ipairs(arrConn) do
            conn:close()
        end
    end
    tDbNameToReadConnections={}
    if dbSink.nUserReadBDIndex then
        tPublicRedis.DelUsedDBRead(dbSink.nUserReadBDIndex)
        dbSink.nUserReadBDIndex = nil
    end
end
local function _CloseMainPoolConnection()
    for _,arrConn in pairs(tDbNameToMainConnections) do
        for _,conn in ipairs(arrConn) do
            conn:close()
        end
    end
    tDbNameToMainConnections={}
end


function dbSink:new( table )
    local t =  table or {}
    self.__index = self
    setmetatable(t,self)
    return t
end

-- 启动服务器
function dbSink.OnStart()
     
    -- 设置日志目录：
    local sLogDir =  dbInfo.LogDir.."db/".. m.GetPort() .. "-" .. m.GetThreadIndex()
    mlogger.SetFile( sLogDir , "db", m )

    -- 设置全局等级
    mlogger:setLevel( tlogging.DEFAULT, "db" )
    -- 消息接收处理，不用默认函数
  --  m.m_MyMonitorFun = --ClientSink.onMsgRecv
    -- 注册服务器
    m.RegServer(tname.db)
    -- 连接数据库
    dbSink.ConnectDB()
    -- 注册协议
    dbSink.RegProto()

    m.Log(" db Server Start ")  
      
    -- 等级案例
    mlogger:info("db Server Start")
    mlogger:debug("debugging...")
    -- mlogger:error("error!")

    local hotFunc =function()
        local patchModuleName ="DbPatch"
        package.loaded[patchModuleName] = nil
          require(patchModuleName)
    end
    m.SetTimer(60001, 1000*60*2, -1, hotFunc)

    m.SetTimer(1003, 1000*60*60, -1, dbSink.DbNameToReadConnections)    -- 一小时连接 操作

    
    m.SetTimer(60003, 1000*5, 1,  tReqHandle._LoadServerInfoData)    
 

    HttpNB.Init(1101, 1102)
end

local function SqlExecut(sSql,dbConnect)
    local arrRows ={}
    local cursor,msg =assert(dbConnect:execute(sSql)) 
    if cursor==nil or type(cursor)=='number' then
        return
    end
    repeat
        row = cursor:fetch({},"a")
        while row do
          table.insert(arrRows,m.DeepCopy(row))
           row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbConnect:nextres()
    until( cursor == 0 ) 
    return arrRows
end

-- 定时一小时 是Mysql连接   不超时断开
function dbSink.DbNameToReadConnections()    
    local sSql  = "select NOW();"  
    for _,dbConnect in pairs(dbSink.tToMainConnections) do
        local arrRows = SqlExecut(sSql,dbConnect)
        -- m.Log("主库 -------------->  size: "..#arrRows)
    end
    for _,dbConnect in pairs(dbSink.tToReadConnections) do
        local arrRows = SqlExecut(sSql,dbConnect)
        -- m.Log("从库 -------------->  size: "..#arrRows)
    end
    tReqHandle._LoadServerInfoData()

    dbSink.ClearData()

end

-- 停止服务器
function dbSink.OnStop()

    -- 取消本地服务器
    m.UnRegServer()
    -- 关闭数据库
    dbSink.ClostDB() 

    m.Log(" db Server OnStop ")

end

-- 有新用户连接
function dbSink.OnAccept (nClientID,  ip, port)
end

-- 关闭连接
function dbSink.OnClose (nClientID)
end

local function _DoDbConnect(dbItem,mysqlEnv)
    m.LogT("_DoDbConnect ",{db_name=dbItem.db_name,db_host=dbItem.db_host,db_port=dbItem.db_port})
    local dbConnect =mysqlEnv:connect(dbItem.db_name, dbItem.db_user,dbItem.db_pass,dbItem.db_host,dbItem.db_port)
    dbConnect:execute "SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci"
    return dbConnect
end

-- 数据库连接
function dbSink.ConnectDB()
    dbSink.mysqlEnv = m.GetMySQL().mysql() --创建环境对象

    --主库连接
    --创建数据库连接
    dbSink.AccountsDB_connect = _DoDbConnect(dbInfo.MySql_AccountsDB,dbSink.mysqlEnv)
    _AddDbConnectionToMainPool(dbSink.AccountsDB_connect,dbInfo.MySql_AccountsDB.db_name)
    --创建数据库连接
    dbSink.PlatformDB_connect = _DoDbConnect(dbInfo.MySql_PlatformDB,dbSink.mysqlEnv)
    _AddDbConnectionToMainPool(dbSink.PlatformDB_connect,dbInfo.MySql_PlatformDB.db_name)
    --创建数据库连接
    dbSink.RecordDB_connect = _DoDbConnect(dbInfo.MySql_RecordDB,dbSink.mysqlEnv)
    _AddDbConnectionToMainPool(dbSink.RecordDB_connect,dbInfo.MySql_RecordDB.db_name)
    --创建数据库连接
    dbSink.TreasureDB_connect = _DoDbConnect(dbInfo.MySql_TreasureDB,dbSink.mysqlEnv)
    _AddDbConnectionToMainPool(dbSink.TreasureDB_connect,dbInfo.MySql_TreasureDB.db_name)
        -- 创建数据库连接
    dbSink.WebDB_connect =_DoDbConnect(dbInfo.MySql_WebDB,dbSink.mysqlEnv)
    _AddDbConnectionToMainPool(dbSink.WebDB_connect,dbInfo.MySql_WebDB.db_name)

    --从库连接
    local arrDbForRead =dbInfo.Db_ForRead or {}
    if dbInfo.Array_Db_ForRead then
        local nLen = #dbInfo.Array_Db_ForRead
        if nLen>0 then
            local nIndex = nil
            local arrUsed = tPublicRedis.GetUsedDBRead()
            --找一个没被使用的从库
            for i=1,nLen do
                if not arrUsed["Index_"..i]then
                    nIndex = i
                    break
                end
            end
            --从库都被使用，选择一个使用最少从库
            if nIndex==nil then
                local arrUsed_new = {}
                for k,v in pairs(arrUsed) do
                    table.insert(arrUsed_new,{nIndex=string.match(k,"%d"),nCnt=tonumber(v)})
                end 
                if #arrUsed_new>1 then
                    table.sort(arrUsed_new,function (a, b)
                        return a.nCnt<b.nCnt
                    end)
                end
                local sIndex = arrUsed_new[1] and arrUsed_new[1].nIndex
                nIndex = tonumber(sIndex)
            end
            --随机选择一个从库
            if nIndex==nil then
                nIndex = math.random(1,nLen)
            end
            tPublicRedis.SetUsedDBRead(nIndex)
            dbSink.nUserReadBDIndex = nIndex
            arrDbForRead = dbInfo.Array_Db_ForRead[nIndex]
            m.Log("选择使用从库%d",nIndex)
        end
    end
    for _,dbItem in ipairs(arrDbForRead) do
        local dbConnect =_DoDbConnect(dbItem,dbSink.mysqlEnv)
        _AddDbConnectionToReadPool(dbConnect,dbItem.db_name)
    end

end

function dbSink.GetDbConnectForRead(sDbName)
    local conn =_GetConnectionFromReadPool(sDbName)
    if  conn then
        return conn
    end
    return _GetConnectionFromMainPool(sDbName)
end


-- 数据库断开
function dbSink.ClostDB()

   -- dbSink.AccountsDB_connect:close()  --关闭数据库连接
    --dbSink.PlatformDB_connect:close()  --关闭数据库连接
    -- dbSink.TreasureDB_connect:close()  --关闭数据库连接
   -- dbSink.RecordDB_connect:close()    --关闭数据库连接
   -- dbSink.WebDB_connect:close()       --关闭数据库连接

   _CloseReadPoolConnection()
   _CloseMainPoolConnection()

    dbSink.mysqlEnv:close()            --关闭数据库环境
    
    m.Log(" db sql Server OnStop ")

end

-- 处理SQL 请求
function dbSink.onChannelDB(ChannelName, ChannelData, ChannelLen)
    
    m.Log(" 处理SQL请求 ChannelName:%s", ChannelName)

end

local function GetHandleFunction(moduleName,sFuncName)
    local func =function(...)
        moduleName[sFuncName](...)
    end
    return func
end
-- 注册协议
function dbSink.RegProto()
    
    local dbCmd =DbServer_pb.Db_Proto()
    local dbCmd1 =DbServer1_pb.Db_Proto1()
    local dbCmdClub =DbServerClub_pb.Db_ClubProto()
    local dbCmdClub1 =DbServerClub1_pb.Db_ClubProto1()

    PublicHandle.PublicHandleProto()  -- 公共操作

    MiniGameSink.MiniGameProto()  -- 小游戏协议

    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbRoomListReq_CMD, GetHandleFunction(tReqHandle,"OnDbRoomListReq")) --房间列表请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbGameListReq_CMD, GetHandleFunction(tReqHandle,"OnDbGameListReq")) --游戏列表请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbShopListReq_CMD, GetHandleFunction(tReqHandle,"OnDbShopListReq")) --游戏列表请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbCheckSafePasswordReq_CMD, GetHandleFunction(tReqHandle,"OnDbCheckSafePasswordReq")) --银行密码验证请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbBankAccessDetailReq_CMD, GetHandleFunction(tReqHandle,"OnDbBankAccessDetailReq"))   --银行存取历史记录请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbBankPasswordChangeReq_CMD, GetHandleFunction(tReqHandle,"OnDbBankPasswordChangeReq")) --银行密码更改请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.VersionReq_CMD, GetHandleFunction(tReqHandle,"OnVersionReq"))                           --客户端当前版本信息请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.MainVersionReq_CMD, GetHandleFunction(tReqHandle,"OnMainVersionReq"))                  --客户主版本信息请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.GameVersionReq_CMD, GetHandleFunction(tReqHandle,"OnGameVersionReq"))               --前端大厅游戏版本请求

    m.RegFunc(dbCmd.Main_CMD, dbCmd.MaintainerIpReq_CMD, GetHandleFunction(tReqHandle,"OnMaintainerIpReq"))               --维护人员ip信息请求 (服务器维护期间，可进入的ip)
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbUserTreasureReq_CMD, GetHandleFunction(tReqHandle,"OnDbUserTreasureReq"))              --用户财富请求
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_ACCOUNT_LOGON, GetHandleFunction(lg,"RequstAccountLogon"))      -- 登录请求
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_ASSIGNDBLOGONACCOUNT, GetHandleFunction(lg,"AssignDBLogonAccount"))      -- 指定DB 登录请求
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_ACCOUNT_REGISTER, GetHandleFunction(lg,"RequstAccountRegister"))   -- 注册

    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.AutoBetLoadUserInfoReq, GetHandleFunction(lg,"_AutoBet_LoadUserInfo"))   --  自动下注加载用户数据

    m.RegFunc(dbCmd.Main_CMD, dbCmd.RecentRecordReq_CMD, GetHandleFunction(tReqHandle,"OnRecentRecordReq"))              --近期战绩查询请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.RecentDetailReq_CMD, GetHandleFunction(tReqHandle,"OnRecentDetailReq"))              --近期牌局记录查询请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.LoadBalancingReq_CMD, GetHandleFunction(tReqHandle,"OnLoadBalancingReq"))           --网关负载均衡列表请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.PlatformChannelShopReq_CMD, GetHandleFunction(tReqHandle,"OnPlatformChannelShopReq")) --平台渠道与分店id的对应关系表请求 
    m.RegFunc(dbCmd.Main_CMD, dbCmd.RefowardRuleReq_CMD, GetHandleFunction(tReqHandle,"OnRefowardRuleReq"))     --网关转发规则请求
    m.RegFunc(dbCmd.Main_CMD, dbCmd.WhiteListReq_CMD, GetHandleFunction(tReqHandle,"OnWhiteListReq"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_WRITETREASURE, GetHandleFunction(tTreasureSink,"WriteTreasure"))      -- 修改玩家财富数据 
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_ZHIBO_WRITETREASURE, GetHandleFunction(tTreasureSink,"BR_WriteTreasure"))      -- 修改玩家财富数据 
     
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbLiveRecordReq_CMD, GetHandleFunction(tReqHandle,"OnDbLiveRecordReq"))         --直播游戏输赢记录查询 请求

    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.GetResultsBySqlReq_CMD, GetHandleFunction(tReqHandle,"OnGetResultsBySqlReq"))    --执行sql并返回结果
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbJackpotSettleCReq_CMD, GetHandleFunction(tReqHandle,"OnDbJackpotSettleCReq"))    --夺宝层级三记录查询 请求

    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.ServerGroupRelationReq_CMD, GetHandleFunction(tReqHandle,"OnServerGroupRelationReq"))    --服务器分组关系请求
    
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.AutoBetMissingRecordReq_CMD, GetHandleFunction(tReqHandle,"OnAutoBetMissingRecordReq"))  --自动下注遗漏记录 请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.AutoBetMissingWinRateReq_CMD, GetHandleFunction(tReqHandle,"OnAutoBetMissingWinRateReq"))  --自动下注遗漏记录胜率 请求

    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbAccountCloseReq_CMD, GetHandleFunction(tReqHandle,"OnDbAccountCloseReq"))  --账号注销 请求

    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbVeriCodeReq_CMD, GetHandleFunction(tReqHandle,"OnDbVeriCodeReq"))   --获取注册验证码请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbBindReq_CMD, GetHandleFunction(tReqHandle,"OnDbBindReq"))           --手机邮箱绑定请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbSignInfoReq_CMD, GetHandleFunction(tReqHandle,"OnDbSignInfoReq"))   --签到界面信息 请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbSignReq_CMD, GetHandleFunction(tReqHandle,"OnDbSignReq"))           --签到 请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbBindQuerryReq_CMD,GetHandleFunction(tReqHandle,"OnDbBindQuerryReq"))        --账号绑定查询请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbPasswordResetReq_CMD,GetHandleFunction(tReqHandle,"OnDbPasswordResetReq"))  --密码重置请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbGetBindAwardReq_CMD,GetHandleFunction(tReqHandle,"OnDbGetBindAwardReq"))   --领取绑定奖励 请求
    
    ----

    m.RegFunc(dbCmd.Main_CMD, dbCmd.SqlExcuteReq_CMD, GetHandleFunction(tReqHandle,"OnSqlExcuteReq"))
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbSqlExcuteReq_CMD, GetHandleFunction(tReqHandle,"OnDbSqlExcuteReq"))

    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbLiveCSRelationReq_CMD, GetHandleFunction(tReqHandle,"OnDbLiveCSRelationReq"))

    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbRechargeReq_CMD, GetHandleFunction(tReqHandle,"OnDbRechargeReq")) --游戏中充值请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbBetRecordReq_CMD, GetHandleFunction(tReqHandle,"OnDbBetRecordReq")) --下注记录查询(飞行棋小游戏)
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbTexaStatisticInit_CMD, GetHandleFunction(tReqHandle,"OnTexaStatisticInit")) --德州玩家统计数据

    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbWritePaiJuHashReq_CMD, GetHandleFunction(tReqHandle,"OnDbWritePaiJuHashReq")) --牌局Hash记录存储请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbGetHashCardReq_CMD, GetHandleFunction(tReqHandle,"OnDbGetHashCardReq")) --Hash指定局牌序列请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbWriteRecordCostReq_CMD, GetHandleFunction(tReqHandle,"OnDbWriteRecordCostReq")) --牌局花费记录存储请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbGetGloBalConfigReq_CMD, GetHandleFunction(tReqHandle,"OnDbGetGloBalConfigReq")) --获取全局配置请求
    m.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbPaiJuHashRecordUpdateReq_CMD, GetHandleFunction(ClubSink,"OnDbPaiJuHashRecordUpdateReq")) --更新牌局hash
    --

    m.RegFunc(dbCmd.Main_CMD, dbCmd.RecordBetSettleReq_CMD, GetHandleFunction(tReqHandle,"OnRecordBetSettleReq"))   --下注结算记录

    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbLiveTableCreateReq_CMD, GetHandleFunction(tReqHandle,"OnDbLiveTableCreateReq")) --直播游戏桌子创建
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbLiveTableCloseReq_CMD, GetHandleFunction(tReqHandle,"OnDbLiveTableCloseReq"))   --直播游戏桌子关闭
    
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbLiveBingdingReq_CMD, GetHandleFunction(tReqHandle,"OnDbLiveBingdingReq"))     --主播绑定与解绑记录
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbWriteRecordPublicReq_CMD, GetHandleFunction(tReqHandle,"OnDbWriteRecordPublicReq"))     --写记录公共接口

    m.RegFunc(dbCmd.Main_CMD, dbCmd.ServerIdOfMaitainingReq_CMD, GetHandleFunction(tReqHandle,"OnServerIdOfMaitainingReq"))   --不停机维护时,被设为维护的serverid 请求

    -- m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_CONTROL_DATA, GetHandleFunction(tReqHandle,"GetControlData")) 
    -- m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_CHECK_USER, GetHandleFunction(tReqHandle,"OnCheckUser")) 
    -- m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_CONTROL_GETNEW_USER, GetHandleFunction(tReqHandle,"OnControl_GetNew_User")) 
    -- m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_CONTROL_USER_DATA, GetHandleFunction(tReqHandle,"GetControl_User_Data")) 
    -- m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_CONTROL_USER_STAT_DATA, GetHandleFunction(tReqHandle,"OnControl_User_Stat_Data"))
    -- m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_USERID_SCOPE_DATA, GetHandleFunction(tReqHandle,"Get_UserID_Scope"))
    
    if dbCmd.DbCheckReq_CMD then
        m.RegFunc(dbCmd.Main_CMD, dbCmd.DbCheckReq_CMD, GetHandleFunction(tReqHandle,"OnDbCheckReq"))
    end
    
    -- 机器人配置加载
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_LOADANDROIDCFG, GetHandleFunction(tAndroidSink,"LoadAndroidConfig"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_ClEANMYSQL, GetHandleFunction(tAndroidSink,"CleanMysqlAndroidData"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_UPDATEMYSQL, GetHandleFunction(tAndroidSink,"UpdateMysqlAndroidData"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_GETANDROIDNAME, GetHandleFunction(tAndroidSink,"GetAndroidNameConfig"))
    -- m.RegFunc(ProtoMgr.Sys.SYS_DB, ProtoMgr.Sub_DB.SUB_REQ_WRITESCORELOCK, tTreasureSink.WriteScoreLocker)
    -- 大厅功能
    -- m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_SAFEBOX_VERIFY, tSafeBoxSink.SafeBoxPassWordVerifySink) -- 银行验证密码
    --m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_SAVEANDROIDITEM, tAndroidSink.SaveAndroidItem)
    --m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_SAFEBOX_DETAIL, tSafeBoxSink.SafeBoxDetailSink) 
    --m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_SAFEBOX_RESETCODE, tSafeBoxSink.SafeBoxResetCodeSink)  
    --m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_GET_RECORD_LIST, tPRSink.GetPaiJuList) -- 获取牌局记录
    -- m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_GateWay.SUB_REQ_DB_USER_IP, tUserIp.DBResLoaderIpInfo) -- 加载过滤Ip   
    --m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_GateWay.SUB_REQ_VERSION_INFO, tVersion.SendVersionSQL) -- 加载版本信息      
    --m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_GateWay.SUB_REQ_PHONE_UPDATE, tVersion.DBResLoadPhone) --加载苹果版本
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_WRITEPAIJU, GetHandleFunction(tRecordSink,"WriteUserPaiJuRecord"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_WRITEPAIJU_WINLOSE, GetHandleFunction(tRecordSink,"WriteUserWinLose"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_UPDATE_USERINFO, GetHandleFunction(tSafeBoxSink,"Update_UserInfo")) 
    m.RegFunc(dbCmd.Main_CMD, dbCmd.DbAdCfgListReq_CMD, GetHandleFunction(tReqHandle,"OnDbAdCfgListReq"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_CONTROL_RECORD, GetHandleFunction(tRecordSink,"Control_Record"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_PILOT_CONTROLRECORD, GetHandleFunction(tRecordSink,"PilotWriteControlRecord"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_Chat_Record, GetHandleFunction(tRecordSink,"WriteChatRecord"))

    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_CONTROL_WINLOSE, GetHandleFunction(TreasureSink,"WriteControlTableWinLose")) 
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_CONTROL_INFO, GetHandleFunction(TreasureSink,"Control_Info")) 
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_CONTROL_ROOM_DATA, GetHandleFunction(TreasureSink,"WriteRoomData")) 

    --quick
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB1.SUB_REQ_QUICKDBSAVE, GetHandleFunction(tRecordSink,"QuickSave"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB1.SUB_REQ_QUICKDBLOAD, GetHandleFunction(tRecordSink,"QuickLoad"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB1.SUB_REQ_JUSTEXCUTE, GetHandleFunction(tRecordSink,"JustExcute"))
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB1.SUB_REQ_QUICKDBJSON, GetHandleFunction(tRecordSink,"JsonExcute"))
 
    --后台充值请求
    m.RegFunc(CMD_Backstage.Main_CMD, CMD_Backstage.RechargeReq_CMD, GetHandleFunction(tReqHandle,"OnRechargeReq"))
    m.RegFunc(CMD_Backstage.Main_CMD, CMD_Backstage.RewardReq_CMD, GetHandleFunction(tReqHandle,"OnRewardReq"))--打赏通知
    m.RegFunc(CMD_Backstage.Main_CMD, CMD_Backstage.FollowBetLockReq_CMD, GetHandleFunction(tReqHandle,"OnFollowBetLockReq")) --修改跟投锁通知
    m.RegFunc(CMD_Backstage.Main_CMD, CMD_Backstage.CanFollowBetReq_CMD, GetHandleFunction(tReqHandle,"OnCanFollowBetReq")) --打赏之后解锁跟投通知
    m.RegFunc(CMD_Backstage.Main_CMD, CMD_Backstage.CoinCanDrawReq_CMD, GetHandleFunction(tReqHandle,"OnCoinCanDrawReq"))   --当前能转出金币数量 查询
    m.RegFunc(CMD_Backstage.Main_CMD, CMD_Backstage.ChangeGoldReq_CMD, GetHandleFunction(tReqHandle,"OnChangeGoldReq"))   --后台增减金币请求

    --俱乐部
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubDataReq_CMD, GetHandleFunction(ClubSink,"OnClubDataReq")) --俱乐部数据 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ServerIdGroupReq_CMD, GetHandleFunction(ClubSink,"OnServerIdGroupReq")) --服务器对应分组 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.CreateClubReq_CMD, GetHandleFunction(ClubSink,"OnCreateClubReq")) --创建俱乐部 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubUserLogonReq_CMD, GetHandleFunction(ClubSink,"OnClubUserLogonReq")) --俱乐部玩家登录 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.GetUserClubListReq_CMD, GetHandleFunction(ClubSink,"OnGetUserClubListReq")) --玩家俱乐部列表 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.SearchClubReq_CMD, GetHandleFunction(ClubSink,"OnSearchClubReq")) --搜索俱乐部 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ApplyJoinClubReq_CMD, GetHandleFunction(ClubSink,"OnApplyJoinClubReq")) --申请加入俱乐部 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ChangeClubInfoReq_CMD, GetHandleFunction(ClubSink,"OnChangeClubInfoReq")) --修改俱乐部信息 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubMembersReq_CMD, GetHandleFunction(ClubSink,"OnClubMembersReq")) --俱乐部成员 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.SearchClubMemberReq_CMD, GetHandleFunction(ClubSink,"OnSearchClubMemberReq")) --搜索俱乐部成员 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubAdminOperateReq_CMD, GetHandleFunction(ClubSink,"OnClubAdminOperateReq")) --管理员操作 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.TransferClubGoldReq_CMD, GetHandleFunction(ClubSink,"OnTransferClubGoldReq")) --个人俱乐部币增加退还 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.TransferRecordReq_CMD, GetHandleFunction(ClubSink,"OnTransferRecordReq")) --个人俱乐部币流水记录 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubPaiJuRecordReq_CMD, GetHandleFunction(ClubSink,"OnClubPaiJuRecordReq")) --俱乐部个人历史牌局 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubContribRecordReq_CMD, GetHandleFunction(ClubSink,"OnClubContribRecordReq")) --俱乐部个人贡献(俱乐部收益) 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubBlacklistReq_CMD, GetHandleFunction(ClubSink,"OnClubBlacklistReq")) --俱乐部黑名单 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubBlacklistMgrReq_CMD, GetHandleFunction(ClubSink,"OnClubBlacklistMgrReq")) --黑名单管理操作 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubBlacklistSearchReq_CMD, GetHandleFunction(ClubSink,"OnClubBlacklistSearchReq")) --黑名单玩家搜索 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubTableRecordReq_CMD, GetHandleFunction(ClubSink,"OnClubTableRecordReq")) --俱乐部牌桌记录 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubTableUserReq_CMD, GetHandleFunction(ClubSink,"OnClubTableUserReq")) --俱乐部牌桌参与玩家 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubMemberInfoReq_CMD, GetHandleFunction(ClubSink,"OnClubMemberInfoReq")) --俱乐部成员信息 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubAdminListReq_CMD, GetHandleFunction(ClubSink,"OnClubAdminListReq")) --俱乐部管理员列表 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubAdminMgrReq_CMD, GetHandleFunction(ClubSink,"OnClubAdminMgrReq")) --俱乐部增加删除管理员 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubChangeAdminPowerReq_CMD, GetHandleFunction(ClubSink,"OnClubChangeAdminPowerReq")) --修改管理员权限 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGoldChangeRecordReq_CMD, GetHandleFunction(ClubSink,"OnClubGoldChangeRecordReq")) --俱乐部账户的俱乐部币流水 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubApplyListReq_CMD, GetHandleFunction(ClubSink,"OnClubApplyListReq")) --俱乐部申请列表请求 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubApplyHandleReq_CMD, GetHandleFunction(ClubSink,"OnClubApplyHandleReq")) --俱乐部申请处理 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubInviteUserReq_CMD, GetHandleFunction(ClubSink,"OnClubInviteUserReq")) --邀请用户 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubAssetChangeRsq_CMD, GetHandleFunction(ClubSink,"OnClubAssetChangeRsq")) -- 俱乐部总资产修改
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubApplyInfoReq_CMD, GetHandleFunction(ClubSink,"OnClubApplyInfoReq")) -- 俱乐部某条申请的信息 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubWriteUserRecordReq_CMD, GetHandleFunction(ClubSink,"OnClubWriteUserRecordReq")) -- 写俱乐部玩家结算记录 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubWriteUserRecord2Req_CMD, GetHandleFunction(ClubSink,"OnClubWriteUserRecord2Req")) -- 写俱乐部玩家结算记录2 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubWriteTableRecordReq_CMD, GetHandleFunction(ClubSink,"OnClubWriteTableRecordReq")) -- 写俱乐部牌桌记录 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubPaiPuReq_CMD, GetHandleFunction(ClubSink,"OnClubPaiPuReq")) -- 牌谱请求 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubOpratePaiPuReq_CMD, GetHandleFunction(ClubSink,"OnClubOpratePaiPuReq")) -- 操作牌谱请求 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubUserNoticeReq_CMD, GetHandleFunction(ClubSink,"OnClubUserNoticeReq")) -- 玩家个人通知 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubUserNoticeHandleReq_CMD, GetHandleFunction(ClubSink,"OnClubUserNoticeHandleReq")) -- 处理个人通知请求 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetUserNoticeInfoReq_CMD, GetHandleFunction(ClubSink,"OnClubGetUserNoticeInfoReq")) -- 获取某条个人通知信息 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubSearchUserReq_CMD, GetHandleFunction(ClubSink,"OnClubSearchUserReq")) -- 搜索用户 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubApplyInvalidReq_CMD, GetHandleFunction(ClubSink,"OnClubApplyInvalidReq")) -- 申请失效处理请求 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetApplyListReq_CMD, GetHandleFunction(ClubSink,"OnClubGetApplyListReq")) -- 玩家俱乐部币申请（玩家个人） 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubUserApplyOpReq_CMD, GetHandleFunction(ClubSink,"OnClubUserApplyOpReq")) -- 玩家申请处理 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubUserInfoReq_CMD, GetHandleFunction(ClubSink,"OnClubUserInfoReq")) -- 玩家个人信息 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubChangeUserInfoReq_CMD, GetHandleFunction(ClubSink,"OnClubChangeUserInfoReq")) -- 修改玩家个人信息 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubChangeLoginPassWardReq_CMD, GetHandleFunction(ClubSink,"OnClubChangeLoginPassWardReq")) -- 修改登录密码 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubPlaybackDataReq_CMD, GetHandleFunction(ClubSink,"OnClubPlaybackDataReq")) -- 回放数据请求 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubWritePlaybackDataReq_CMD, GetHandleFunction(ClubSink,"OnClubWritePlaybackDataReq")) -- 写入回放数 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubUserRedDotReq_CMD, GetHandleFunction(ClubSink,"OnClubUserRedDotReq")) -- 玩家红点数据 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetTablePaiJuIdReq_CMD, GetHandleFunction(ClubSink,"OnClubGetTablePaiJuIdReq")) -- 获取牌桌的牌局id 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubLoadUserInfoReq_CMD, GetHandleFunction(ClubSink,"OnClubLoadUserInfoReq")) -- 加载俱乐部成员的基本信息 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetPersonTableRecordReq_CMD, GetHandleFunction(ClubSink,"OnClubGetPersonTableRecordReq")) -- 获取玩家个人牌桌记录 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetTableDetailReq_CMD, GetHandleFunction(ClubSink,"OnClubGetTableDetailReq")) -- 获取牌桌详细记录 请求

    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetTablePaiPuReq_CMD, GetHandleFunction(ClubSink,"OnClubGetTablePaiPuReq")) -- 获取牌桌牌谱 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetTableInsuranceReq_CMD, GetHandleFunction(ClubSink,"OnClubGetTableInsuranceReq")) -- 获取牌桌保险明细 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetTableUserListReq_CMD, GetHandleFunction(ClubSink,"OnClubGetTableUserListReq")) -- 获取牌桌玩家列表 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubWriteUserGPS_CMD, GetHandleFunction(ClubSink,"OnClubWriteUserGPS")) -- 记录玩家的GPS 请求

    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetPersonTableRecord2Req_CMD, GetHandleFunction(ClubSink,"OnClubGetPersonTableRecord2Req_Normal")) -- 获取玩家个人牌桌记录2 请求(大厅永久牌桌)
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetTableDetail2Req_CMD, GetHandleFunction(ClubSink,"OnClubGetTableDetail2Req")) -- 获取牌桌详细记录2 请求(大厅永久牌桌)
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetTableUserList2Req_CMD, GetHandleFunction(ClubSink,"OnClubGetTableUserList2Req")) -- 获取牌桌玩家列表2 请求(大厅永久牌桌)
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetTablePaiPu2Req_CMD, GetHandleFunction(ClubSink,"OnClubGetTablePaiPu2Req")) -- 获取牌桌牌谱2 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetTableInsurance2Req_CMD, GetHandleFunction(ClubSink,"OnClubGetTableInsurance2Req")) -- 获取牌桌保险明细2 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetPaijuDetailReq_CMD, GetHandleFunction(ClubSink,"OnClubGetPaijuDetailReq")) -- 获取牌局明细查询请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetPayOrderReq_CMD, GetHandleFunction(ClubSink,"OnDBClubGetPayOrderReq")) -- 充值账单查询 请求

    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.LoadStoreConfigReq_CMD, GetHandleFunction(ClubSink,"OnLoadStoreConfigReq")) -- 加载商城配置
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.PayOrder_CreateReq_CMD, GetHandleFunction(ClubSink,"OnPayOrder_CreateReq")) -- 创建订单
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.PayOrder_DealReq_CMD, GetHandleFunction(ClubSink,"OnPayOrder_DealReq"))     -- 处理订单
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.StoreBuyRecord_CMD, GetHandleFunction(ClubSink,"OnStoreBuyRecord"))         -- 购买记录
	

	m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubSetSafePassWardOpenReq_CMD, GetHandleFunction(ClubSink,"OnClubSetSafePassWardOpenReq")) -- 设置安全密码开启关闭 请求
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubInputRedeemCodeReq_CMD, GetHandleFunction(ClubSink,"OnClubInputRedeemCodeReq")) -- 输入兑换码 请求

    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubAddiInfoChangeReq_CMD, GetHandleFunction(ClubSink,"OnClubAddiInfoChangeReq")) -- 用户额外信息录入请求

    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubSecuPwdReq_CMD, GetHandleFunction(ClubSink,"OnClubSecuPwdReq")) -- 安全密码请求

    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubSearchSecuPwdReq_CMD, GetHandleFunction(ClubSink,"OnClubSearchSecuPwdReq")) -- 安全密码校验请求

    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubNotifyRecordReq_CMD, GetHandleFunction(ClubSink,"OnClubNotifyRecordReq")) -- 后台审核通知记录

	m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubGetActiInfoReq_CMD, GetHandleFunction(ClubSink,"OnClubGetActiInfoReq")) -- 活动信息请求	
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubActivityAwardGrantReq_CMD, GetHandleFunction(ClubSink,"OnClubActivityAwardGrantReq")) -- 发放活动奖励
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubActivityHandleReq_CMD, GetHandleFunction(ClubSink,"OnClubActivityHandleReq")) -- 领取活动奖励
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubActivityPublicReq_CMD, GetHandleFunction(ClubSink,"OnClubActivityPublicReq")) -- 领取活动奖励
    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubRecommendHandleReq_CMD, GetHandleFunction(ClubSink,"OnClubRecommendHandleReq")) -- 推荐操作请求

    m.RegFunc(dbCmdClub.Main_CMD, dbCmdClub.ClubActivityReviewDataReq_CMD, GetHandleFunction(ClubSink,"OnClubActivityReviewDataReq")) -- 写审核数据请求

    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubGetActivityListReq_CMD, GetHandleFunction(ClubSink,"OnClubGetActivityListReq")) -- 获取活动列表请求
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubGetPersonTableStaticReq_CMD, GetHandleFunction(ClubSink,"OnClubGetPersonTableStaticReq")) -- 大厅信息统计
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubGetGoldHistoryReq_CMD, GetHandleFunction(ClubSink,"OnClubGetGoldHistoryReq")) -- 账变
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubGetGameGoldReq_CMD, GetHandleFunction(ClubSink,"OnClubGetGameGoldReq")) -- 局内消耗
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubGetGameGoldDetailReq_CMD, GetHandleFunction(ClubSink,"OnClubGetGameGoldDetailReq")) -- 局内消耗详情
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubGetHashListReq_CMD, GetHandleFunction(ClubSink,"OnClubGetHashListReq")) -- 可存证hash请求
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubGetHashCardReq_CMD, GetHandleFunction(ClubSink,"OnClubGetHashCardReq")) -- Hash指定局牌序列请求
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubGoldTransUserReq_CMD, GetHandleFunction(ClubSink,"OnClubGoldTransUserReq")) -- 内部转币
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubGetTableModuleListReq_CMD, GetHandleFunction(ClubSink,"OnClubGetTableModuleListReq")) -- 牌桌模板列表
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubTableModuleSaveReq_CMD, GetHandleFunction(ClubSink,"OnClubTableModuleSaveReq")) -- 牌桌模板保存
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.ClubMarkUserReq_CMD, GetHandleFunction(ClubSink,"OnClubMarkUserReq")) -- 标记玩家请求
    m.RegFunc(dbCmdClub1.Main_CMD, dbCmdClub1.CluUpdatePlaybackDataReq_CMD, GetHandleFunction(ClubSink,"OnCluUpdatePlaybackDataReq")) -- 更新回放数
       -- 新增支付信息到DB操作
    -- 插入充值地址
    m.RegFunc(dbCmd.Main_CMD, dbCmd.PayInsertClientAddressReq_CMD, GetHandleFunction(tReqHandle, "OnDBInsertClientAddressReq"))
    -- 更新充值地址，将地址和userid对应
    m.RegFunc(dbCmd.Main_CMD, dbCmd.PayUpdateAddressReq_CMD, GetHandleFunction(tReqHandle, "OnDbUpdateAddressReq"))
    -- 插入充值订单信息
    m.RegFunc(dbCmd.Main_CMD, dbCmd.PayInsertPayInfoReq_CMD, GetHandleFunction(tReqHandle, "OnDbInsertPayInfoReq"))
    -- 更新充值信息，此时充值完成，包含tx_hash信息
    m.RegFunc(dbCmd.Main_CMD, dbCmd.PayUpdatePayInfoReq_CMD, GetHandleFunction(tReqHandle, "OnDbUpdatePayInfoReq"))
    -- 插入提现信息
    m.RegFunc(dbCmd.Main_CMD, dbCmd.PayInsertWithdrawInfoReq_CMD, GetHandleFunction(tReqHandle, "OnDbInsertWithdrawInfoReq"))
    -- 获取充值地址
    m.RegFunc(dbCmd.Main_CMD, dbCmd.PayGetPayAddressReq_CMD, GetHandleFunction(tReqHandle, "OnDbGetPayAddressReq"))

    -- 大厅请求个人消息
    m.RegFunc(dbCmd.Main_CMD, dbCmd.LobbyNotifyRecordReq_CMD, GetHandleFunction(tReqHandle,"OnLobbyNotifyRecordReq")) 
    m.RegFunc(dbCmd.Main_CMD, dbCmd.UpdateLobbyNotifyRecordReq_CMD, GetHandleFunction(tReqHandle,"OnUpdateLobbyNotifyRecordReq")) 

    m.RegFunc(dbCmd.Main_CMD, dbCmd.ClubUserNoticeReq_CMD, GetHandleFunction(tReqHandle, "OnClubUserNoticeReq")) -- 玩家个人通知 请求

    -- 玩家昵称校验
    m.RegFunc(ProtoMgr.Sys.DB, ProtoMgr.Sub_DB.SUB_REQ_CHECK_NICKNAME, GetHandleFunction(tReqHandle, "OnCheckNickName"))      -- 校验昵称
end



-- 超时检查
function dbSink.OnTimeOutDatabase()          
    local dbConnect  = dbSink.tToMainConnections["DJH_PlatformDB"] 
    if not dbConnect then 
        m.Log("_OnTimeOutDatabase 超时检查  dbConnect is nil  ")  
        return 
    end 
    local sSql  = "call LoadTimeout()"  
    local arrRows = SqlExecut(sSql,dbConnect)
    if arrRows and #arrRows > 0 then   
        -- m.Log("_OnTimeOutDatabase  超时检查  arrRows: "..#arrRows) 
        local arr = {}
        for k, v in pairs(arrRows) do
            if v["trx_state"] == "LOCK WAIT" then  
                logger:error(string.format("当前事务记录的锁 %d:  %s ",k,cjson.encode(v)) ) 
            else
                logger:error(string.format("当前事务记录 %d :  %s ",k,cjson.encode(v)) ) 
            end  
            if v["lock_id"] then 
                -- m.Log("_OnTimeOutDatabase  死锁表 %d  arrRows: %s ",k,cjson.encode(v))    
                logger:error(string.format("锁记录:  %s ",cjson.encode(v)) )
            
            end           
        end 
    end     
end     

function dbSink.ClearData()
    if m.m_tKey ~= m.m_arrServerList[tname.db][1] then
        m.Log("_ClearData   此线程不处理 ")  
        return  
    end       

    -- 清除 百家乐自动下注数据
    local nDay = tonumber(os.date("%d"))
    -- if nDay==1 or nDay==10 or nDay==20 then 
        local nHour = tonumber(os.date("%H"))
        if nHour >= 2 and nHour <= 6 then             
            -- 清除 过期 60天数据
            local sSql =string.format("call BJLGTSettleRecord_Clear_Past_due();")    
            local dbConnect  = dbSink.tToMainConnections["DJH_RecordDB"] 
            if not dbConnect then 
                m.Log("_OnTimeOutDatabase 超时检查  dbConnect is nil  ")  
                return 
            end   
            m.Log("_OnTimeOutDatabase 超时检查  sSql "..sSql)  
            SqlExecut(sSql,dbConnect)                
        end 
    -- end     
end


return dbSink
