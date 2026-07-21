
EventB = 
{
	__newindex = function(tb, key, value)	
		if type(key) == "number" and type(value) == "function" then
			rawset(tb, key, {})
			local o = {}
			o.__call = function(t, ...) 
				for i=1, #tb[key] do
					tb[key][i](...)
				end
			end
			o.__add = function(t, fun)
				table.insert(t, fun)
				return t
			end
			setmetatable(tb[key], o)
		else
			rawset(tb, key, value)
			
			tb.RegistEvent = function(nEventId, func)
				if tb[nEventId] == nil then
					tb[nEventId] = func
				end
				tb[nEventId]= tb[nEventId] + func
			end
			
			tb.Call = function (nEventId, ...)
				tb[nEventId](...)
			end
		end	
	end
}

EventIo = {}

function EventIo.New()
	local t = setmetatable({}, EventB)
	t.new = function() print("event start") end
	return t, t.new()
end

return EventIo

