
package.path = "../lua/base/?.lua;./lua/base/?.lua;" .. package.path

thread = {}
 -- 创建协程
thread.coroutine_pool = setmetatable({}, { __mode = "kv" })

--[[
function thread.co_create(f, ...)
    if arg ~= nil then  
        arg = { ... }  
    end
	local co = table.remove(thread.coroutine_pool)
	if co == nil then
		co = coroutine.create(function(f, tt)

            local m = require("base")

            while true do                

                m.Heartpackage()

                if unpack ~= nil then -- 5.1及之前的版本  
                    -- f(unpack(tt))  
                    local status, err = pcall(f, unpack(tt))
                    if (err ~= nil) then
                        print("co_create err:"..err.."\n")
                        m.SetLogPath("./log/Module/"..m.GetPort().."-"..m.GetThreadIndex(), "lo")
                        m.Log("Error"..err)
                    end
                else -- 之后的版本 
                    -- f(table.unpack(tt))  
                    local status, err = pcall(f, table.unpack(tt))
                    if (err ~= nil) then
                        print("co_create err:"..err.."\n")
                        m.SetLogPath("./log/Module/"..m.GetPort().."-"..m.GetThreadIndex(), "lo")
                        m.Log("Error"..err)
                    end
                end
                thread.coroutine_pool[#thread.coroutine_pool+1] = co
                f, tt = coroutine.yield()

                if f == 0 then
                    break
                end

			end
		end)
	end

    if unpack ~= nil then -- 5.1及之前的版本          
        --f(unpack(arg))
        coroutine.resume(co, f, arg)
    else -- 之后的版本  
        local arg = { ... }  
        --f(table.unpack(arg))
        coroutine.resume(co, f, arg)
    end
end
]]

function thread.GetIdx()
    if thread.nIdx == nil then
        thread.nIdx = 0
    end

    if thread.nIdx > 0xFFFFF then
        thread.nIdx = 0
    end

    thread.nIdx = thread.nIdx + 1
    return thread.nIdx
end

function thread.co_create(f, ...)
    local arg = { ... }  

    local m = require("base")    

    function tpLog(e)
        local nIdx = thread.GetIdx()
        m.Log("Error%d:========================================", nIdx)
        local sPath, sFile = m.GetLogPath()
        m.Log("ErrorMsg:"..e)
        m._OnMonitorInfo(string.gsub(e,'#', '参数'),ServerInfo.nServerId)
        m.Log("Error%d: %s \n %s", nIdx, debug.traceback(), e)
        m.Log("Error%d:========================================", nIdx)

        m.SetLogPath("./log/Module/"..m.GetPort().."-"..m.GetThreadIndex(), "lo")
        m.Log("ErrorMsg:"..e)
        m.Log("Error%d: %s \n %s", nIdx, debug.traceback(), e)

        m.SetLogPath(sPath, sFile)
        return e
    end

    if unpack ~= nil then -- 5.1及之前的版本  
        -- f(unpack(tt))  
        xpcall(f, tpLog, unpack(arg))
    else -- 之后的版本 
        -- f(table.unpack(tt))  
        xpcall(f, tpLog, table.unpack(arg))
    end

end

-- 关闭所有协程
function thread.CloseAllCoroutine()

    for i=1, #(thread.coroutine_pool) do  
        coroutine.resume(thread.coroutine_pool[i], 0, 0)
    end 

end

return thread
