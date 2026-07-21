package.path = require("./lua/BurDB/Head").path

local tBase = require("base")
local tname = require("typename")
local ProtoMgr  = require("ProtoManager")
local tParserAux = require("ParserAux")
local cjson = require("cjson")
local tBase64= require("BaseSink") -- base 编码解码
local tPubApi = require("PublicUserInfo")
local tGameConfig = require("GameConfig")

local dbCmd1 =ProtoMgr.DbServer1_pb.Db_Proto1()

LuaScrip = { 
	m_client_sink_list = nil, -- 网关保存的用户列表
	m_isOpenTimer = 0,  --定时器是否开启
	m_tNotice = {},
	m_TimerID = 15555,
	m_BatchID = 10419, -- 批量发送定时器标识
}
LuaScrip.tBurScript = {}

function SqlExecut(sSql,dbConnect)
    local arrRows ={} 
    local cursor,msg =assert(dbConnect:execute (sSql))
    if cursor==nil then
        return
    end
    repeat
        row = cursor:fetch({},"a")
        while row do
          table.insert(arrRows,tBase.DeepCopy(row))
           row = cursor:fetch(row,"a")
        end
        cursor:close()
        cursor = dbConnect:nextres()
    until( cursor == 0 ) 
    return arrRows
end

function SqlExecutResult(sSql,dbConnect)
    local arrRows ={} 
    local cursor,msg =assert(dbConnect:execute (sSql))
    if cursor==nil then
        tBase.LogT("没处理结果_",sSql)
        return
    end 
