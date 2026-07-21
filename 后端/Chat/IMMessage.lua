-- IM 即时通讯  
local http  = require("socket.http")  -- Http 服务器 
local cjson = require("cjson")   
local tBase64 = require("BaseSink")    -- base 编码解码

IMMessage = { 
    sUrl ="http://127.0.0.1:8888/api/IMServer/",
}


-- URI 解码
local function decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end
-- URI 编码
local function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "%%20")
end

-- 相关文档参考: https://doc.yunxin.163.com/docs/TM5MzM5Njk/jc2NDgzMTg?platformId=60353#%E5%88%9B%E5%BB%BA%E7%BE%A4

 
local function OnWebUrlReq(sUrl,isRegister)       
    local nTime = tBase.GetTime() 
    local sResult = http.request(sUrl)   
    local isSuccee,tRlt = pcall(cjson.decode,sResult)
    if not isSuccee then 
        local SendSMS = string.format("IM即时通讯  解析失败 sResult=%s,sUrl:%s",sResult,sUrl)
        tBase._OnMonitorInfo(SendSMS)
        if not isRegister then 
            tBase.Log(SendSMS)
        end 
        return false,{}
    end   
    local nCode = tonumber(tRlt.code) 
    local sMsg = tRlt.msg
    local nNow = tBase.GetTime() - nTime
    -- tBase.Log("_OnWebUrlReq   %d 毫秒",nNow)    
    if nCode == 200 and sMsg == "success" then 
        return true,tRlt
    end   
    return false,tRlt
end

-- 异步请求
local function _OtherRequest(sUrl)   
	local funcRes = function(sData,nCode)  
		local isSuccee,tRlt = pcall(cjson.decode,sData) 
		if not isSuccee then 
			local SendSMS = string.format("_OtherRequest 解析失败  %s  sUrl: %s ",sData,sUrl)
            tBase._OnMonitorInfo(SendSMS) 		
			return  
		end 	          
        if tonumber(tRlt.code)  == 200 and tRlt.msg == "success" then 
            return true,tRlt
        end  
        return false,tRlt
	end	
	local funcErr = function(nCode)
		tBase.Log("_OtherRequest   funcErr  nCode: %s ",nCode)
	end 
	return HttpNB.request(sUrl,funcRes,funcErr,"GET","") 
end

function IMMessage.LoadUrlConfig()    
    local sKey = "IMAppWebKey"
	local tRedis =tBase.m_MyRedisData[2].redis 
    local sUrl = tRedis:hget(sKey,"url") 
    if not sUrl or #sUrl < 10 then 
        local SendSMS = string.format("IM即时通讯, IMAppWebKey sUrl 没有配置！")
        tBase._OnMonitorInfo(SendSMS)
        Base.SetTimer(60001,1000*60,1,IMMessage.LoadUrlConfig)           
        return
    end 
    IMMessage.sUrl = sUrl
    Base.SetTimer(60001,1000*60*5,1,IMMessage.LoadUrlConfig)   
    -- Base.SetTimer(60001,1000*5,1,IMMessage.LoadUrlConfig)    
end 

-- 创建群 
-- function IMMessage.CreateIMGroup(accid)    
--     local nTime = tBase.GetTime()
--     local sBody = string.format("CreateRoom?tname=%s&owner=%s&msg=%s",accid,accid,accid)    
--     local sUrl =IMMessage.sUrl..sBody  
--     local isSuccee,tRlt = OnWebUrlReq(sUrl) 
--     if isSuccee then 
--         return tonumber(tRlt.tid)
--     end 
--     local slog = ""
--     if tonumber(tRlt.code) == 806 then     --  创建群数量达到限制 
--         slog = "创建群数量达到限制"
--     end 
--     local SendSMS = string.format("IM_创建群组失败 %s  accid: %s  %s ",slog,accid,cjson.encode(tRlt))   
--     tBase._OnMonitorInfo(SendSMS)
--     tBase.Log("_CreateIMGroup %s  sUrl: %s  ",SendSMS,sUrl)  
--     return 
-- end

