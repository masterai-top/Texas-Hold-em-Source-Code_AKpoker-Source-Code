_G.devEnv = "test"
package.path = "../lua/base/?.lua;./lua/base/?.lua;" .. package.path
package.path = "../lua/base/socket/?.lua;./lua/base/socket/?.lua;" .. package.path
package.path = "../lua/DB_s/?.lua;./lua/DB_s/?.lua;" .. package.path
package.path = "../lua/public/?.lua;./lua/public/?.lua;" .. package.path
local api = require("publicApi")    -- 共用功能接口
local dbInfo = require("DBInfo")    -- 数据库连接信息
local tBase = require("base") 
-- 返回MySQL接口
function GetMySQL()
    return mysql_427F56073F604A338B2FE790AB2A825A
end

function GetCmdLine(serverid)

    local sResLine = ""

    local mysqlEnv = GetMySQL().mysql()                    --创建环境对象

    -- 创建数据库连接
    local PlatformDB_connect = mysqlEnv:connect(dbInfo.MySql_PlatformDB.db_name, dbInfo.MySql_PlatformDB.db_user,dbInfo.MySql_PlatformDB.db_pass,dbInfo.MySql_PlatformDB.db_host,dbInfo.MySql_PlatformDB.db_port)  --连接数据库
    if not PlatformDB_connect then
        tBase.Log("Error: PlatformDB_connect failed! please check DBinfo file")
    end

    PlatformDB_connect:execute "SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci" --设置数据库的编码格式

    local sLuaFile = ""
    local sOtherInfo = ""

    local cursor = assert (PlatformDB_connect:execute ("select * from ServerInfo where ID = "..serverid))
    local row = cursor:fetch({},"a")    
    if row then

        -- 服务类型：0 -- 登陆， 1 -- 大厅， 2 -- 游戏， 3 -- 数据库， 4 -- 聊天和杂项， 5 -- 网关服 -- 6 web服
        -- 9 ---  三公游戏
        if row.SType == "0" then
            sLuaFile = "./lua/Logon_s/ClientStart"
        elseif row.SType == "1" then
            sLuaFile = "./lua/Lobby/ClientStart"
        -- elseif row.SType == "2" then
        --     sLuaFile = "./lua/Game/ClientStart"
        elseif row.SType == "3" then
            sLuaFile = "./lua/DB_s/ClientStart"
        elseif row.SType == "4" then
            sLuaFile = "./lua/Chat/ClientStart"
        elseif row.SType == "5" then
            sLuaFile = "./lua/Gateway/ClientStart"
        elseif row.SType == "6" then
            sLuaFile = "./lua/Web/ClientStart"
        elseif row.SType == "7" then
            sLuaFile = "./lua/Android/ClientStart"
        elseif row.SType == "8" then
            sLuaFile = "./lua/BurDB/ClientStart"
        elseif row.SType == "11" then
            sLuaFile = "./lua/Control/ClientStart"
        elseif row.SType=="12" then
            sLuaFile = "./lua/Monitor/ClientStart"
        elseif row.SType == "101" then
            sLuaFile = "./lua/Game/SanGong/ClientStart"
        elseif row.SType == "102" then
            sLuaFile = "./lua/Game/NiuNiu/ClientStart"
        elseif row.SType == "104" then
            sLuaFile = "./lua/Game/BaiRenNiuNiu/ClientStart"
        elseif row.SType == "105" then
            sLuaFile = "./lua/Game/ZhaJinHua/ClientStart"
        elseif row.SType == "106" then
            sLuaFile = "./lua/Game/Dian21/ClientStart"
        elseif row.SType == "107" then
            sLuaFile = "./lua/Game/Baijiale/ClientStart"        --百人百家乐
        elseif row.SType == "108" then
            sLuaFile = "./lua/Game/majiang/ClientStart"
        elseif row.SType == "109" then
            sLuaFile = "./lua/Game/qzBaijiale/ClientStart"      --抢庄百家乐
        elseif row.SType == "110" then
            sLuaFile = "./lua/Game/tbBaijiale/ClientStart"      --通比百家乐
        elseif row.SType == "113" then
            sLuaFile = "./lua/Game/SanGong/ClientStart"
        elseif row.SType == "114" then
            sLuaFile = "./lua/Game/Dian21/ClientStart"
        elseif row.SType == "115" then
            sLuaFile = "./lua/Game/Dian21/ClientStart"
        elseif row.SType =="116" then
            sLuaFile = "./lua/Game/PaiJiu/ClientStart"
        elseif row.SType =="118" then
            sLuaFile = "./lua/Game/BaiRenZhaJinHua/ClientStart"
        elseif row.SType =="120" then
            sLuaFile = "./lua/Game/ErBaGang/ClientStart"
        elseif row.SType =="212" then --集合鱼游戏服
            sLuaFile = "./lua/Game/YuXiaXie/Slave/ClientStart"
        elseif row.SType == "127" then--集合鱼中心服
            sLuaFile = "./lua/Game/YuXiaXie/Center/ClientStart"
        elseif row.SType =="121" then --鱼游戏服
            sLuaFile = "./lua/Game/YuXiaXieM/Slave/ClientStart"
        elseif row.SType == "125" then--鱼中心服
            sLuaFile = "./lua/Game/YuXiaXieM/Center/ClientStart"
        elseif row.SType =="126" then --百家乐中心服
            sLuaFile = "./lua/Game/BaiJiaLeM/Center/ClientStart"
        elseif row.SType =="122" then --百家乐游戏服
            sLuaFile = "./lua/Game/BaiJiaLeM/Slave/ClientStart"
        elseif row.SType =="123" then --德州扑克
            sLuaFile = "./lua/Game/DeZhouM/DeZhou/ClientStart"
        elseif row.SType =="140" then --德州扑克 从服
            sLuaFile = "./lua/Game/DeZhouM/Slave/ClientStart"
        elseif row.SType =="124" then --搏灯
            sLuaFile = "./lua/Game/BoDeng/ClientStart"
        elseif row.SType == "128" then
            sLuaFile = "./lua/Game/GaoBo/ClientStart"
        elseif row.SType == "133" then
            sLuaFile = "./lua/Game/PilotM/Center/ClientStart"
        elseif row.SType == "134" then
            sLuaFile = "./lua/Game/PilotM/Slave/ClientStart"
        elseif row.SType =="135" then
            sLuaFile = "./lua/Game/PilotSmallGame/ClientStart"
        elseif row.SType =="136" then
            sLuaFile = "./lua/Game/PilotGuessGame/ClientStart"
        elseif row.SType == "150" then
            sLuaFile = "./lua/Game/SeDie/ClientStart"
        elseif row.SType =="151" then
            sLuaFile = "./lua/Game/ColorButterGame/ColorButterFA/Center/ClientStart"
        elseif row.SType =="152" then
            sLuaFile = "./lua/Game/ColorButterGame/ColorButterFA/Slave/ClientStart" 
        elseif row.SType =="220" then
            sLuaFile = "./lua/Game/LiveM/Center/ClientStart"
        elseif row.SType =="221" then
            sLuaFile = "./lua/Game/LiveM/Slave/ClientStart" 
        elseif row.SType =="153" then --直播色碟中心服
            sLuaFile = "./lua/Game/SeDieM/Center/ClientStart"
        elseif row.SType =="154" then --直播色碟游戏服
            sLuaFile = "./lua/Game/SeDieM/Slave/ClientStart"
		elseif row.SType =="155" then --骰宝中心服
            sLuaFile = "./lua/Game/TouBaoM/Center/ClientStart"
        elseif row.SType == "156" then--骰宝游戏服
            sLuaFile = "./lua/Game/TouBaoM/Slave/ClientStart" 
        elseif row.SType =="129" then
            sLuaFile = "./lua/Game/FootBallM/Slave/ClientStart" 
        elseif row.SType =="130" then
            sLuaFile = "./lua/Game/FootBallM/Center/ClientStart"
        elseif row.SType =="230" then --俱乐部中心服
            sLuaFile = "./lua/Club/Center/ClientStart" 
        elseif row.SType =="231" then --俱乐部从服
            sLuaFile = "./lua/Club/Slave/ClientStart" 
        elseif row.SType == "157" then
            sLuaFile = "./lua/Game/FellTree/Center/ClientStart"
        elseif row.SType == "158" then
            sLuaFile = "./lua/Game/FellTree/Slave/ClientStart"
        elseif row.SType == "159" then
            sLuaFile = "./lua/Game/Basketball/Center/ClientStart"
        elseif row.SType == "160" then
            sLuaFile = "./lua/Game/Basketball/Slave/ClientStart"
        elseif row.SType=="170" then --德州2中心服
            sLuaFile = "./lua/Game/Texas/Center/ClientStart"
        elseif row.SType=="171" then --德州2从服
            sLuaFile = "./lua/Game/Texas/Slave/ClientStart"
        elseif row.SType=="172" then
            sLuaFile = "./lua/Game/TexasClub/Center/ClientStart"
        elseif row.SType=="173" then
            sLuaFile = "./lua/Game/TexasClub/Slave/ClientStart"
        elseif row.SType=="175" then
            sLuaFile = "./lua/Game/TexasClubShortCard/Center/ClientStart"
        elseif row.SType=="176" then
            sLuaFile = "./lua/Game/TexasClubShortCard/Slave/ClientStart"
        elseif row.SType=="178" then
            sLuaFile = "./lua/Game/ClubQiangZhuangNiu/ClientStart"
        elseif row.SType=="139" then
            sLuaFile = "./lua/Game/LongHu/Center/ClientStart"
        elseif row.SType=="138" then
            sLuaFile = "./lua/Game/LongHu/Slave/ClientStart"
        elseif row.SType=="143" then
            sLuaFile = "./lua/Game/NiuNiuM/Center/ClientStart"
        elseif row.SType=="142" then
            sLuaFile = "./lua/Game/NiuNiuM/Slave/ClientStart"
        elseif row.SType=="301" then    -- 小游戏 老司机
            sLuaFile = "./lua/MiniGame/OldHand/ClientStart"
        elseif row.SType=="302" then    -- 小游戏 弹球
            sLuaFile = "./lua/MiniGame/TanQiu/ClientStart"
        elseif row.SType=="303" then    -- 小游戏 地鼠
            sLuaFile = "./lua/MiniGame/DiShu/ClientStart"
        elseif row.SType=="304" then    -- 小游戏 弹线
            sLuaFile = "./lua/MiniGame/TanXian/ClientStart"
        elseif row.SType=="305" then    --德州比赛服
            sLuaFile = "./lua/TexasCup/ClientStart"
        elseif row.SType=="146" then    --红黑彩中心服
            sLuaFile = "./lua/Game/BRLottely/Center/ClientStart"
        elseif row.SType=="147" then     --红黑彩中从服
            sLuaFile = "./lua/Game/BRLottely/Slave/ClientStart"
        elseif row.SType=="306" then     --夺宝彩票
            sLuaFile = "./lua/Game/JackLot/ClientStart"
        end

        sLuaFile = sLuaFile..":"..serverid..":"..row.Port..":"..row.SType..":"..row.Ip..":"..row.ScoketType..":"..row.Name
        sOtherInfo = row.Port.."\n"..row.MaxCon.."\n"..row.TType.."\n"..row.ScoketType 

    end
    cursor:close() 
    
    -- cursor = assert (PlatformDB_connect:execute ("select * from GameSrvConfig where SrvId = "..serverid))
    -- row = cursor:fetch({},"a")
    -- if row then
    --     sLuaFile = sLuaFile..":"..row.SType       
    -- end
    -- cursor:close() 
    
    sResLine = sLuaFile.."\n"..sOtherInfo 
    PlatformDB_connect:close()  --关闭数据库连接
    mysqlEnv:close()      --关闭数据库环境

    return sResLine
end