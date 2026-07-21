
Head ={}

Head.path = "../lua/base/?.lua;./lua/base/?.lua;" ..
"../lua/base/socket/?.lua;./lua/base/socket/?.lua;" ..
"../lua/base/luasec/?.lua;./lua/base/luasec/?.lua;" ..
"../lua/public/?.lua;./lua/public/?.lua;" .. 
"../lua/protocol/pb/?.lua;./lua/protocol/pb/?.lua;" ..
"../lua/base/logging/?.lua;./lua/base/logging/?.lua;" ..
"../lua/Chat/?.lua;./lua/Chat/?.lua;" ..
"../lua/Chat/User?.lua;./lua/Chat/User/?.lua;" ..
"./lua/public/PublicLogic/?.lua;" ..
package.path

package.path = Head.path

require("base")         -- 基础功能接口
require("typename")     -- 服务器名字
require("DBInfo")       -- 数据库连接信息
require("logging")      -- 日志等级接口
require("cjson")        -- json
require("logger")       -- 日志对象
require("ProtoManager") -- 协议管理对象
 

require("ChatHandle") 
require("ChatManager")   
require("IMMessage")    
require("PublicUserInfo")   
require("TimerAux") -- 协议管理对象


tBase = base




return Head
