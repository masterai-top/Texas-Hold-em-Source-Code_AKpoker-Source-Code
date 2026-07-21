local mlogger = require("logger")
PrivateLog = {}

-- PrivateLog
function PrivateLog:New()
	local t = {}
	setmetatable(t, self)
    self.__index = self
    t.sLogFlag = ""
	return t
end

-- 设置日志输出对象
function PrivateLog:SetLogFlag(tTableObj)
    self.sLogFlag = string.format( "%s",tTableObj )
end

-- 构造日志标识
function PrivateLog:MakeFlag()
    local skey = ""
    skey = string.format( "[%s]",self.sLogFlag )
    return skey
end

-- 日志输出 -- 多参数混合使用

function PrivateLog:info(...)
    local arg = {...}
    if #arg == 1 then -- 单参数 
        local  sLogData = arg[1]
        mlogger:info(self:MakeFlag()..sLogData)
    elseif #arg == 2 then
        local tTableObj = arg[1]
        local sLogData = arg[2]
        self:SetLogFlag(tTableObj)
        mlogger:info(self:MakeFlag()..sLogData)
    end
end

function PrivateLog:info2(formatstr, ...)
    local arg = {...}
    --local sLogData = string.format(formatstr, table.unpack(arg))
    --mlogger:info(self:MakeFlag()..sLogData)
    function tpLog(e)
        local kl = base.GetKernel()
        local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)
        km:Log(e)
        km:Log(debug.traceback())
        return e
    end
    local f =function ()
        local sLogData = string.format(formatstr, table.unpack(arg))
        mlogger:info(self:MakeFlag()..sLogData)
    end
    local ok, msg = xpcall(f, tpLog)
    if not ok then
        mlogger:error(msg)
    end
end

function PrivateLog:debug(...)
    local arg = {...}
    if #arg == 1 then -- 单参数 
        local  sLogData = arg[1]
        mlogger:debug(self:MakeFlag()..sLogData)
    elseif #arg == 2 then
        local tTableObj = arg[1]
        local sLogData = arg[2]
        self:SetLogFlag(tTableObj)
        mlogger:debug(self:MakeFlag()..sLogData)
    end
end


function PrivateLog:error(...)
    local arg = {...}
    if #arg == 1 then -- 单参数 
        local  sLogData = arg[1]
        mlogger:error(self:MakeFlag()..sLogData)
    elseif #arg == 2 then
        local tTableObj = arg[1]
        local sLogData = arg[2]
        self:SetLogFlag(tTableObj)
        mlogger:error(self:MakeFlag()..sLogData)
    end
end

function PrivateLog:warn(...)
    local arg = {...}
    if #arg == 1 then -- 单参数 
        local  sLogData = arg[1]
        mlogger:warn(self:MakeFlag()..sLogData)
    elseif #arg == 2 then
        local tTableObj = arg[1]
        local sLogData = arg[2]
        self:SetLogFlag(tTableObj)
        mlogger:warn(self:MakeFlag()..sLogData)
    end
end

function PrivateLog:fatal(...)
    local arg = {...}
    if #arg == 1 then -- 单参数 
        local  sLogData = arg[1]
        mlogger:fatal(self:MakeFlag()..sLogData)
    elseif #arg == 2 then
        local tTableObj = arg[1]
        local sLogData = arg[2]
        self:SetLogFlag(tTableObj)
        mlogger:fatal(self:MakeFlag()..sLogData)
    end
end

return PrivateLog