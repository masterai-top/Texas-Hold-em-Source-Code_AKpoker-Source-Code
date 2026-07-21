package.path                    = "../lua/base/?.lua;./lua/base/?.lua;" .. package.path
package.path                    = "../lua/base/socket/?.lua;./lua/base/socket/?.lua;" .. package.path
package.path                    = "../lua/public/?.lua;./lua/public/?.lua;" .. package.path
package.path                    = "../lua/base/luasec/?.lua;./lua/base/luasec/?.lua;" .. package.path

local api                       = require("publicApi")
local redis                     = require("redis")
local tname                     = require("typename") -- 类弄定义接口
local sk                        = require("socket")
local dbInfo                    = require("DBInfo")   -- 数据库连接信息
local tSrvInfo                  = require("ServerInfo")
local tCHashing                 = require("ConsistentHashing")
local http                      = require("socket.http")
local cjson                     = require("cjson")
local tSCfg                     = require("SetingConfig")
local tNMess                    = require("NoticeMess")


base                            = {}
Base                            = base
----------------------------------------------------------------------------------------
-- 底层用的定时器ID(小于1000)，上层设计时不能占用
base.m_wTimer_ID_Min            = 1  -- 底层定时器最小值
base.m_wTimer_ID_Heart          = 10 -- 心跳包定时器
base.m_wTimer_ID_Rand           = 11 -- 随机种子定时器
base.m_wTimer_ID_Reconnection   = 12 -- 重连Redis定时器
base.m_wTimer_ID_PersecCheck    = 13 -- 每秒检测的定时器
base.m_wTimer_ID_Collectgarbage = 14 -- 垃圾回收的定时器
base.m_wTimer_ID_GetServerList  = 15 -- 获取服务器列表的定时器

base.m_wTimer_ID_StartServer    = 16 -- 开服后操作 的定时器

base.m_wTimer_ID_LiveGameResit  = 17 -- 直播游戏 主从关系 定时器
base.m_wTimer_ID_LogonToCenter  = 18 -- 直播游戏 主从关系 定时器
base.m_wTimer_ID_CenterServId   = 19 -- 直播游戏 主从关系 定时器
base.m_wTimer_ID_CenterServKey  = 20 -- 直播游戏 主从关系 定时器
base.m_wTimer_ID_Memory         = 21 -- 开服后操作  内存统计




base.m_wTimer_ID_Max = 1000 -- 底层定时器最大值

----------------------------------------------------------------------------------------
base.m_CallBackIndex = 0                           -- 回调函数索引
base.m_tKey = ""                                   -- 代表本服务器的标识
base.m_tType = ""                                  -- 服务器类型
base.m_centerRedis = {}                            -- 中心redis
base.m_IP = ""                                     -- 本机IP
base.m_sha = {}                                    -- redis脚本
base.m_OldSinkFunc = nil                           -- 用本服务器key作为频道时的回调函数（旧方式）
base.m_MyRedisData = {}                            -- 用户自用的redis数据库
base.m_arrDelayClose = {}                          -- 延迟关闭客户端数组
base.m_arrServerList = {}                          -- 服务器列表
--base.m_arrServerHashing = {}    -- 服务器列表对应的一致性哈希算法
base.m_FK = "E13B1417CBD147F9BB64C53E638BA427"     -- 附加数据KEY
base.m_Flist = "1F7B948C50EC47BB9D87C397C1BB6565_" -- 附加列表KEY
base.m_DBTime = 0                                  --DB服服务器时间
base.m_cmpTime = 0                                 --DB服务器和本地时间差

base.m_CountTime = 0
--兼容
if not table.pack then
    function table.pack(...)
        return { n = select("#", ...), ... }
    end
end
--兼容
if not table.unpack then
    table.unpack = unpack
end

-- 生产回调函数ID
function base.generate_func_id()
    base.m_CallBackIndex = base.m_CallBackIndex + 1
    return base.m_CallBackIndex
end

-- 设置回调函数
function base.create_callback_table(fn, name)
    local t = {}
    t.callback = fn
    setmetatable(t, {
        __call =                       -- 关注__call
            function(func, ...)        -- 在t(xx)时，将调用到这个函数
                if func.callback ~= nil then
                    func.callback(...) -- 真正的回调
                end
                --del_callback (name) -- 回调完毕，清除wrap建立的数据
            end
    })
    return t
end

-- 设置回调函数
function base.wrap(fn)
    local id = base.generate_func_id() -- 产生唯一的id
    local fn_s = "_callback_fn" .. id

    if fn == nil then error("invalid input") end
    _G[fn_s] = base.create_callback_table(fn, fn_s) -- _G[fn_s]对应的是一个表
    return fn_s
end

-- 返回回调函数
function base.GetFuncByName(name)
    return _G[name]
end

-- 返回核心接口
function base.GetKernel()
    return RM_8B56314062A74ABD9F943700C6D07486
end

-- 返回线程索引
function base.GetThreadIndex()
    return TI_67C4F52E263F422283C040A5ABE96B31
end

-- 返回网络接口
function base.GetNetworkEngine()
    return Net_042AC81D472F49B8984E27B471123EB5
end

-- 返回解释数据接口
function base.GetRP()
    return RP_437298BD4BB04659AA7F7918B6065421
end

-- 返回发送数据接口
function base.GetSP()
    return SP_AA72D5F10D7743BDAF54EF1F9E6E3B87
end

-- 返回服务器端口号
function base.GetPort()
    return PO_F05ADA09A24341BE9E76845C32DAA596
end

-- 返回Int64数据类型类
function base.GetInt64()
    return Int64_22B4A82EC1264817AF8A995DF22CA66F
end

-- 返回MySQL接口
function base.GetMySQL()
    return mysql_427F56073F604A338B2FE790AB2A825A
end

-- 返回队列发送对象
function base.GetQueue()
    return Queue_E1989A69093D4002BC9CE34F025361B6
end

-- 返回队列消收对象
function base.GetMsgRecv()
    return MyRedis_198BBDC36C2C4C33AA80C462D2E95F31
end

-- 返回日志对象
function base.GetLogObject()
    return LOG_003501BF4D4F408A8D1EFED467DAEF9B
end

-- 注册协议回调
function base.RegFunc(MainID, SubID, funcSink)
    local kl = base.GetKernel()
    local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)

    -- 先清空全局函数表项
    local sFun = km:GetFunC(MainID, SubID)
    if sFun ~= "" then
        _G[sFun] = nil
    end

    km:RegFunc(MainID, SubID, base.wrap(funcSink))
    km = nil
end

-- 获取注册函数
function base.GetFunC(MainID, SubID)
    local kl = base.GetKernel()

    local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)
    local sFuncName = km:GetFunC(MainID, SubID)
    km = nil

    if sFuncName ~= "" then
        return base.GetFuncByName(sFuncName)
    end

    return nil
end

