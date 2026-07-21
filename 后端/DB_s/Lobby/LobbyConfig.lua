-- 大厅服 配置逻辑
package.path = require("./lua/DB_s/Head").path

local tBase = require("base")           -- 基础功能接口
local redis = require("redis")      -- Redis数据库接口
local api = require("publicApi")    -- 共用功能接口
local tname = require("typename")          -- 类弄定义接口
local tErr   = require("ErrorSink")       -- 捕捉错误
local ProtoMgr  = require("ProtoManager") -- 协议管理对象 

LobbyConfig = {}

--加载 游戏列表配置
function LobbyConfig.Load_GameListConfig(sReturnKey, sData, nLen)
    local ReadData = tBase.GetRP().new(sData, nLen)
    local MainID = ReadData:GetModuleID() 
    local SubID = ReadData:GetMsgID()

    local Read = ProtoMgr.PubProto_pb.RUQ_GameListCfg()
    Read:ParseFromString(ReadData:GetString())

    local sSql = Read.sSql  
    local tSend = ProtoMgr.PubProto_pb.RUP_GameListCfg()

    sSql = "Call Load_ShopInfo_Config()"
    tBase.Log(" 分店基本表   配置sSql： %s  ",sSql) 
    local cursor = assert (dbSink.PlatformDB_connect:execute (sSql))  
    repeat
        row = cursor:fetch({},"a")
        while row do
           function LobbyConfig.GetRes(row)  
                local arr =  tSend.arrShopCfg:add()                
                arr.Id               = tonumber(row.Id)
                arr.Shop             = row.Shop  
                arr.GroupID          = tonumber(row.GroupID)  
                arr.DefaultGroupID   = tonumber(row.DefaultGroupID)  
                arr.ShopInfo         = row.ShopInfo
                -- tBase.Log(" 分店基本表    Id %d  Shop: %s , ChannelType %d, FatherID %d "
                -- ,arr.Id,arr.Shop,arr.GroupID, arr.DefaultGroupID)  
           end  
           xpcall(LobbyConfig.GetRes,tErr.tpLog, row)
           row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbSink.PlatformDB_connect:nextres()
    until( cursor == 0 ) 

    sSql = "Call Load_GroupInfo_Config()"
    tBase.Log(" 群组基本表   配置sSql： %s  ",sSql) 

    local cursor = assert (dbSink.PlatformDB_connect:execute (sSql))  
    repeat
        row = cursor:fetch({},"a")
        while row do
           function LobbyConfig.GetRes(row)  
                local arr =  tSend.arrGroupCfg:add()                
                arr.Id               = tonumber(row.Id)
                arr.GroupName        = row.GroupName  
                arr.GroupInfo        = row.GroupInfo  
                -- tBase.Log(" 群组基本表    Id %d  GroupName: %s , GroupInfo %s",arr.Id,arr.GroupName,arr.GroupInfo)  
           end  
           xpcall(LobbyConfig.GetRes,tErr.tpLog, row)
           row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbSink.PlatformDB_connect:nextres()
    until( cursor == 0 ) 


    sSql = "Call Load_GroupGameList()"
    tBase.Log(" 群组游戏列表    配置sSql： %s  ",sSql)   
    local cursor = assert (dbSink.PlatformDB_connect:execute (sSql))  
    repeat
        row = cursor:fetch({},"a")
        while row do
           function LobbyConfig.GetRes(row)  
                local arr =  tSend.arrGroupGameListCfg:add()
                arr.Id           = tonumber(row.Id)    
                arr.GroupID      = tonumber(row.GroupID)    
                arr.SType        = tonumber(row.SType)    
                arr.GameName     = row.GameName
                arr.GameOrder    = tonumber(row.GameOrder) 
                arr.GameStatus   = tonumber(row.GameStatus)
                arr.CGStatus     = tonumber(row.CGStatus)             
                arr.IconUrl      = row.IconUrl            
                arr.GamePath     = row.GamePath                          
                arr.Version      = row.Version            
                arr.ZipFilePath     = row.ZipFilePath                         
                arr.MD5FilePath      = row.MD5FilePath              
                -- tBase.Log(" 渠道游戏列表配置 Id: %d SType: %d  GroupID: %d "
                    -- ,arr.Id,arr.SType,arr.GroupID)  
           end  
           xpcall(LobbyConfig.GetRes,tErr.tpLog, row)
           row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbSink.PlatformDB_connect:nextres()
    until( cursor == 0 )         

    local SType = 0
    local sSql = "Call Load_GameConfig("..SType..")"
    tBase.Log(" 游戏类型配置   sSql=  %s  ",sSql)   
    local cursor = assert (dbSink.PlatformDB_connect:execute (sSql))  
    repeat
        row = cursor:fetch({},"a")
        while row do
           function LobbyConfig.GetRes(row)  
                local arr =  tSend.arrGameCfg:add()
                arr.Id          = tonumber(row.Id)
                arr.SType       = tonumber(row.SType)   
                arr.Session     = tonumber(row.Session)  
                arr.Floor       = tonumber(row.Floor)    
                arr.LowGrade    = tonumber(row.LowGrade)  
                arr.SessionName = row.SessionName              
                arr.Status      = tonumber(row.Status) 
                -- tBase.Log(" 游戏列表配置  Id: %d  SType: %d  ",arr.Id,arr.SType)  
           end  
           xpcall(LobbyConfig.GetRes,tErr.tpLog, row)
           row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbSink.PlatformDB_connect:nextres()
    until( cursor == 0 ) 


    local sSql = "Call Load_GroupGameCfg_Relation()"
    tBase.Log(" 加载  渠道与游戏配置的关系  %s  ",sSql)   
    local cursor = assert (dbSink.PlatformDB_connect:execute (sSql))  
    repeat
        row = cursor:fetch({},"a")
        while row do
           function LobbyConfig.GetRes(row)  
                local arr =  tSend.arrGroupGameRelation:add()
                arr.Id                    = tonumber(row.Id)  
                arr.GrouplGameListID      = tonumber(row.GrouplGameListID)  
                arr.GameCfgID             = tonumber(row.GameCfgID)  
                arr.DefaultSessionName    = row.DefaultSessionName  
                -- tBase.Log(" 渠道与游戏配置的关系   Id: %d  GrouplGameListID: %d   GameCfgID: %d  DefaultSessionName： %s ",arr.Id,arr.GrouplGameListID,arr.GameCfgID,arr.DefaultSessionName)  
           end  
           xpcall(LobbyConfig.GetRes,tErr.tpLog, row)
           row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbSink.PlatformDB_connect:nextres()
    until( cursor == 0 ) 


    local s = tBase.GetSP().new(MainID, SubID)
    s:AddString(tSend:SerializeToString())
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    tBase.Log(" 大厅服   游戏列表配置   DB服  返回成功    ")
end

return LobbyConfig