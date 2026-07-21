DBInfoDebug = {
    LogDir = "./log/",       -- 服务器日志路径
    Client_LogDir = "/root/Client_log/",       -- 客户端日志命令
}

-- HTTP  配置表
DBInfoDebug.HttpConfig = 
{    
    [1] = {     
        host = '192.168.0.199',     -- 内网： 用于微信登录，支付，实名制，
        port = 84,  
    },
}

 -- 注意需要修改  部署新服务器的时候会有变动,
DBInfoDebug.sHttp = "http://"..DBInfoDebug.HttpConfig[1].host..":"..DBInfoDebug.HttpConfig[1].port.."/Auth/"

-- redis的地址池： 18001 select 1 服务器key  消息队列  select 15 用户数据    38001 38002 持久化 
DBInfoDebug.Address = {
    [1] = {
        host = '127.0.0.1',
        port = 6379, 
        pass = '',  
    },
    [2] = {
        host = '127.0.0.1',
        port = 6379,
        pass = '',
    },
    [3] = {
        host = '127.0.0.1',
        port = 6379,
        pass = '',
    },
}

-- redis数据库信息
DBInfoDebug.RedisParams = {
    -- 中心redis，用于保存各服务器注册的KEY，还有用于生成唯一key
    center = DBInfoDebug.Address[1],

    -- 消息队列redis，用于局域网内各服务器间的消息传递，可以有多个
    msg = {
        [1] = DBInfoDebug.Address[1], 
    },

    -- 自定义数据库： 用于保存用户数据，可持久化
    My = {
        [1] = DBInfoDebug.Address[1],    
        [2] = DBInfoDebug.Address[2],   -- 提供数据后台访问（数据持久化）
        [3] = DBInfoDebug.Address[3],   -- 监控服专同的 
    },
}

-- mysql数据库信息
DBInfoDebug.MySql_AccountsDB = {
    db_name = "DJH_AccountsDB",
    db_user = "root",
    db_pass = "suiguo3564",
    db_host = "127.0.0.1",
    db_port = 3306,
}

DBInfoDebug.MySql_PlatformDB = {
    db_name = "DJH_PlatformDB",
    db_user = "root",
    db_pass = "suiguo3564",
    db_host = "127.0.0.1",
    db_port = 3306,
}

DBInfoDebug.MySql_TreasureDB = {
    db_name = "DJH_TreasureDB",
    db_user = "root",
    db_pass = "suiguo3564",
    db_host = "127.0.0.1",
    db_port = 3306,
}

DBInfoDebug.MySql_RecordDB = {
    db_name = "DJH_RecordDB",
    db_user = "root",
    db_pass = "suiguo3564",
    db_host = "127.0.0.1",
    db_port = 3306,
}

DBInfoDebug.MySql_WebDB = {
    db_name = "DJH_WebDB",
    db_user = "root",
    db_pass = "suiguo3564",
    db_host = "127.0.0.1",
    db_port = 3306,
}

-- 以下 是 从库 信息
DBInfoDebug.Slave_AccountsDB = {
    db_name = "DJH_AccountsDB",
    db_user = "root",
    db_pass = "suiguo3564",
    db_host = "127.0.0.1",
    db_port = 3306,
}
DBInfoDebug.Slave_PlatformDB = {
    db_name = "DJH_PlatformDB",
    db_user = "root",
    db_pass = "suiguo3564",
    db_host = "127.0.0.1",
    db_port = 3306,
}
DBInfoDebug.Slave_TreasureDB = {
    db_name = "DJH_TreasureDB",
    db_user = "root",
    db_pass = "suiguo3564",
    db_host = "127.0.0.1",
    db_port = 3306,
}
DBInfoDebug.Slave_RecordDB = {
    db_name = "DJH_RecordDB",
    db_user = "root",
    db_pass = "suiguo3564",
    db_host = "127.0.0.1",
    db_port = 3306,
}
DBInfoDebug.Slave_WebDB = {
    db_name = "DJH_WebDB",
    db_user = "root",
    db_pass = "suiguo3564",
    db_host = "127.0.0.1",
    db_port = 3306,
}
--从库地址信息
DBInfoDebug.Db_ForRead={
    DBInfoDebug.Slave_RecordDB,
    DBInfoDebug.Slave_TreasureDB,
    DBInfoDebug.Slave_WebDB,
    DBInfoDebug.Slave_PlatformDB,
    DBInfoDebug.Slave_AccountsDB,
}

--从库地址列表
DBInfoDebug.Array_Db_ForRead={
    DBInfoDebug.Db_ForRead, --从库地址1
    DBInfoDebug.Db_ForRead, --从库地址2
    DBInfoDebug.Db_ForRead, --从库地址3
}

return DBInfoDebug