-- 注册定时器
function base.SetTimer(TimerID, Elapse, Repeat, funcSink, bBaseTimer)
    local nMinID, nMaxID = 0, 0

    if bBaseTimer ~= nil and bBaseTimer == true then
        nMinID = base.m_wTimer_ID_Min
        nMaxID = base.m_wTimer_ID_Max
    else
        nMinID = base.m_wTimer_ID_Max + 1
        nMaxID = 65535
    end

    if TimerID < nMinID or TimerID > nMaxID then
        assert(false)
    end

    base.KillTimer(TimerID, bBaseTimer)

    local kl = base.GetKernel()
    local ti = base.GetThreadIndex()

    local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)
    km:SetTimer(ti, TimerID, Elapse, Repeat, base.wrap(funcSink))
    km = nil
end

-- 定时器传参用法
function base.TokenCallTimeID(nTimerID, nMSeconds, nCount, fFunc, ...)
    local arrP = table.pack(...)
    local tmpF = function()
        fFunc(table.unpack(arrP))
        --base.Log("Base_TimeID:"..nTimerID.." nMSeconds:"..nMSeconds.." nCount:"..nCount)
    end
    base.SetTimer(nTimerID, nMSeconds, nCount, tmpF)
end

-- 删除定时器
function base.KillTimer(TimerID, bBaseTimer)
    local nMinID, nMaxID = 0, 0

    if bBaseTimer ~= nil and bBaseTimer == true then
        nMinID = base.m_wTimer_ID_Min
        nMaxID = base.m_wTimer_ID_Max
    else
        nMinID = base.m_wTimer_ID_Max + 1
        nMaxID = 65535
    end

    if TimerID < nMinID or TimerID > nMaxID then
        assert(false)
    end

    local kl = base.GetKernel()
    local ti = base.GetThreadIndex()

    local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)

    -- 先清空全局函数表项
    local sFun = km:GetTimerFun(ti, TimerID)
    if sFun ~= "" then
        _G[sFun] = nil
    end

    km:KillTimer(ti, TimerID)

    km = nil
end

-- 主动断开客户
function base.CloseClient(ClientID)
    local kl = base.GetKernel()
    local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)
    km:CloseClient(base.GetNetworkEngine(), ClientID)
    km = nil
end

-- 延迟关闭客户端
function base.DelayClose(ClientID, nSec)
    local t = {}
    t.ClientID = ClientID
    t.CloseTime = os.time() + nSec
    table.insert(base.m_arrDelayClose, t)
end

--执行数据库操作
function base.rows(connection, sql_statement)
    local cursor = assert(connection:execute(sql_statement))
    return function()
        return cursor:fetch()
    end
end

-- 设置日志目录和文件名
function base.SetLogPath(path, name)
    local kl = base.GetKernel()
    local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)
    km:SetLogPath(path, name)
end

function base.GetLogPath()
    local kl = base.GetKernel()
    local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)
    local tInfo = km:GetLogPath()
    km = nil

    --[1]=path, [2]=file
    return tInfo[1], tInfo[2]
end

-- 记录日志
function base.Log(formatstr, ...)
    local arg = { ... }
    function tpLog(e)
        local kl = base.GetKernel()
        local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)
        km:Log(e)
        km:Log(debug.traceback())
        return e
    end

    local f = function()
        local sData = ""
        if #arg > 0 then
            sData = string.format(formatstr, table.unpack(arg))
        else
            sData = tostring(formatstr)
        end
        local kl = base.GetKernel()
        local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)
        km:Log(sData)
        km = nil
    end
    xpcall(f, tpLog)
end

local function _table_serialize(pTable)
    local tp = type(pTable)
    if tp == 'string' then
        return string.format('%q', pTable)
    elseif tp ~= 'table' then
        return tostring(pTable)
    end
    local kvPairs = {}
    local ks, vs
    for k, v in pairs(pTable) do
        tp = type(k)
        vs = _table_serialize(v)
        if vs == nil then return end
        ks = tp == 'number' and string.format('[%d]', k) or string.format('["%s"]', k)
        table.insert(kvPairs, ks .. '=' .. vs)
    end
    return "{" .. table.concat(kvPairs, ',') .. "}"
end
base.tostring = _table_serialize
function base.LogT(...) --不支持格式化，但可以接受所有类型的参数进行打印(包括table)
    local str = ""
    for _, v in pairs({ ... }) do
        if type(v) ~= 'table' and type(v) ~= 'boolean' then
            str = str .. v
        else
            str = str .. base.tostring(v)
        end
    end
    base.Log(str)
end

