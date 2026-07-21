
local tJson = require("cjson")
require("publicApi") -- 共用功能接口

ControlDefine = {}

ControlDefine.TimerID_Check = 10001
ControlDefine.TimerID_SetShopID = 10003
ControlDefine.TimerID_ClearShopData = 10004
ControlDefine.TimerID_CheckUser = 10002
ControlDefine.TimerID_SetUserIDScope = 10006
ControlDefine.TimerID_LoadGameConfig = 10005
ControlDefine.TimerID_AppBlackList = 10007

-- 获取redis数据的key
ControlDefine.APP_Blacklist = "7AD6C52E814A442E9CEF3FC856587D49_"   -- 黑名单
ControlDefine.Other_WinLose = "8775299EEA074CB590ABC586BFAF4566_"   -- 玩家在其它厂商的输赢

-- 设置
ControlDefine.m_Setting = {}

local sDefineKey = "50F3DF333BB14C9AA7B51EAA8D0A18C7_Control"

function ControlDefine.GetVal(sName, nDefaultVal)

    local sVal = base.m_MyRedisData[2].redis:hget(sDefineKey, sName)
    if sVal ~= nil then
        logger:info('ControlDefine.GetVal， sName:'..sName..', Val:'..sVal)
        return tonumber(sVal)
    end

    return nDefaultVal
end

function ControlDefine.GetValByShopID(sName, nShopID, nDefaultVal)

    local sRedisName = 'Group_'..nShopID..'_'..sName

    local sVal = base.m_MyRedisData[2].redis:hget(sDefineKey, sRedisName)
    if sVal ~= nil then
        logger:info('ControlDefine.GetValByShopID, sName:'..sRedisName..', Val:'..sVal)
        return tonumber(sVal)
    end

    return nDefaultVal
end

function ControlDefine.GetValByGameID(sName, nShopID, nGameID, nDefaultVal)

    local sRedisName = 'Group_'..nShopID..'_'..nGameID..'_'..sName

    local sVal = base.m_MyRedisData[2].redis:hget(sDefineKey, sRedisName)
    if sVal ~= nil then
        logger:info('ControlDefine.GetValByGameID, sName:'..sRedisName..', Val:'..sVal)
        return tonumber(sVal)
    end

    return nDefaultVal
end

function ControlDefine.GetValByRoomID(sName, nShopID, nGameID, nRoomID, nDefaultVal)

    local sRedisName = 'Group_'..nShopID..'_'..nGameID..'_'..nRoomID..'_'..sName

    local sVal = base.m_MyRedisData[2].redis:hget(sDefineKey, sRedisName)
    if sVal ~= nil then
        logger:info('ControlDefine.GetValByRoomID, sName:'..sRedisName..', Val:'..sVal)
        return tonumber(sVal)
    end

    return nDefaultVal
end

function ControlDefine.GetText(sName, sDefaultVal)

    local sVal = base.m_MyRedisData[2].redis:hget(sDefineKey, sName)
    if sVal ~= nil then
        logger:info('ControlDefine.GetText sName:'..sName)
        return sVal
    end

    return sDefaultVal
end

