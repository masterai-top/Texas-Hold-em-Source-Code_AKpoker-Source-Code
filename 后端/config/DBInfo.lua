DBInfo = {
    LogDir = "./log/",       -- 服务器日志路径
    Client_LogDir = "/root/Client_log/",       -- 客户端日志命令
}

-- HTTP  配置表
DBInfo.HttpConfig = 
{    
    [1] = {     
        host = '192.168.0.199',     -- 内网： 用于微信登录，支付，实名制，
        port = 84,  
    },
}


DBInfo.backUrl = "http://127.0.0.1:8891"
 -- 注意需要修改  部署新服务器的时候会有变动,
DBInfo.sHttp = "http://"..DBInfo.HttpConfig[1].host..":"..DBInfo.HttpConfig[1].port.."/Auth/"

-- redis的地址池： 18001 select 1 服务器key  消息队列  select 15 用户数据    38001 38002 持久化 
DBInfo.Address = {
    [1] = {
        host = '127.0.0.1',
        port = 18001, 
        pass = '123456',  
    },
    [2] = {
        host = '127.0.0.1',
        port = 38001,
        pass = '123456',  
    },
    [3] = {
        host = '127.0.0.1',
        port = 38002,
        pass = '123456',  
    },
}

-- redis数据库信息
DBInfo.RedisParams = {
    -- 中心redis，用于保存各服务器注册的KEY，还有用于生成唯一key
    center = DBInfo.Address[1],

    -- 消息队列redis，用于局域网内各服务器间的消息传递，可以有多个
    msg = {
        [1] = DBInfo.Address[1], 
    },

    -- 自定义数据库： 用于保存用户数据，可持久化
    My = {
        [1] = DBInfo.Address[1],    
        [2] = DBInfo.Address[2],   -- 提供数据后台访问（数据持久化）
        [3] = DBInfo.Address[3],   -- 监控服专同的 
    },
}

-- mysql数据库信息
DBInfo.MySql_AccountsDB = {
    db_name = "DJH_AccountsDB",
    db_user = "root",
    db_pass = "MyP@ssw0rd2024",
    db_host = "127.0.0.1",
    db_port = 3306,
}

DBInfo.MySql_PlatformDB = {
    db_name = "DJH_PlatformDB",
    db_user = "root",
    db_pass = "MyP@ssw0rd2024",
    db_host = "127.0.0.1",
    db_port = 3306,
}

DBInfo.MySql_TreasureDB = {
    db_name = "DJH_TreasureDB",
    db_user = "root",
    db_pass = "MyP@ssw0rd2024",
    db_host = "127.0.0.1",
    db_port = 3306,
}

DBInfo.MySql_RecordDB = {
    db_name = "DJH_RecordDB",
    db_user = "root",
    db_pass = "MyP@ssw0rd2024",
    db_host = "127.0.0.1",
    db_port = 3306,
}

DBInfo.MySql_WebDB = {
    db_name = "DJH_WebDB",
    db_user = "root",
    db_pass = "MyP@ssw0rd2024",
    db_host = "127.0.0.1",
    db_port = 3306,
}

-- 以下 是 从库 信息
DBInfo.Slave_AccountsDB = {
    db_name = "DJH_AccountsDB",
    db_user = "root",
    db_pass = "MyP@ssw0rd2024",
    db_host = "127.0.0.1",
    db_port = 3306,
}
DBInfo.Slave_PlatformDB = {
    db_name = "DJH_PlatformDB",
    db_user = "root",
    db_pass = "MyP@ssw0rd2024",
    db_host = "127.0.0.1",
    db_port = 3306,
}
DBInfo.Slave_TreasureDB = {
    db_name = "DJH_TreasureDB",
    db_user = "root",
    db_pass = "MyP@ssw0rd2024",
    db_host = "127.0.0.1",
    db_port = 3306,
}
DBInfo.Slave_RecordDB = {
    db_name = "DJH_RecordDB",
    db_user = "root",
    db_pass = "MyP@ssw0rd2024",
    db_host = "127.0.0.1",
    db_port = 3306,
}
DBInfo.Slave_WebDB = {
    db_name = "DJH_WebDB",
    db_user = "root",
    db_pass = "MyP@ssw0rd2024",
    db_host = "127.0.0.1",
    db_port = 3306,
}
--从库地址信息
DBInfo.Db_ForRead={
    DBInfo.Slave_RecordDB,
    DBInfo.Slave_TreasureDB,
    DBInfo.Slave_WebDB,
    DBInfo.Slave_PlatformDB,
    DBInfo.Slave_AccountsDB,
}

--从库地址列表
DBInfo.Array_Db_ForRead={
    DBInfo.Db_ForRead, --从库地址1
    DBInfo.Db_ForRead, --从库地址2
    DBInfo.Db_ForRead, --从库地址3
}

if _G.devEnv == "test" then
    local DBInfoDebug = require("DBInfoDebug")
    return DBInfoDebug
    -- for k,v in pairs(DBInfoDebug) do
    --     DBInfo[k] = v
    -- end
end
return DBInfo
