package.path = require("./lua/BurDB/Head").path

local tBase = require("base")
local api = require("publicApi")
local dbInfo = require("DBInfo")
local tname = require("typename") 
local ProtoMgr = require("ProtoManager")  
local tlogging = require("logging") 
local mlogger = require("logger")   
local tParserAux = require("ParserAux")
local tCScriptCfg = require("CScriptCfg")
local tLuaScrip = require("LuaScrip")
local cjson = require("cjson")

local DbServer1_pb =ProtoMgr.DbServer1_pb
local DbCmd =ProtoMgr.DbServer_pb.Db_Proto()
local DbProtoEncode =tParserAux.DbProtoEncode
local DbProtoParse =tParserAux.DbProtoParse

-- 玩家功能回调
ClientStart = { LevelLog = nil }
ClientStart.m_ClientList = {} -- 保存每个玩家的信息的链表
ClientStart.m_Servers = {}   -- 内网服务器表列，保存服务器与对应用户的关系，方便其它处理

function ClientStart:new( table )
    local t =  table or {}
    self.__index = self
    setmetatable(t,self)
    return t
end

local function ErrReport(sErrMsg,id)
    tBase.Log("BurDB_sErrMsg:%s id:%d",(sErrMsg or "nil"),id or -1)
end

local function RedisCheck()
    if tBase.m_MyRedisData[1].redis==nil then
        ErrReport("MyRedis_1 is nil")
        return
    end
    if tBase.m_MyRedisData[2].redis==nil then
        ErrReport("MyRedis_2 is nil")
        return
    end
    local isNormal=true
    local ping1Rt =tBase.m_MyRedisData[1].redis:ping()
    if not ping1Rt then
        isNormal=false
        ErrReport("MyRedis_1 ping fail")
    end
    local ping2Rt =tBase.m_MyRedisData[2].redis:ping()
    if not ping2Rt then
        isNormal=false
        ErrReport("MyRedis_2 ping fail")
    end
    if not tBase.m_centerRedis.Mo:ping() then
        isNormal=false
        ErrReport("MoRedis ping fail")
    end
    if isNormal then
        tBase.Log("==>RedisCheck Normal")
    else
        tBase.Log("--------------------")
    end
end

ClientStart.tToMainConnections = {}  --主库连接

local tDbNameToMainConnections ={}

local function _DoDbConnect(dbItem,mysqlEnv)
    local dbConnect =mysqlEnv:connect(dbItem.db_name, dbItem.db_user,dbItem.db_pass,dbItem.db_host,dbItem.db_port)
    dbConnect:execute "SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci"
    return dbConnect
end

local function _AddDbConnectionToMainPool(connection,sDbName)
    tDbNameToMainConnections[sDbName] =tDbNameToMainConnections[sDbName] or {}
    table.insert(tDbNameToMainConnections[sDbName],connection) 
end

local function _GetConnectionFromMainPool(sDbName)
    local arr =tDbNameToMainConnections[sDbName] or {}
    if #arr ==0 then
        return nil
    end
    local randomDex =math.random(1,#arr)
    return  arr[randomDex]
end

local function _CloseMainPoolConnection()
    for _,arrConn in pairs(tDbNameToMainConnections) do
        for _,conn in ipairs(arrConn) do
            conn:close()
        end
    end
    tDbNameToMainConnections={}
end

-- 数据库连接
function ClientStart.ConnectDB()
    ClientStart.mysqlEnv = tBase.GetMySQL().mysql() --创建环境对象
   
    --主库连接
    --创建数据库连接
    ClientStart.AccountsDB_connect = _DoDbConnect(dbInfo.MySql_AccountsDB,ClientStart.mysqlEnv)
    _AddDbConnectionToMainPool(ClientStart.AccountsDB_connect,dbInfo.MySql_AccountsDB.db_name)
        --创建数据库连接
    ClientStart.PlatformDB_connect = _DoDbConnect(dbInfo.MySql_PlatformDB,ClientStart.mysqlEnv)
    _AddDbConnectionToMainPool(ClientStart.PlatformDB_connect,dbInfo.MySql_PlatformDB.db_name)
        --创建数据库连接
    ClientStart.RecordDB_connect = _DoDbConnect(dbInfo.MySql_RecordDB,ClientStart.mysqlEnv)
    _AddDbConnectionToMainPool(ClientStart.RecordDB_connect,dbInfo.MySql_RecordDB.db_name)
    --创建数据库连接
    ClientStart.TreasureDB_connect = _DoDbConnect(dbInfo.MySql_TreasureDB,ClientStart.mysqlEnv)
    _AddDbConnectionToMainPool(ClientStart.TreasureDB_connect,dbInfo.MySql_TreasureDB.db_name)
        -- 创建数据库连接
    ClientStart.WebDB_connect =_DoDbConnect(dbInfo.MySql_WebDB,ClientStart.mysqlEnv)
    _AddDbConnectionToMainPool(ClientStart.WebDB_connect,dbInfo.MySql_WebDB.db_name)

end

function ClientStart.OnStart()     
    -- 设置日志目录:
    local sLogDir =  dbInfo.LogDir.."BurDB/" .. tBase.GetPort() .. "-" .. tBase.GetThreadIndex()
    mlogger.SetFile( sLogDir , "BurDB", tBase )
    -- 设置全局等级
    mlogger:setLevel( tlogging.DEFAULT, "BurDB" )
    -- 消息接收处理，不用默认函数
    tBase.m_MyMonitorFun = nil
    -- 注册服务器
    tBase.RegServer(tname.burdb)
    -- 连接数据库
    ClientStart.ConnectDB()
    -- 注册协议
    ClientStart.Protocol() 
    tBase.SetTimer(25535, 1000*60*10, -1, RedisCheck) 
    tBase.SetTimer(25536, 1000*5, 1, tCScriptCfg.ReqDbScriptList) 
    tBase.Log(" BurDB_Server Start ")  
      

end
function ClientStart.OnStop()

    -- 取消本地服务器
    tBase.UnRegServer()
    tBase.Log(" BurDB_Server OnStop ") 
end

function ClientStart.ClostDB()

    _CloseMainPoolConnection()   
    ClientStart.mysqlEnv:close()            --关闭数据库环境    

    tBase.Log(" BurDB_sql Server OnStop ")
end

function ClientStart.OnAccept(ClientID, ip, port)
end
function ClientStart.OnClose(ClientID)
end
function ClientStart.OnRecv(ClientID, Data, Len)
end

function ClientStart.GetDbConnectForRead(sDbName)
    local conn =_GetConnectionFromMainPool(sDbName)
    if  conn then
        return conn
    end
    return 
end

local function GetHandleFunction(moduleName,sFuncName)
    local func =function(...)
        moduleName[sFuncName](...)
    end
    return func
end

-- 注册协议
function ClientStart.Protocol()
    local dbCmd1 =DbServer1_pb.Db_Proto1()
    tBase.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbScriptCfgListReq_CMD, GetHandleFunction(tLuaScrip,"OnDbScriptCfgListReq"))
    tBase.RegFunc(dbCmd1.Main_CMD, dbCmd1.DbBurWriteNotify_CMD, GetHandleFunction(tLuaScrip,"OnDbBurWriteNotice"))


end



return ClientStart