function ControlDefine.NewParam()
    local tParam = {}

    -- 全局变量
    local GroupData = {}
    GroupData.UserTriggerVal1 = 20000.00  -- 个人全局控输触发范围开始值
    GroupData.UserTriggerVal2 = 25000.00  -- 个人全局控输触发范围结束值

    GroupData.UserStopTriggerVal1 = 0.00  -- 个人全局控输停止范围开始值
    GroupData.UserStopTriggerVal2 = 2000.00     -- 个人全局控输停止范围结束值

    GroupData.UserTriggerWinVal1 = -22000.00    -- 个人全局控赢触发范围开始值
    GroupData.UserTriggerWinVal2 = -20000.00    -- 个人全局控赢触发范围结束值

    GroupData.UserStopTriggerWinVal1 = 0.00       -- 个人全局控赢停止范围开始值
    GroupData.UserStopTriggerWinVal2 = 2000.00    -- 个人全局控赢停止范围结束值

    GroupData.UserAddPerInit = 50.00    -- 个人全局控输概率初始值%
    GroupData.UserAddPerStep = 2.00     -- 个人全局控输概率增加步长%
    GroupData.UserMaxPer = 70.00        -- 个人全局控输概率最大值%

    GroupData.UserAddPerInitWin = 20.00   -- 个人全局控赢概率初始值%
    GroupData.UserAddPerStepWin = 2.00    -- 个人全局控赢概率增加步长%
    GroupData.UserMaxPerWin = 40.00       -- 个人全局控赢概率最大值%

    GroupData.UserLuckPer1 = 50.00 -- 玩家运气非常差概率
    GroupData.UserLuckPer2 = 20.00 -- 玩家运气有点差概率
    GroupData.UserLuckPer3 = 50.00 -- 玩家运气非常好概率
    GroupData.UserLuckPer4 = 20.00 -- 玩家运气有点好概率   
    
    GroupData.FirstControlPerStart = 0    -- 新注册用户加入风控概率
    GroupData.FirstControlPerEnd = 0     -- 新注册用户加入风控概率
    GroupData.UnlockGamesStart = 10       -- 风控有条件解锁起始局数
    GroupData.UnlockGamesEnd = 30         -- 风控有条件解锁结束局数
    GroupData.UnlockValStart = 10000     -- 风控有条件解锁起始金额
    GroupData.UnlockValEnd = 20000       -- 风控有条件解锁结束金额
    GroupData.FirstControlPer = 20   -- 新注册用户控牌赢的概率

    GroupData.PpccPer = 0.5 -- 符合相关性强的特点
    GroupData.CheckUserMinCount = 5.00   -- 个人全局控检测间隔局数
    GroupData.UserSecondGoordCardPer = 60.00 -- 个人全局控输时玩家拿好牌概率
    GroupData.MaxUserCheckJS = 100.00 -- 风控最大保留局数
    
    -- 游戏房间数据
    local RoomData = {}
    RoomData.TriggerControlVal1 = 10000.00       -- 个人房间控输触发范围开始值
    RoomData.TriggerControlVal2 = 15000.00       -- 个人房间控输触发范围结束值

    RoomData.EndControlVal1 = 0.00               -- 个人房间控输停止范围开始值
    RoomData.EndControlVal2 = 2000.00            -- 个人房间控输停止范围结束值

    RoomData.TriggerControlWinVal1 = -12000.00 -- 个人房间控赢触发范围开始值
    RoomData.TriggerControlWinVal2 = -10000.00 -- 个人房间控赢触发范围结束值

    RoomData.EndControlWinVal1 = 0.00            -- 个人房间控赢停止范围开始值
    RoomData.EndControlWinVal2 = 2000.00         -- 个人房间控赢停止范围结束值

    RoomData.UserAddPerInit = 50.00    -- 个人房间控输概率初始值%
    RoomData.UserAddPerStep = 2.00     -- 个人房间控输概率增加步长%
    RoomData.UserMaxPer = 70.00        -- 个人房间控输概率最大值%

    RoomData.UserAddPerInitWin = 20.00   -- 个人房间控赢概率初始值%
    RoomData.UserAddPerStepWin = 2.00    -- 个人房间控赢概率增加步长%
    RoomData.UserMaxPerWin = 40.00       -- 个人房间控赢概率最大值%

    RoomData.CheckRoomMinCount = 5.00 -- 个人房间控检测间隔局数
    RoomData.NormalGoordCardPer = 0.00 -- 非风控下增加游戏难度的概率 

    RoomData.FirstControlPer = 20   -- 新注册用户控牌赢的概率
    RoomData.BRControlPer = 20      -- 百人游戏风控额外概率

    RoomData.PoolWinWaterPer = 0    -- 风控抽水百分比

    RoomData.IsControl = 1          -- 本游戏是否开启风控

    ----------------------------------------

    tParam.GroupData = GroupData
    tParam.GameDefault = RoomData       -- 个人房间默认配置

    -- tParam.GameData = {}
    -- tParam.GameData["107"] = {}
    -- tParam.GameData["107"]["-1"] = RoomData -- 房间默认配置
    -- tParam.GameData["107"]["1"] = RoomData  -- 新手场默认配置
    -- tParam.GameData["107"]["2"] = RoomData  -- 初级场默认配置
    -- tParam.GameData["107"]["3"] = RoomData  -- 中级场默认配置
    -- tParam.GameData["107"]["4"] = RoomData  -- 高级场默认配置

    return tParam
end

function ControlDefine.GetControlParam(GroupID)

    GroupID = math.floor(GroupID)

    local tParam = {}
    local json_data = ControlDefine.GetText("ControlParam_"..GroupID, nil)
    if json_data ~= nil then
        tParam = tJson.decode(json_data)
    else
        tParam = ControlDefine.NewParam()
    end
    return tParam
end

function ControlDefine.GetGroupParam(GroupID)

    GroupID = tostring(math.floor(GroupID))

    local tParam = publicApi.DoCache(60 * 2, ControlDefine.GetControlParam, GroupID)

    return tParam.GroupData
end

function ControlDefine.GetRoomParam(GroupID, GameID, RoomID)

    GroupID = tostring(math.floor(GroupID))
    GameID = tostring(math.floor(GameID))
    RoomID = tostring(math.floor(RoomID))

    local tParam = publicApi.DoCache(60 * 2, ControlDefine.GetControlParam, GroupID)

    if tParam.GameData ~= nil and tParam.GameData[GameID] ~= nil then
        if tParam.GameData[GameID][RoomID] ~= nil then
            return tParam.GameData[GameID][RoomID], false
        elseif tParam.GameData[GameID]["-1"] ~= nil then
            return tParam.GameData[GameID]["-1"], false
        end
    end

    return tParam.GameDefault, true
end



-- 不可调整参数
ControlDefine.m_Setting.nRoomTimeOut = 1000 * 60 * 60 * 48 -- 控制最近玩过的玩家超时时间
ControlDefine.m_Setting.nSetShopIDTimeOut = 1000 * 1 -- 用户设置ShopID定时器
ControlDefine.m_Setting.nClearShopDataTimeOut = 1000 * 60 * 30 -- 清除无效shopID定时器
ControlDefine.m_Setting.nCheckRoomTimeOut = 1000 * 60 * 1 -- 房间检测定时器
ControlDefine.m_Setting.nCheckUserTimeOut = 1000 * 60 * 1 -- 个人检测定时器

return ControlDefine