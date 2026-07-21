
package.path = "../lua/base/logging/?.lua;./lua/base/logging/?.lua;" .. package.path
local tBase  = require("base")         -- 基础功能接口
require"logging.file"
local tlogging = require("logging") -- 日志等级接口

logger = {}
Logger = logger
Log = logger
function logger.SetFile(sDir, sExt, mm)
    local logTmp = logging.file(sDir, sExt, mm)
    setmetatable(logger, logTmp)
    logTmp.__index = logTmp
    logger.LogObject =  tlogging
	logger.logTmp =logTmp
end
function logger:error(sExt)
	logger.logTmp:error(sExt)
	tBase._OnMonitorInfo(sExt)
end

function logger.Info(sExt)
	logger:info(sExt)
end

function logger.Debug(sExt)
	logger:debug(sExt)
end

function logger.Error(sExt)
	logger:error(sExt)
end

function logger.Warn(sExt)
	logger:warn(sExt)
end

function logger.Fatal(sExt)
	logger:fatal(sExt)
end



return logger