end

 
function LuaScrip.OnDbScriptCfgListReq(sReturnKey, sData, nLen)
    local arrtItem ={}
    arrtItem.arrScriptItem = {}
    local sql = "call Load_LuaScript_Config()"
    local arrRows = SqlExecut(sql, ClientStart.PlatformDB_connect)
    tBase.Log(sql..' luaScript_cfg_sum:'..#arrRows) 
    if #arrRows == 0 then
        tBase.Log("Err happen,Len =0 error ScriptCfg")
        return
    end
    LuaScrip.WriteFile('\n local tBase = require("base") \n  local cjson = require("cjson") \n local BurScript = {} \n', "BurScript.lua", "w")
    for _,row in ipairs(arrRows) do
        local Item ={}
        Item.ID = tonumber(row.ID) or 1
        Item.ScriptName = row.ScriptName or "" 
        Item.UIPath = row.UIPath or ""
        Item.Event = row.Event or "" 
        Item.Script = row.Script or ""
        Item.UUID = row.UUID or ""
        table.insert(arrtItem.arrScriptItem, Item)
        local Content = LuaScrip.WriteFile(Item.Script.."\n", "BurScript.lua")
        if Content then
            tBase.Log("写入文件成功Nmae="..Item.ScriptName)
        end
    end
    LuaScrip.WriteFile("\n return BurScript", "BurScript.lua") 
    local tSend = ProtoMgr.DbServer1_pb.DbScriptCfgListRsp()
    tBase.ProtoInit(tSend, arrtItem)
    local s = tBase.GetSP().new(dbCmd1.Main_CMD,dbCmd1.DbScriptCfgListRsp_CMD)
    s:AddString(tSend:SerializeToString())
    tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
end

--执行脚本
function LuaScrip.OnDbBurWriteNotice(sReturnKey, sData, nLen) 
    local ReadData = tBase.GetRP().new(sData, nLen)
    local Read = ProtoMgr.DbServer1_pb.DbBurWriteNotify()
    Read:ParseFromString(ReadData:GetString())
    local gcjson = cjson.decode(Read.tBuildUserData)
    if not LuaScrip.isLoad then
        local function reLoad()
            LuaScrip.tBurScript = require("BurScript")
            LuaScrip.isLoad = true
        end
        local isSuccee,sErr = pcall(reLoad)
        if not isSuccee then
            if type(sErr) == "string" then 
                logger:error(sErr)
            else 
                tBase.LogT(sErr) 
            end
		end 
    end    
    -- tBase.LogT("执行脚本_",gcjson)
    LuaScrip.Record_Write_Script(tBase.m_MyRedisData[1].redis,gcjson)
end

function LuaScrip.Record_Write_Script(redis_table, DataSrc)
    --redis_table 包含所有my的redis接口:指定redis库15,具体再看
    local iUserId = DataSrc.iUserId or 0
    if not DataSrc.iUserId then 
        -- tBase.LogT("Record_Write_Script 存储失败 DataSrc",DataSrc) 
        -- return 
    end 
    local bNull = false
    local tUserInfo = tPubApi.GetAllUserInfo(iUserId)
    local nGameId = 0
    local nSocketId = 2
    if next(tUserInfo)~=nil then
        if tUserInfo.sChannel == nil then bNull = true end
        DataSrc.nShopID = (tUserInfo.nShopID==nil and 2 or tGameConfig.GetChannelId(tUserInfo.nShopID) )
        DataSrc.sChannel = tUserInfo.nShopID or 37
        nGameId = tUserInfo.nGameId or 0 
        tBase.LogT(tUserInfo)
        nSocketId = tUserInfo.nSocketId or 1
        assert(nSocketId~=nil,"iUserId_"..iUserId)
        tBase.Log("iUserId_"..iUserId.." sChannel_"..DataSrc.sChannel.." nShopID_"..DataSrc.nShopID.." bNull_"..tostring(bNull).." nGameId_"..nGameId.." nSocketId_"..nSocketId)
    end
    local arrRlt =redis_table:set("ExeRecordDB_sChannel_",(DataSrc.sChannel or "0") )
    if arrRlt then
        tBase.Log("Record_Write_Script 存储成功") 
    else
        tBase.Log("Record_Write_Script 存储失败") 
    end
    if DataSrc.iResult then DataSrc.iResult = math.ceil(DataSrc.iResult) end
    local sSqlEve = "Call BurEvent_Record_Write("..(iUserId or 0)..
    ",".."'"..(nLoginID or -1).."'"..
    ",".."'"..(DataSrc.sUiPath or "NULL").."'"..
    ",".."'"..(DataSrc.sEvent or "NULL").."'"..
    ",".."'"..(DataSrc.nShopID or 2).."'"..
    ",".."'"..(DataSrc.sChannel or "37").."'"..
    ",".."'"..(DataSrc.sOsVersion or "NULL").."'"..
    ",".."'"..(DataSrc.sBrowserVer or "NULL").."'"..
    ",".."'"..(DataSrc.sModel or "NULL").."'"..
    ",".."'"..(DataSrc.nDeviceId or 15).."'"..
    ",".."'"..(DataSrc.iResult or "NULL").."'"..
    ",".."'"..(nGameId or 0).."'"..
    ","..(nSocketId or 2)..")"
    
    local kEvent =redis_table:get(DataSrc.sEvent)
    local nCount = 1
    if kEvent ~= nil then nCount = nCount+tonumber(kEvent) end
    redis_table:set(DataSrc.sEvent,nCount)
    SqlExecutResult(sSqlEve,ClientStart.RecordDB_connect) 
    -- local sSqlTotal = "Call BurTotal_Record_Write("..(nCount or 5)..",".."'"..(DataSrc.sEvent or "NULL").."'"..")"
    -- SqlExecutResult(sSqlTotal,ClientStart.RecordDB_connect) 
    
    tBase.Log("sSqlEve="..sSqlEve)
    -- tBase.Log("sSqlTotal="..sSqlTotal) 
end

--test执行脚本
function LuaScrip.ExeScriptEvent(sEvent,sScriptName)
    local tt = {uiPath="Login_Script",vent="loginStart/loginEnd",version="1.0.0.1",type="account/token/visitor",platform="IOS",channel="Channel",result="fail/userID",reason="not  know"}
    local DataSrc = cjson.encode(tt)
    
    if tt.uiPath == sScriptName then
        tBase.Log("脚本名字相同")
    end 
    local f = _G[sScriptName]
    tBase.Log(" f="..type(f).." ScriptName="..sScriptName)
    f(tBase.m_MyRedisData[1].redis,ClientStart.PlatformDB_connect,DataSrc)
    tBase.Log("ExeEND_ScriptName="..sScriptName)
end

--文件读取
function LuaScrip.ReadFile(Path)
    local file = io.open(Path,"r+")
    if file then 
        local Content = file:read("*all")
        io.close(file)
        return Content
    end
    return "nil"
end

--文件写入
function LuaScrip.WriteFile(Content,Path,mode)
    mode = mode or "a+"
    Path = "./lua/public/"..Path.."" or Path 
    tBase.Log("PathPath="..Path)
    local file = io.open(Path, mode)
    if file then
        if file:write(Content) == nil then 
            return false
        end
        io.close(file)
        return true
    else
        return false
    end
end

--文件大小
function LuaScrip.FileSize(Path)
    local size = false
    local file = io.open(Path,"r+")
    if file then 
        local current = file:seek()
        size = file:seek("end")
        file:seek("set",current)
        io.close(file)
    end
    return size
end

--文件存在
function LuaScrip.FileExists(Path)
    local file = io.open(Path,"r")
    if file then 
        io.close(file)
        return true
    end
    return false
end
   

return LuaScrip