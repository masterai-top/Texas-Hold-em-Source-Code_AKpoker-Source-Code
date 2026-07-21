local tBase 	= require("base")   
--[[异步的消息机制，用redis的消息队列]]
AsyncEvent =  {
    EMain = 65000, -- 使用redis
    tEvent = {},
}

-- redis主协议
function AsyncEvent.InitRedisConifg(tReisConfig)
    AsyncEvent.EMain = tReisConfig.EMain
end

-- 注册事件
function AsyncEvent.RegistEvent(nEventKey, fFun)
    if type(nEventKey) ~= "number" or type(fFun) ~= "function" then
        return false
    end
    if  AsyncEvent.tEvent[nEventKey] ~= nil then
        tBase.Log("警告！异步事件注册时候:%d 有被覆盖",nEventKey)
    end
    AsyncEvent.tEvent[nEventKey] = fFun
    tBase.RegFunc(AsyncEvent.EMain,nEventKey, AsyncEvent.OnCall)

end

-- 呼叫事件
function AsyncEvent.Call(nEventKey,tData)
    local nCnt = 0
    for _, _ in pairs(tData) do
		nCnt = nCnt + 1
	end
    local s = tBase.GetSP().new(AsyncEvent.EMain, nEventKey)
    tBase.Log("%s",AsyncEvent)

	s:AddInt32(nCnt)
	for k, v in pairs(tData) do
		s:AddString(tostring(k))
		s:AddString(tostring(v))
	end
	tBase.PostToServer(tBase.m_tKey, 1, s:GetData(), s:GetSize())
end

-- 这是异步事件机制响应
function AsyncEvent.OnCall(nClientID, sData, nLen)
    local ReadData = tBase.GetRP().new(sData, nLen)
    local nMainId = ReadData:GetModuleID()
    local nSubId = ReadData:GetMsgID()
    tBase.Log("OnCall MainId:%d, SubID:%d", nMainId, nSubId)
  
    if  nMainId == AsyncEvent.EMain then
        local tData = AsyncEvent.GetEventData(sData, nLen)
        AsyncEvent.tEvent[nSubId](tData)
    end
end


function AsyncEvent.GetEventData(sData, nLen)
	local ReadData = base.GetRP().new(sData, nLen)
    local nMainId = ReadData:GetModuleID()
    local nSubId = ReadData:GetMsgID()

    local nCnt = ReadData:GetInt32()
    local tRet = {}
    for i=1, nCnt do 
    	local k = ReadData:GetString()
    	local v = ReadData:GetString()
    	tRet[k] = v
    end
    return tRet 
end


function AsyncEvent:Log()
    tBase.Log("I Am AsyncEvent")
end

return AsyncEvent