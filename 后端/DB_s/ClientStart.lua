--package.path = "../lua/base/?.lua;./lua/base/?.lua;" .. package.path
--package.path = "../lua/base/socket/?.lua;./lua/base/socket/?.lua;" .. package.path 
--package.path = "../lua/DB_s/?.lua;./lua/DB_s/?.lua;" .. package.path
package.path = require("./lua/DB_s/Head").path
local tPubUser = require("PublicUserInfo") 

-- 玩家功能回调
local ClientSink = {}

local m = require("base")
local db = {}


-- 启动服务器
function ClientSink.OnStart()

    db = require("dbSink")

    db.OnStart()

    local cnt =tPubUser.UnLockServAllUsersGold()
    m.Log("Unlock User Cnt:%d",cnt)  
end

-- 停止服务器
function ClientSink.OnStop()

    db.OnStop()

end

-- 有新用户连接
function ClientSink.OnAccept (nClientID,  ip, port)
end

-- 关闭连接
function ClientSink.OnClose (nClientID)
end

    
-- 超时检查
function ClientSink.OnTimeOutDatabase()    

    dbSink.OnTimeOutDatabase() 

end      


return ClientSink
