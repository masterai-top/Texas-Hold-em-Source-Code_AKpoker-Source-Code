-- 大厅服 配置逻辑

package.path = require("./lua/DB_s/Head").path

local tBase = require("base")           -- 基础功能接口
local redis = require("redis")      -- Redis数据库接口
local api = require("publicApi")    -- 共用功能接口
local tname = require("typename")   -- 类弄定义接口
local tErr   = require("ErrorSink")       -- 捕捉错误

LogonConfig= {}


-- 加载限制配置
function LogonConfig.LoadLimitCfg(sReturnKey, sData, nLen)
    tBase.Log(" 限制配置    LoadLimitCfg   sReturnKey:   "..sReturnKey)
    local ReadData = tBase.GetRP().new(sData, nLen)
    local MainID = ReadData:GetModuleID()
    local SubID = ReadData:GetMsgID()
    local sSql = ReadData:GetString()
    local tSqlRes = {}
    --执行数据库操作          
    local nIndex = 0
    tBase.Log(" 限制配置   执行SQL  %s ",sSql)
    local cursor = assert (dbSink.PlatformDB_connect:execute (sSql))
    repeat
        row = cursor:fetch({},"a")
        while row do
           function LogonConfig.GetRes(row)
                tSqlRes[nIndex..",".."sMachine"]  = row.MachineSerial  or ""
                tSqlRes[nIndex..",".."nEnjoinLogon"]   = tonumber(row.EnjoinLogon)  or 0
                tSqlRes[nIndex..",".."nEnjoinRegister"]    = tonumber(row.EnjoinRegister)  or 0
           end
           xpcall(LogonConfig.GetRes,tErr.tpLog, row)
            nIndex = nIndex + 1
            row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbSink.PlatformDB_connect:nextres()
    until( cursor == 0 )

    tBase.Log(" 登录服   DB  返回数据   : %d,%d", MainID, SubID)
    local s = tBase.GetSP().new(MainID, SubID)
    tBase.Log(" 登录服   限制配置      nIndex：  "..nIndex)
    s:AddInt32(nIndex)
    for i = 0,nIndex - 1 do
        -- tBase.Log(" 登录服   限制配置      i:   "..i)
        s:AddString(tSqlRes[i..",".."sMachine"])
        s:AddInt32(tSqlRes[i..",".."nEnjoinLogon"])
        s:AddInt32(tSqlRes[i..",".."nEnjoinRegister"])
    end
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
    tBase.Log(" 登录服   限制配置表      DB返回     成功  ")
end



return LogonConfig