function _decoTable(tStr, tData, fkey)
    fkey = fkey or ""
    if "table" == type(tData) then
        if tData._setter ~= nil then
            local tBuild = {}
            for m_key, m_val in pairs(tData._setter) do
                if "string" == type(m_key) and ("number" == type(tData[m_key]) or "string" == type(tData[m_key]) or "boolean" == type(tData[m_key])) then
                    tBuild[m_key] = Base._Constval(tData[m_key])
                elseif "string" == type(m_val) or "number" == type(m_val) then
                    local newVal = {}
                    newVal[#newVal + 1] = Base._Constval(m_val)
                    tStr[m_key] = newVal
                elseif "table" == type(tData[m_key]) then
                    if nil == tData[m_key]._setter then
                        local setTable = {}
                        for n_key, n_val in pairs(tData[m_key]) do
                            if "table" ~= type(n_val) and "function" ~= type(n_val) then
                                local newVal2 = Base._Constval(n_val)
                                setTable[#setTable + 1] = newVal2
                            end
                        end
                        tStr[m_key] = setTable
                    else
                        _decoTable(tStr, tData[m_key], m_key)
                    end
                else
                    tStr[m_key] = Base._Constval(tData[m_key])
                end
            end
            if fkey then tStr[fkey] = tBuild end
        end
    end
end

Base.BuildT = _decoTable --构建可序化结构

Base._Constval = function(descriptor)
    if type(descriptor) == "string" then descriptor = descriptor and descriptor or "" end
    if type(descriptor) == "number" then descriptor = descriptor and descriptor or -1 end
    if type(descriptor) == "boolean" then descriptor = descriptor and "true" or "false" end
    return descriptor or "null"
end
Base._CheckVailFiled = function(descriptor)
    if type(descriptor) ~= "table" then
        Base._Constval(descriptor)
    elseif type(descriptor) == "table" then
        for k, v in pairs(descriptor) do
            if type(v) == "table" then
                Base._CheckVailFiled(v)
            else
                descriptor[k] = Base._Constval(v)
            end
        end
    end
end

-- 设置监控频道(旧方式)
function base.MonitorChannel(func)
    base.m_OldSinkFunc = func
end

-- 心跳包定时器
function base.onTimerHeart(timerID)
    base.Heartpackage()
end

-- 垃圾回收
function base.onTimercollect(timerID)
    collectgarbage("collect")
    base.SetTimer(base.m_wTimer_ID_Collectgarbage, 1000 * 300, 1, base.onTimercollect, true)
end

-- 重连redis定时器
function base.onTimerReconnection(timerID)
    local err = 0

    -- 重连中心服务器
    if (base.m_centerRedis.Mo == nil) then
        local bReconnect = false
        if base.m_tKey ~= "" then
            bReconnect = true
        end

        if base.ConnectCenter(bReconnect) == false then
            err = err + 1
        end
    end

    if (base.m_centerRedis.Mo ~= nil) then
        if base.Start() == false then
            err = err + 1
        end
    end

    if err > 0 then
        base.Log("onTimerReconnection......ing")
        base.SetTimer(base.m_wTimer_ID_Reconnection, 1000 * 5, 1, base.onTimerReconnection, true)
    end
end

-- 检测连接
function base.OnPerSecCheck(timerID)
    local nIdx = 1
    while (nIdx <= #base.m_arrDelayClose)
    do
        local t = base.m_arrDelayClose[nIdx]
        if t and os.time() >= t.CloseTime then
            base.Log("执行延迟关闭:" .. t.ClientID)
            base.CloseClient(t.ClientID)
            table.remove(base.m_arrDelayClose, nIdx)
            base.Log("延时结束1")
        else
            base.Log("延时结束2")
            nIdx = nIdx + 1
        end
    end

    base.SetTimer(base.m_wTimer_ID_PersecCheck, 1000 * 1, 1, base.OnPerSecCheck, true)
end

-- -- 发送请求
-- function base.PostData(tagkey, sqlParam)
--     if base.m_centerRedis.Mo == nil then
--         return nil
--     end
--     -- 获取全局唯一key
--     local datakey = ""
--     local nResExist = false
--     -- 测试时保留下面判断
--     datakey = base.GetUniqueKey()
--     nResExist = base.m_centerRedis.Mo:exists(datakey)
--     if (nResExist == true) then
--         print("PostData key exists!!!!!!!!!!!!!!\n")
--         return 0
--     end
--     -- 设置对方返回的key
--     sqlParam[base.m_FK] = base.m_tKey
--     -- 存入参数
--     base.m_centerRedis.Mo:hmset(datakey, sqlParam)
--     -- 设置时效
--     base.m_centerRedis.Mo:expire(datakey, 60 * 5)   -- 设置5分钟失效
--     -- 发布请求
--     return base.m_centerRedis.Mo:publish(tagkey, datakey)
-- end
-- -- 获取订阅的数据
-- function base.GetData(data, len)
--     if base.m_centerRedis.Mo == nil then
--         return nil
--     end
--     local datakey = api.udataToStr(data, len)
--     local nResExist = false
--     nResExist = base.m_centerRedis.Mo:exists(datakey)
--     if nResExist == true then
--         local sqlParam = base.m_centerRedis.Mo:hgetall(datakey)
--         base.m_centerRedis.Mo:persist(datakey) -- 设置永久有效
--         base.m_centerRedis.Mo:del(datakey)
--         return sqlParam, sqlParam[base.m_FK]
--     end
--     return nil
-- end
-- -- 随机获取某个类型的服务器发送,此接口准备废弃,以前若有使用请改之
-- function base.PostDataByType(stypename, sqlParam, ...)
--     if base.m_centerRedis.Mo == nil then
--         return nil
--     end
--     -- 获取数据源
--     local nRes = 0
--     local nTestCount = 0
--     local sKey = ""
--     repeat
--         nRes = 0
--         nTestCount = nTestCount + 1
--         sKey = base.GetSrcKey(stypename, 0, ...)
--         if sKey ~= nil then
--             nRes = base.PostData(sKey, sqlParam)
--             if nRes == 0 then
--                 -- 通过失效的方式删除
--                 base.m_centerRedis.Mo:pexpire(sKey, 1)
--                 base.Sleep(10)
--                 base.Log("--------pexpire key :%s", sKey)
--             end
--         end
--     until nRes ~= 0 or nTestCount > 3
--     return nRes
-- end
--随机获取某个类型的服务器发送 没有ClientId填0
function base.PostDatasByType(stypename, nClientId, nUserId, sData, nLen, ...)
    assert(stypename ~= nil and nClientId ~= nil and sData ~= nil and nLen ~= nil)

    local Msg = base.GetSP().new(0, 0)
    Msg:AddString(base.m_tKey)
    Msg:AddUint32(nClientId)
    Msg:AddBuff(sData, nLen)

    local sKey = ""
    sKey = base.GetSrcKey(stypename, nUserId, ...)
    if sKey ~= nil then
        return base.PostMsg(sKey .. "Gateway", Msg:GetData(), Msg:GetSize(), nUserId)
    else
        base.Log("no find:" .. stypename)
    end

    return 0
end

--根据userid获取某个类型的服务器发送
function base.PostDatasByTypeAndUID(stypename, nClientId, nUserId, sData, nLen, ...)
    assert(stypename ~= nil and nClientId ~= nil and sData ~= nil and nLen ~= nil)

    local Msg = base.GetSP().new(0, 0)
    Msg:AddString(base.m_tKey)
    Msg:AddUint32(nClientId)
    Msg:AddBuff(sData, nLen)

    -- local sKey = ""
    local sKey = base.GetUserIdSrcKey(stypename, nUserId)
    -- base.Log("根据userid获取某个类型的服务器发送 sKey_%s",sKey)
    if sKey ~= nil then
        return base.PostMsg(sKey .. "Gateway", Msg:GetData(), Msg:GetSize(), nUserId)
    else
        base.Log("no find:" .. stypename)
    end

    return 0
end

-- 获取服务器列表定时器
function base.onTimerGetServerList(timerID)
    if base.m_dwGetServerTime == nil then
        base.m_dwGetServerTime = base.GetTime()
    end

    local nTimeSpace = 1000 * 5
    if base.GetTime() - base.m_dwGetServerTime > 1000 * 60 then
        nTimeSpace = 1000 * 60 * 2
    end

    if base.m_centerRedis.Mo ~= nil then
        for k, v in pairs(tname) do
            local sServerKey = base.m_Flist .. v .. '*'
            local arrServerKey = base.m_centerRedis.Mo:keys(sServerKey)
            base.m_arrServerList[v] = {}
            for k1, v1 in pairs(arrServerKey) do
                table.insert(base.m_arrServerList[v], v1)
            end
            table.sort(base.m_arrServerList[v])
            -- 如有服务器没记启动，要加紧获取
            if base.m_arrServerList[v] == nil or next(base.m_arrServerList[v]) == nil then
                -- nTimeSpace = 1000
                -- base.Log("onTimerGetServerList fast0...")
            end
        end
    end

    -- if nTimeSpace == 1000 * 5 then
    --     base.Log("onTimerGetServerList fast1...")
    -- elseif nTimeSpace == 1000 * 60 * 2 then
    --     base.Log("onTimerGetServerList fast2...")
    -- end

    base.SetTimer(base.m_wTimer_ID_GetServerList, nTimeSpace, 1, base.onTimerGetServerList, true)
end

-- 随机获取某类型服务器key
function base.GetSrcKey(stypename, nUserId, ...)
    local arg = { ... }

    local sKey = nil

    local servertable = {}
    if nUserId ~= 0 and base.m_arrServerList[stypename] ~= nil and next(base.m_arrServerList[stypename]) ~= nil then
        local nId = nUserId % (#base.m_arrServerList[stypename]) + 1
        table.insert(servertable, base.m_arrServerList[stypename][nId])
    else
        servertable = base.m_arrServerList[stypename]
    end

    if servertable ~= nil and next(servertable) ~= nil then
        --优先寻找与本服有同样分组的服务器
        local arrServerGroupList = base.GetGroupByServerId(tSrvInfo.nServerId)
        local arrServerKey = {}
        if #arrServerGroupList > 0 then
            for k, v in pairs(servertable) do
                local nServerId = tonumber(string.match(v, "_(%d+)"))
                for _, nGroupId in pairs(arrServerGroupList) do
                    if base.HasServerGroupRelation(nServerId, nGroupId) then
                        table.insert(arrServerKey, v)
                        break
                    end
                end
            end
            -- base.LogT(stypename.." GetSrcKey arrServerGroupList:",arrServerGroupList," arrServerKey:",arrServerKey)
        end
        if #arrServerKey == 0 then --没找到与本服有同样分组的服务器,尝试在寻找无分组服务器
            local arrNotGroupServ = {}
            for k, v in pairs(servertable) do
                local nServerId = tonumber(string.match(v, "_(%d+)"))
                --判断是否属于无分组服务器
                local arrGroupList = base.GetGroupByServerId(nServerId)
                if #arrGroupList == 0 then
                    table.insert(arrNotGroupServ, v)
                end
            end
            arrServerKey = arrNotGroupServ
            -- base.LogT(stypename.." GetSrcKey arrNotGroupServ:",arrNotGroupServ)
        end

        if #arrServerKey == 0 then --没找到与本服有同样分组的服务器,也没找到无分组服务器
            arrServerKey = servertable
        end
        local lIndex = math.random(1, #arrServerKey)
        sKey = arrServerKey[lIndex]
    end

    return sKey
end

-- 根据UserId  获取某类型服务器key
function base.GetUserIdSrcKey(stypename, nUserId)
    local arrServerKey = base.m_arrServerList[stypename]
    if not arrServerKey then return nil end
    table.sort(arrServerKey)
    local sKey = nil
    local servertable = {}
    if nUserId ~= 0 and arrServerKey ~= nil and next(arrServerKey) ~= nil then
        local nId = nUserId % (#arrServerKey) + 1
        table.insert(servertable, arrServerKey[nId])
        -- base.Log("_GetUserIdSrcKey nUserId:  %d  %d  arrServerKey: %s   ",nUserId,nId,cjson.encode(arrServerKey))
    else
        servertable = arrServerKey
    end
    if servertable ~= nil and next(servertable) ~= nil then
        local lIndex = math.random(1, #servertable)
        sKey = servertable[lIndex]
    end
    return sKey
end

-- 获取某类型服务器所有key
function base.GetSrcAllKey(stypename)
    local arrServerGroupList = base.GetGroupByServerId(tSrvInfo.nServerId)
    local arrServerKey = {}
    if #arrServerGroupList > 0 then
        for k, v in pairs(base.m_arrServerList[stypename] or {}) do
            local nServerId = tonumber(string.match(v, "_(%d+)"))
            for _, nGroupId in pairs(arrServerGroupList) do
                if base.HasServerGroupRelation(nServerId, nGroupId) then
                    table.insert(arrServerKey, v)
                    break
                end
            end
        end
        -- base.LogT(stypename.." GetSrcAllKey arrServerGroupList:",arrServerGroupList," arrServerKey:",arrServerKey)
    end

    if #arrServerKey == 0 then --没找到与本服有同样分组的服务器,尝试在寻找无分组服务器
        local arrNotGroupServ = {}
        for k, v in pairs(base.m_arrServerList[stypename] or {}) do
            local nServerId = tonumber(string.match(v, "_(%d+)"))
            --判断是否属于无分组服务器
            local arrGroupList = base.GetGroupByServerId(nServerId)
            if #arrGroupList == 0 then
                table.insert(arrNotGroupServ, v)
            end
        end
        arrServerKey = arrNotGroupServ
        -- base.LogT(stypename.." GetSrcAllKey arrNotGroupServ:",arrNotGroupServ)
    end

    if #arrServerKey == 0 then --没找到与本服有同样分组的服务器,也没找到无分组服务器
        arrServerKey = base.m_arrServerList[stypename]
    end
    return arrServerKey
end

-- 获取某类型服务器所有key
function base._GetTypenameAllKey(stypename)
    return base.m_arrServerList[stypename] or {}
end

-- 心跳包定时器
function base.onTimerRand(timerID)
    local suuid = api.GetTickCount()
    math.randomseed(tonumber(suuid))
    base.Log("happy suuid:" .. suuid)
end

-- 根据 游戏id获取 服务器key
function base.GetServerIdIdKey(nServerId)
    for stypename, arrKey in pairs(base.m_arrServerList) do
        for _, sServKey in pairs(arrKey) do
            local nId = tonumber(string.match(sServKey, "_(%d+)"))
            if nServerId == nId then
                return sServKey
            end
        end
    end
    return nil
end

-- 根据 游戏id获取 服务器key
function base.GetServerId_ArrKey(nServerId)
    local arr = {}
    for stypename, arrKey in pairs(base.m_arrServerList) do
        for _, sServKey in pairs(arrKey) do
            local nId = tonumber(string.match(sServKey, "_(%d+)"))
            if nServerId == nId then
                table.insert(arr, sServKey)
            end
        end
    end
    return arr
end

-- 注册服务器
function base.RegServer(tType)
    math.random = base.Ran_dom
    _G.pcall = base.myPcall

    local suuid = api.GetTickCount()
    base.Log("happy suuid:" .. suuid)
    math.randomseed(tonumber(suuid))

    -- 本服务器心跳定时器
    base.SetTimer(base.m_wTimer_ID_Heart, 1500, -1, base.onTimerHeart, true)

    -- 设置随机种子
    base.SetTimer(base.m_wTimer_ID_Rand, 1000 * 60 * math.random(50, 60), -1, base.onTimerRand, true)

    -- 每秒定时器
    base.SetTimer(base.m_wTimer_ID_PersecCheck, 1000 * 1, 1, base.OnPerSecCheck, true)

    -- 垃圾回收
    base.SetTimer(base.m_wTimer_ID_Collectgarbage, 1000 * 60, 1, base.onTimercollect, true)

    -- 获取服务器列表
    base.SetTimer(base.m_wTimer_ID_GetServerList, 1000, 1, base.onTimerGetServerList, true)

    base.m_tType = tType
    base.m_IP = api.GetLocalIP()

    if base.ConnectCenter(false) == true then
        if (base.Start() == true) then
            return true
        end
    end

    -- 检测redis连接是否成功
    base.SetTimer(base.m_wTimer_ID_Reconnection, 1000 * 5, 1, base.onTimerReconnection, true)

    return false
end

-- 取消注册服务器
function base.UnRegServer()
    -- 关闭定时器
    base.KillTimer(base.m_wTimer_ID_Heart, true)
    base.KillTimer(base.m_wTimer_ID_Rand, true)
    base.KillTimer(base.m_wTimer_ID_Reconnection, true)

    -- 关闭队列
    base.Stop()

    -- 关闭中心redis
    -- 通过失效的方式删除
    if base.m_centerRedis.Mo ~= nil then
        base.m_centerRedis.Mo:pexpire(base.m_tKey, 1)
        base.Sleep(10)
        base.Log("--------pexpire2 key :%s", base.m_tKey)
        base.m_centerRedis.Mo:del(base.m_tKey)
        -- base.m_centerRedis.Mo:script("FLUSH")
        base.m_centerRedis.Mo = nil
    end
end

-- 连接中心服务器
function base.ConnectCenter(IsReConnect)
    base.m_centerRedis.host = dbInfo.RedisParams.center.host
    base.m_centerRedis.port = dbInfo.RedisParams.center.port
    base.m_centerRedis.pass = dbInfo.RedisParams.center.pass

    base.m_centerRedis.Mo = redis.connect(dbInfo.RedisParams.center)
    if base.m_centerRedis.Mo ~= nil then
        if #dbInfo.RedisParams.center.pass > 0 then
            base.m_centerRedis.Mo:auth(base.m_centerRedis.pass)
        end
        base.m_centerRedis.Mo:select(1)

        -- redis载入脚本，生成全局唯一key
        base.m_sha = base.m_centerRedis.Mo:script("load",
            "redis.replicate_commands();\r\n\r\nlocal prefix = '__idgenerator_';\r\nlocal partitionCount = 4096;\r\nlocal step = 3;\r\nlocal startStep = KEYS[1];\r\n\r\nlocal tag = KEYS[2];\r\nlocal partition\r\nif KEYS[3] == nil then\r\npartition = 0;\r\nelse\r\npartition = KEYS[3] % partitionCount;\r\nend\r\n\r\nlocal now = redis.call('TIME');\r\n\r\nlocal miliSecondKey = prefix .. tag ..'_' .. partition .. '_' .. now[1] .. '_' .. math.floor(now[2]/1000);\r\n\r\nlocal count;\r\nrepeat\r\n  count = tonumber(redis.call('INCRBY', miliSecondKey, step));\r\n  if count > (1024 - step) then\r\n      now = redis.call('TIME');\r\n      miliSecondKey = prefix .. tag ..'_' .. partition .. '_' .. now[1] .. '_' .. math.floor(now[2]/1000);\r\n  end\r\nuntil count <= (1024 - step)\r\n\r\nif count == step then\r\n  redis.call('PEXPIRE', miliSecondKey, 5);\r\nend\r\n\r\nreturn {tonumber(now[1]), tonumber(now[2]), partition, count + startStep}\r\n")

        if IsReConnect == false then
            local SType = ""
            if tSrvInfo.SType ~= -1 then
                SType = SType .. "_" .. tSrvInfo.SType
            end
            base.m_tKey = base.m_Flist .. base.m_tType .. base.GetUniqueKey() .. "_" .. tSrvInfo.nServerId .. SType
        end

        local nExist = base.m_centerRedis.Mo:exists(base.m_tKey)
        if nExist == false then
            base.m_centerRedis.Mo:set(base.m_tKey, base.m_tKey) -- 对应增加一个key
            base.m_centerRedis.Mo:expire(base.m_tKey, 60)       -- 设置10秒失效
            base.Log("ConnectCenter set key------%s", base.m_tKey)
        end

        base.Log("ConnectCenter succeed------")
        return true
    end

    base.m_centerRedis.Mo = nil
    base.Log("ConnectCenter error host:%s port:%d", dbInfo.RedisParams.center.host, dbInfo.RedisParams.center.port)
    return false
end

-- 更新心跳包
function base.Heartpackage()
    if base.m_centerRedis.Mo == nil then
        return nil
    end

    local nExist = base.m_centerRedis.Mo:exists(base.m_tKey)
    if nExist == false then
        base.m_centerRedis.Mo:set(base.m_tKey, base.m_tKey) -- 如果key不存，就增加一个
        base.Log("reset key -- :%s", base.m_tKey)
    end

    base.m_centerRedis.Mo:persist(base.m_tKey)    -- 更新key对应的值，防止失效
    base.m_centerRedis.Mo:expire(base.m_tKey, 60) -- 设置60秒失效
end

-- 返回分布式全局唯一KEY
function base.GetUniqueKey()
    if base.m_centerRedis.Mo == nil then
        return nil
    end

    local sRes = base.m_centerRedis.Mo:evalsha(base.m_sha, 3, base.GetThreadIndex(),
        api.GetLocalIP() .. ":" .. base.GetPort(), 123456789)
    local datakey = sRes[1] .. sRes[2] .. sRes[3] .. sRes[4]
    return datakey
end

-- 暂停函数
function base.Sleep(n)
    sk.select(nil, nil, n / 1000.0)
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- 新的发布订阅方式
-- 全局变量
base.m_Queue = {}                  -- 队列集合
base.m_Monitor = {}                -- 消息接收器
base.m_MyMonitorFun = nil          -- 消息接收自定义回调函数，如果为nil，则调用默认处理base.dispatch
base.m_MyErrorFun = nil            -- 错误处理自定义回调函数，如果为nil，则调用默认处理base.ErrorDispatch
base.m_MyTimerFun = nil            -- 定时器自定义回调函数，如果为nil，则调用默认处理base.dispatch_timer
base.m_IsSupportMultiMsgQue = true --是否支持多消息队列(多消息队列不保证接受信息的先后顺序,例：按顺序发送A B两信息，接受方不保证按顺序接受到信息)

-- 启动消息队列
function base.Start()
    local nError = 0

    local nMsgServLen = #dbInfo.RedisParams.msg
    if not base.m_IsSupportMultiMsgQue then
        nMsgServLen = math.min(nMsgServLen, 1)
    end
    -- 连接队列发送器
    for i = 1, nMsgServLen do
        if base.m_Queue[i] == nil then
            base.m_Queue[i] = {}
        end

        base.m_Queue[i].host = dbInfo.RedisParams.msg[i].host
        base.m_Queue[i].port = dbInfo.RedisParams.msg[i].port
        base.m_Queue[i].pass = dbInfo.RedisParams.msg[i].pass

        if (base.m_Queue[i].Mo == nil) then
            base.m_Queue[i].Mo = base.GetQueue().new()
            local nRes = base.m_Queue[i].Mo:connect(dbInfo.RedisParams.msg[i].host, dbInfo.RedisParams.msg[i].port,
                dbInfo.RedisParams.msg[i].pass)
            if nRes == 0 then
                base.m_Queue[i].Mo = nil
                base.Log("Queue connect err, host:%s, port:%d", dbInfo.RedisParams.msg[i].host,
                    dbInfo.RedisParams.msg[i].port)
                nError = nError + 1
            else
                base.Log("Queue connect succeed, host:%s, port:%d", dbInfo.RedisParams.msg[i].host,
                    dbInfo.RedisParams.msg[i].port)
            end
        end
    end

    -- 连接用户自用数据redis
    if base.MyRedisDataConnect() == false then
        nError = nError + 1
    end

    -- 连接队列监控器
    local tChannels = {}
    tChannels[1] = base.m_tKey .. "Gateway"
    tChannels[2] = base.m_tKey

    if base.MonitorConnect(tChannels) == false then
        nError = nError + 1
    end

    if (nError > 0) then
        return false
    end

    return true
end

-- 关闭消息队列
function base.Stop()
    -- 关闭myredis
    for k, v in pairs(base.m_MyRedisData) do
        if base.m_MyRedisData[k] ~= nil then
            base.m_MyRedisData[k] = nil
        end
    end

    -- 关闭队列发送器
    for i = 1, #base.m_Queue do
        if (base.m_Queue[i] ~= nil) then
            if (base.m_Queue[i].Mo ~= nil) then
                base.m_Queue[i].Mo:close()
            end
            base.m_Queue[i] = nil
        end
    end

    local kl = base.GetKernel()
    -- 连接队列接收器
    for k, v in pairs(base.m_Monitor) do
        if (base.m_Monitor[k].Mo ~= nil) then
            base.m_Monitor[k].Mo:close(kl)
            base.m_Monitor[k].Mo = nil
        end
    end
end

-- 消息接收处理
function base.MonitorConnect(tChannels)
    local kl = base.GetKernel()
    local ti = base.GetThreadIndex()

    -- 选择处理函数
    local pFunc = nil
    if (base.m_MyMonitorFun ~= nil) then
        pFunc = base.m_MyMonitorFun
    else
        pFunc = base.dispatch
    end

    local sChennels = ""
    for i = 1, #tChannels do
        sChennels = sChennels .. tChannels[i]
        if i < #tChannels then
            sChennels = sChennels .. " "
        end
    end

    local err = 0

    for nIndex = 1, #dbInfo.RedisParams.msg do
        if base.m_Monitor[nIndex] == nil then
            base.m_Monitor[nIndex] = {}

            base.m_Monitor[nIndex].host = dbInfo.RedisParams.msg[nIndex].host
            base.m_Monitor[nIndex].port = dbInfo.RedisParams.msg[nIndex].port
            base.m_Monitor[nIndex].pass = dbInfo.RedisParams.msg[nIndex].pass

            base.m_Monitor[nIndex].marks = sChennels
        end

        if (base.m_Monitor[nIndex].Mo == nil) then
            base.m_Monitor[nIndex].Mo = base.GetMsgRecv().new(kl, ti)

            local nRes = base.m_Monitor[nIndex].Mo:connect(kl, dbInfo.RedisParams.msg[nIndex].host,
                dbInfo.RedisParams.msg[nIndex].port, dbInfo.RedisParams.msg[nIndex].pass, base.m_Monitor[nIndex].marks,
                base.wrap(pFunc), base.GetUniqueKey())
            if nRes == 0 then
                base.m_Monitor[nIndex].Mo = nil
                err = err + 1
                base.Log("------Monitor re close, Host: %s, Port: %d", dbInfo.RedisParams.msg[nIndex].host,
                    dbInfo.RedisParams.msg[nIndex].port)
            else
                base.Log("------Monitor succeed, Host: %s, Port: %d", dbInfo.RedisParams.msg[nIndex].host,
                    dbInfo.RedisParams.msg[nIndex].port)
            end
        end
    end

    if err > 0 then
        return false
    end

    return true
end

-- 用户自用redis数据连接
function base.RedisConnect(host, port, pass, dbSelect)
    local redisConn = redis.connect({ host = host, port = port })
    if redisConn == nil then
        return nil, "connect fail"
    end
    if pass and #pass > 0 then
        if not redisConn:auth(pass) then --auth成功会返回:true
            redisConn:quit()
            return nil, "auth fail"
        end
    end
    if not redisConn:select(dbSelect) then --select成功会返回:true
        redisConn:quit()
        return nil, "select db fail"
    end
    return redisConn, "succee"
end

-- 用户自用redis数据连接
function base.MyRedisDataConnect()
    local dbSelect = 15
    local nErrCnt = 0
    for nDex, rDbInfo in ipairs(dbInfo.RedisParams.My) do
        if base.m_MyRedisData[nDex] == nil then
            local host, port, pass = rDbInfo.host, rDbInfo.port, rDbInfo.pass
            local redisConn, sErr = base.RedisConnect(host, port, pass, dbSelect)
            if redisConn then
                base.m_MyRedisData[nDex] = { redis = redisConn, host = host, port = port, pass = pass }
                base.Log("MyRedis[%d] succee,host:%s port:%d dbSelect:%d", nDex, host, port, dbSelect)
            else
                base.Log("MyRedis[%d] fail,%s", nDex, sErr)
                nErrCnt = nErrCnt + 1
            end
        end
    end
    return (nErrCnt == 0)
end

-- 发送消息到队列(通用)
function base.PostMsg(tagkey, Data, Len, ...)
    local arg = { ... }

    -- 随机选择一个消息队列发送
    local nRes = 0
    local nTestCount = 0
    repeat
        nRes = 0
        nTestCount = nTestCount + 1
        local aTmp = {}
        local nCount = 1
        for i = 1, #base.m_Queue do
            if (base.m_Queue[i] ~= nil and base.m_Queue[i].Mo ~= nil) then
                aTmp[nCount] = i
                nCount = nCount + 1
            end
        end

        if #aTmp > 0 then
            local lIndex = 1
            local q = nil

            if arg[1] ~= nil and arg[1] ~= 0 then
                lIndex = arg[1] % (#aTmp) + 1
            else
                lIndex = math.random(1, #aTmp)
            end
            q = base.m_Queue[aTmp[lIndex]].Mo
            -- 发布请求
            nRes = q:PostMsg(tagkey, Data, Len)
            if nRes == 0 then
                nRes = -1
                base.Log("Queue publish err:%d tagkey:" .. (tagkey or 'nil'), aTmp[lIndex])
            else
                break
            end
        else
            nRes = -1
            break
        end
    until nRes > 0 or nTestCount > 3

    if nRes <= 0 then
        base.Log("PostMsg Errpr AA")
        -- 通过失效的方式删除
        base.m_centerRedis.Mo:pexpire(tagkey, 1)
        base.Log("PostMsg Errpr BB")
        base.Sleep(10)
        base.Log("PostMsg Errpr CC")
        base.onTimerGetServerList(base.m_wTimer_ID_GetServerList)
        base.Log("PostMsg Errpr DD")
    end

    return nRes -- 返回为 0 : 频道不存在， -1 ： 队列服务器出错， 1 ：发送成功
end

-- 网关发给内网服
function base.PostToServer(tagkey, clientID, Data, Len)
    -- 加入附加信息
    local Msg = base.GetSP().new(0, 0)
    Msg:AddString(base.m_tKey)
    Msg:AddUint32(clientID)
    Msg:AddBuff(Data, Len)

    return base.PostMsg(tagkey .. "Gateway", Msg:GetData(), Msg:GetSize(), clientID)
end

-- 内网服间转发
function base.PostToClient(sClientID, Data, Len)
    local tVal = api.Split(sClientID, ":")
    local sTagkey = tVal[1]
    local nClientId = tonumber(tVal[2])

    return base.PostToServer(sTagkey, nClientId, Data, Len)
end

-- 内网服发给网关服
function base.PostToGateway(sClientID, Data, Len)
    local tVal = api.Split(sClientID, ":")
    local tagkey = tVal[1] .. "Gateway"
    local clientID = tVal[2]
    local srckey = base.m_tKey

    -- 加入附加信息
    local Msg = base.GetSP().new(0, 0)
    Msg:AddString(srckey)
    Msg:AddUint32(clientID)
    Msg:AddBuff(Data, Len)

    return base.PostMsg(tagkey, Msg:GetData(), Msg:GetSize(), tonumber(clientID))
end

local function _IsArray(value)
    if type(value) == 'table' then
        if #value > 0 or _G.next(value) == nil then
            return true
        end
    end
    return false
end
local function _IsBasicType(value)
    if _IsArray(value) then
        return false
    end
    if type(value) == 'table' then
        return false
    end
    return true
end
local function IsHaveBasicValue(tb)
    for _, v in pairs(tb) do
        if type(v) ~= 'table' then
            return true
        else
            if IsHaveBasicValue(v) then
                return true
            end
        end
    end
    return false
end

local function _ConstructProto(tProtoObj, tData)
    for k, v in pairs(tData) do
        if _IsBasicType(v) then --基本类型直接赋值
            tProtoObj[k] = v
        elseif _IsArray(v) then --数组类型
            for kk, vv in ipairs(v) do
                if _IsBasicType(vv) then
                    tProtoObj[k]:append(vv)
                else
                    local ele = tProtoObj[k]:add()
                    _ConstructProto(ele, vv)
                end
            end
        elseif IsHaveBasicValue(v) then --table类型
            _ConstructProto(tProtoObj[k], v)
        end
    end
end

base.ProtoInit = _ConstructProto
--base.ProtoInit 使用示例
--[[
   local  tProtoObj = ZhaJinHuaGame_pb.TestReq()
   local tData ={nUserId =10001,arrL={1,2,3},tB={a=1,b=2},arrY={{c=1,b=2},{c=1,b=2}}}
   tBase.ProtoInit(tProtoObj,tData)
   tProtoObj:SerializeToString()
]]


-- 获取TCP的协议信息
function base.GetTCP(Data, Len)
    local r = base.GetRP().new(Data, Len)
    -- 获取附加信息
    local SrcKey = r:GetString();
    local ClientID = r:GetUint32();
    base.Log("GetTCP===.SrcKey=" .. tostring(SrcKey) .. "ClientID=" .. tostring(ClientID))
    -- 获取协议信息
    local Buff, Size = r:GetBuff()

    return SrcKey, ClientID, Size, Buff
end

-- 消息接收器
function base.dispatch(Mark, Data, Len)
    if (Mark == base.m_tKey .. "Gateway") then -- 与网关的TCP通信息
        -- 获取TCP协议信息
        local SrcKey, ClientID, Size, Buff = base.GetTCP(Data, Len)
        local NewID = SrcKey .. ":" .. ClientID
        local r = base.GetRP().new(Buff, Size)
        local MainID = r:GetModuleID()
        local SubID = r:GetMsgID()
        base.Log("dispatch,MainID=" .. MainID .. ",SubID=" .. SubID)
        local f = base.GetFunC(MainID, SubID)
        if (f ~= nil) then
            f(NewID, Buff, Size)
        end
    elseif (Mark == base.m_tKey) then -- 旧频道
        if base.m_OldSinkFunc ~= nil then
            base.m_OldSinkFunc(Mark, Data, Len)
        end
    end
end

-- 检测断线函数
function base.CheckConnect(Data, Len)
    local r = base.GetRP().new(Data, Len)
    local host = r:GetString()
    local port = r:GetUint32()

    local kl = base.GetKernel()

    -- 设置中心服发布重连
    if base.m_centerRedis.Mo ~= nil and base.m_centerRedis.host == host and base.m_centerRedis.port == port then
        base.m_centerRedis.Mo = nil
        base.Log("------centerRedis close")
    end

    -- 设置myredsi重连
    for k, v in pairs(base.m_MyRedisData) do
        if base.m_MyRedisData[k] ~= nil and base.m_MyRedisData[k].redis ~= nil and base.m_MyRedisData[k].host == host and base.m_MyRedisData[k].port == port then
            base.m_MyRedisData[k].redis = nil
            base.Log("------MyRedisData close:%d", k)
        end
    end

    -- 设置队列发布的重连
    for k, v in pairs(base.m_Queue) do
        if base.m_Queue[k] ~= nil and base.m_Queue[k].Mo ~= nil and base.m_Queue[k].host == host and base.m_Queue[k].port == port then
            base.m_Queue[k].Mo:close()
            base.m_Queue[k].Mo = nil
            base.Log("------Queue close:%d", k)
        end
    end

    -- 设置队列订阅的重连
    for nIndex = 1, #base.m_Monitor do
        if base.m_Monitor[nIndex] ~= nil and base.m_Monitor[nIndex].Mo ~= nil and base.m_Monitor[nIndex].host == host and base.m_Monitor[nIndex].port == port then
            base.m_Monitor[nIndex].Mo:close(kl)
            base.m_Monitor[nIndex].Mo = nil
            base.Log("------Monitor close:%d", nIndex)
        end
    end

    base.SetTimer(base.m_wTimer_ID_Reconnection, 1000 * 5, 1, base.onTimerReconnection, true)
end

-- 连接状态处理
function base.ErrorDispatch(Type, Data, Len)
    if Type == 1 then --redis服务器连接情况
        base.CheckConnect(Data, Len)
    end

    if base.m_MyErrorFun ~= nil then
        base.m_MyErrorFun(Type, Data, Len)
    end
end

-- 定时器分发函数
function base.dispatch_timer(func, TimerID)
    if base.m_MyTimerFun ~= nil then
        base.m_MyTimerFun(func, TimerID)
    else
        func(TimerID)
    end
end

--获取服务器时间（已和DB服务器校准）
function base.GetCountDTime()
    local dNow = os.time()
    -- base.Log("currentime = %d", os.time() + base.m_cmpTime)
    return dNow + base.m_cmpTime
end

--获取0点时间戳（已和DB服务器校准）
function base.GetZeroTime()
    local cDateCurrectTime = os.date("*t")

    local cDateTodayTime = os.time({
        year = cDateCurrectTime.year,
        month = cDateCurrectTime.month,
        day = cDateCurrectTime
            .day,
        hour = 0,
        min = 0,
        sec = 0
    });
    return base.m_cmpTime + cDateTodayTime;
end

--获取今天是周几（0-6）（已和DB服务器校准）
--0 周日
function base.GetWeek()
    return os.date("%w", base.GetCountDTime())
end

local deepcopy = function(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
base.DeepCopy = deepcopy


-- 返回当前的时间(毫秒)
function base.GetTime()
    -- local kl = base.GetKernel()
    -- local ti = base.GetThreadIndex()

    -- local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)

    -- return km:GetTime()
    return math.floor(sk.gettime() * 1000)
    -- return math.floor(socket.gettime() * 1000)
end

-- 返回正态分布随机数
-- 对于任何的正态分布
-- 1.期望(u)的每一边的值都占50%，标准差(o)
-- 2.u-o和u+o之间有68%的值
-- 3.u-2o和u+2o之间有95%的值
function base.GetNormalRandom(dMu, dSigma, bChangSeed)
    -- dMu，期望
    -- dSigma，标准差
    -- bDouble，是否产生浮点随机数
    -- bChangSeed，是否换种子

    local kl = base.GetKernel()
    local ti = base.GetThreadIndex()

    local km = km_FD55292F51334A64AC61470D796F8D43.new(kl)

    if dMu == nil then
        dMu = 0.00
    end

    if dSigma == nil then
        dSigma = 1.00
    end

    local nC = 0
    if bChangSeed == nil then
        nC = 0
    elseif bChangSeed then
        nC = 1
    end

    return km:NormalRandom(dMu, dSigma, nC)
end

-- 返回正态分布随机数(整型)
function base.GetNormalRandomInt(dMu, dSigma, bChangSeed)
    return math.floor(base.GetNormalRandom(dMu, dSigma, bChangSeed) + 0.5)
end

local function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--监控信息
function base._OnMonitorInfo(SendSMS, nServer)
    local MonitorKey = base.m_MyRedisData[2].redis:hgetall("MonitorKey_")
    -- base.Log("MonitorKey_:"..cjson.encode(MonitorKey))
    nServer = nServer or tSrvInfo.nServerId
    local sHttp = tSCfg.sHttpMonitor .. "chat_id=%d&text=%s"
    local date = os.date("%Y-%m-%d %H:%M:%S")
    local str = "[" .. date .. "][" .. nServer .. "][" .. tSrvInfo.nIp .. "]Msg_" .. SendSMS
    sHttp = string.format(sHttp, tSCfg.nChatId, str)

    if MonitorKey ~= nil then
        if MonitorKey["m_Http"] ~= nil and MonitorKey["m_tokenAI"] ~= nil and MonitorKey["chat_id"] ~= nil and MonitorKey["IsEnabled"] == "true" then
            sHttp = MonitorKey["m_Http"] ..
                "?sToken=" .. MonitorKey["m_tokenAI"] .. "&CharID=" .. MonitorKey["chat_id"] .. "&Msg=%s"
            sHttp = string.format(sHttp, urlEncode(str))
        end
    end

    local arrWKey = base.GetSrcAllKey(tname.web) or {}
    if #arrWKey < 1 then return end
    tNMess.NoticeMess(arrWKey[1], sHttp)
end

function base.Ran_dom(...)
    --参数处理
    local arg = { ... }
    local min = nil
    local max = nil
    if arg[1] ~= nil and arg[2] == nil then
        min = 1
        max = arg[1]
    elseif arg[1] ~= nil and arg[2] ~= nil then
        min = arg[1]
        max = arg[2]
    end

    -- 随机数池
    if base.m_arrCacheRand == nil then
        base.m_arrCacheRand = {}
    end

    --从系统随机文件中读取
    local function urandom()
        if #base.m_arrCacheRand == 0 then
            local COUNT = 4096
            local frandom = assert(io.open("/dev/urandom", "rb"))
            local s = frandom:read(COUNT)
            assert(s:len() == COUNT)

            for i = 1, 4096, 4 do
                --读取4个字节作为一个整数
                local v = 0
                for c = 0, 3 do
                    v = 256 * v + s:byte(i + c)
                end
                table.insert(base.m_arrCacheRand, v)
            end
            io.close(frandom)
        end

        if #base.m_arrCacheRand > 0 then
            return table.remove(base.m_arrCacheRand)
        end

        assert(false)
    end

    local rand = urandom

    --随机给定范围[min,max]的整数
    local function randInt(min, max)
        assert(max >= min)

        local nRandMax = math.pow(2, 32)
        local nLen = max - min + 1

        local nRemainder = nRandMax % nLen

        assert(nRandMax > nRemainder)

        local nRandNum = 0
        repeat
            nRandNum = rand()
        until (nRandNum < (nRandMax - nRemainder))

        local v = nRandNum % nLen

        return v + min
    end

    if min ~= nil and max ~= nil then
        return randInt(min, max)
    end

    return rand() / 0xFFFFFFFF
end

-- 主从 关联 通知
function base._SlaveRelevanceSendTelegram()
    if not base.SendTelegram then
        base.SendTelegram = os.time()
    else
        if math.floor((os.time() - base.SendTelegram) / 60) >= 5 then -- 一分钟 提示
            base.SendTelegram = nil
            local sSend = string.format("该从服 nServerId: %d 没有关联中心服Id,要在该表(LiveCSRelation_ ) 增加配置", tSrvInfo.nServerId)
            base._OnMonitorInfo(sSend)
        end
    end
end

base.arrSGRelation = {} --服务器-分组关系
function base.GetSGRelation()
    return base.arrSGRelation
end

function base.SetSGRelation(arrSGRelation)
    base.arrSGRelation = arrSGRelation or {}
end

--获取服务器对应的分组
--@params nServerId:服务器id
--@return arrGroup={nGroupId,nGroupId,nGroupId,...}
function base.GetGroupByServerId(nServerId)
    local arrGroup = {}
    for k, v in pairs(base.arrSGRelation) do
        if v.nServerId == nServerId then
            table.insert(arrGroup, v.nGroupId)
        end
    end
    return arrGroup
end

--服务器和分组是否有对应关系
--@params nServerId:服务器id
--@params nGroupId:分组id
--@return true:有，false：没有
function base.HasServerGroupRelation(nServerId, nGroupId)
    for k, v in pairs(base.arrSGRelation) do
        if v.nServerId == nServerId and v.nGroupId == nGroupId then
            return true
        end
    end
    return false
end

-- 代替系统pcall函数
function base.myPcall(f, ...)
    local arg = { ... }
    local sErr = ''
    local tData = nil
    function tpLog(e)
        sErr = e .. "\n" .. debug.traceback()
        return e
    end

    if unpack ~= nil then -- 5.1及之前的版本
        tData = { xpcall(f, tpLog, unpack(arg)) }
    else                  -- 之后的版本
        tData = { xpcall(f, tpLog, table.unpack(arg)) }
    end

    if tData and tData[1] then
        return table.unpack(tData)
    else
        -- base.Log("is  false")
        return false, sErr
    end
end

-- 通知Web 服公共接口
function base.PublicPushWebHttp(sHttp)
    local arrWKey = base.GetSrcAllKey(tname.web) or {}
    if #arrWKey < 1 then return end
    tNMess.NoticeMess(arrWKey[1], sHttp)
end

return base