-- 解散群
-- function IMMessage.DeleteIMGroup(tid,accid)   
--     local sBody = string.format("DissolutionRoom?tid=%s&owner=%s",tid,accid)   
--     local sUrl =IMMessage.sUrl..sBody  
--     local isSuccee,tRlt = _OtherRequest(sUrl)  
--     if isSuccee then 
--         return isSuccee 
--     end 
--     local SendSMS = string.format("IM_解散群失败 accid: %s tid_%d  : %s ",accid,tid,cjson.encode(tRlt))   
--     tBase._OnMonitorInfo(SendSMS)
--     tBase.Log("_DeleteIMGroup %s  sUrl: %s  ",SendSMS,sUrl)   
--     return false 
-- end
 
-- 加群 
-- function IMMessage.JoinIMGroup(tid,sTable_accid,accid)   
--     local sBody = string.format("JoinRoom?tid=%s&owner=%s&uid=%s&msg=%s",tid,sTable_accid,accid,sTable_accid) 
--     local sUrl =IMMessage.sUrl..sBody  
--     local isSuccee,tRlt = OnWebUrlReq(sUrl) 
--     if isSuccee then 
--         return true 
--     end 
--     if tonumber(tRlt.code) == 809 then     --  已经在群内
--         tBase.Log("_JoinIMGroup   已经在群内 accid_%s  tid: %s  ",accid,tid)   
--         return true 
--     end 
--     local SendSMS = string.format("IM_加群失败 accid: %s tid_%d  sTable_accid: %s  tRlt: %s ",accid,tid,sTable_accid,cjson.encode(tRlt))   
--     tBase._OnMonitorInfo(SendSMS)
--     tBase.Log("_JoinIMGroup %s  sUrl: %s  ",SendSMS,sUrl)    
--     return false
-- end

-- 踢出群 
-- function IMMessage.KickIMGroup(tid,sTable_accid,Kick_accid)   
--     local sBody = string.format("KickUserRoom?tid=%s&owner=%s&kickAccids=%s",tid,sTable_accid,Kick_accid)
--     local sUrl =IMMessage.sUrl..sBody  
--     local isSuccee,tRlt = OnWebUrlReq(sUrl) 
--     if isSuccee then 
--         return true 
--     end 
--     local SendSMS = string.format("IM_踢出群失败 tid: %s Kick_accid_%s  sTable_accid: %s  tRlt: %s ",tid,Kick_accid,sTable_accid,cjson.encode(tRlt))   
--     tBase._OnMonitorInfo(SendSMS)
--     tBase.Log("_KickIMGroup %s  sUrl: %s  ",SendSMS,sUrl)   
--     return false
-- end

local function GetNickName(sNickName)
    if sNickName then             
        sNickName=tBase64.decode(sNickName)     -- 先解码
        if #sNickName >= 63 then 
            sNickName =  string.sub(sNickName,1,63)    
        end 
        -- 处理 特殊字符变  * 号 
        local function Check_String_Special(str) 
            str =  string.gsub(str, "\\","*")    -- 处理 ’
            str =  string.gsub(str, "'", "*")    -- 处理 ’
            str =  string.gsub(str, "%%", "*")   -- 处理 % 
            str =  string.gsub(str, "/", "*")    -- 处理 /
            str =  string.gsub(str, "“", "*")    -- 处理 “
            str =  string.gsub(str, "”", "*")    -- 处理 ”
            str =  string.gsub(str, "%b“”", "*")   -- 处理 “” 
            -- str =  string.gsub(str, " ", "*")   -- 处理 “” 
            return str
        end
        sNickName = Check_String_Special(sNickName)
        sNickName=encodeURI(sNickName)            
    end    
    return sNickName
end

-- 注册 
-- function IMMessage.RegisterAccount(nUserId,sNickName,sFaceID) 
--     sNickName = GetNickName(sNickName)
--     local sBody = string.format("RegisterAccount?accid=%s&name=%s&headUrl=%s",nUserId,sNickName,sFaceID)       
--     local sUrl =IMMessage.sUrl..sBody
--     local isSuccee,tRlt = OnWebUrlReq(sUrl,true) 
--     if isSuccee then 
--         return tRlt
--     end    
--     local SendSMS = string.format("IM_注册失败 nUserId: %s  %s ",nUserId,cjson.encode(tRlt))     
--     if tonumber(tRlt.code) == 414 and tRlt.msg == "already register" then     -- 已注册, 重新刷新token 
--         local isSuccee,tRlt = IMMessage.Token_Update(nUserId) 
--         if isSuccee then 
--             tBase.Log("_RegisterAccount  nUserId: %s 已注册,重新刷新token: %s ",nUserId,tRlt.token)
--             return tRlt
--         end             
--         SendSMS = string.format("IM_已注册,刷新token失败 nUserId: %s  %s ",nUserId,cjson.encode(tRlt))   
--     end         
--     tBase._OnMonitorInfo(SendSMS)
--     tBase.Log("_RegisterAccount %s  sUrl: %s  ",SendSMS,sUrl) 
--     return nil   
-- end

-- 刷新 token 
function IMMessage.Token_Update(accid)   
    local sBody = string.format("UpdateToken?accid=%s",accid)   
    local sUrl =IMMessage.sUrl..sBody
    local isSuccee,tRlt = OnWebUrlReq(sUrl) 
    if isSuccee then 
        return true,tRlt 
    end   
    return false,tRlt
end
 
-- 获取用户信息
function IMMessage.GetAccid_UserInfo(accid)   
    local sBody = string.format("Account?accid=%s",accid)   
    local sUrl =IMMessage.sUrl..sBody
    local isSuccee,tRlt = OnWebUrlReq(sUrl) 
    if isSuccee then 
        return true,tRlt 
    end   
    tBase.Log("_GetAccid_UserInfo  sUrl_%s  没有用户信息  tRlt_%s    ",sUrl,cjson.encode(tRlt)) 
    return false,tRlt
end
 
-- 更新用户信息
function IMMessage.Update_UserInfo(nUserId,sNickName,sFaceID)    
    local accid = string.format("game_accid_%d",nUserId) 
    local isSuccee,tRlt = IMMessage.GetAccid_UserInfo(accid)  
    if not isSuccee then 
        tBase.Log("_Update_UserInfo  nUserId_%s  没有用户信息  tRlt_%s    ",nUserId,cjson.encode(tRlt)) 
        return 
    end    
    local sName=tBase64.decode(sNickName)     -- 先解码
    if tRlt.name ~= sName then 
        sNickName = GetNickName(sNickName)        
        local sBody = string.format("UpdateAccount?accid=%s&name=%s&headUrl=%s",accid,sNickName,sFaceID)       
        local sUrl =IMMessage.sUrl..sBody 
        local isSuccee,tRlt = OnWebUrlReq(sUrl)    
    end 
end 
 
-- 获取用户加入群组 
function IMMessage.GetUserJoinGroup(nUserId)
    local sUrl = IMMessage.sUrl.."GetJoinTeams?accid="..math.floor(nUserId)
    local sResult = http.request(sUrl)   
    local isSuccee,tRlt = pcall(cjson.decode,sResult)
    local arr = {}
    if isSuccee then 
        if tonumber(tRlt.count) == 0 then return arr end 
        tBase.Log("_GetUserJoinGroup   nUserId_%d  count:  %d ",nUserId,tonumber(tRlt.count)) 
        for k, v in pairs(tRlt.infos) do
            tBase.Log("_GetUserJoinGroup   owner:  %s  tid: %s ",v.owner,v.tid) 
            local tid = math.floor(v.tid)
            table.insert(arr,{tid=tid,owner = v.owner})               
        end
    end    
    return arr     
end

-- 获取群信息  
function IMMessage._GetIMGroupInfo(tid)   
    local sBody = string.format("SelectUserRoom?tid=%s",tid)
    local sUrl =IMMessage.sUrl..sBody  
    local isSuccee,tRlt = _OtherRequest(sUrl) 
    if isSuccee then 
        return true,tRlt
    end 
    if tonumber(tRlt.code) == 414 and tRlt.msg ~= "success" then     -- 已注册, 重新刷新token 
        return false 
    end 
    return false
end


return IMMessage



