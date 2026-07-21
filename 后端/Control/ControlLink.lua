
local tGameConfig = require("GameConfig") --  游戏匹配
local ProtoMgr   = require("ProtoManager") -- 协议管理对象 
local tPubUser = require("PublicUserInfo") -- 用户信息
local Define = require("ControlDefine") -- 定义
local tPublicRedis =require("PublicRedis") -- Redis 公共接口

ControlLink = {}

ControlLink.m_lstControl = {}
ControlLink.m_CheckTime = {}

function _gettime()
    return math.floor(socket.gettime() * 1000)
end

function _CreateUser()
    local tUser = {}

    -- 公共信息
    tUser.lstWin = {}               -- 输赢列表
    tUser.sRTime = _gettime()   -- 最近一次读取时间
    tUser.nCountControlJS = 0       -- 已进行控制的局数
    tUser.dUserStatWin = nil        -- 用户全局输赢统计
    tUser.nLock = 0                 -- 用户是否被锁定
    tUser.nLuck = 0                 -- 用户的运气值
    tUser.bWin = false              -- 是否控牌赢
    tUser.dUnlockGames = 0          -- 解锁局数
    tUser.dUnlockVal = 0            -- 解锁配置的金额
    tUser.dCurUnlockVal = 0         -- 当前解锁金额

    tUser.UserTriggerVal = 0        -- 控输触发值
    tUser.UserStopTriggerVal = 0    -- 控输停止值
    tUser.UserTriggerWinVal = 0        -- 控赢触发值
    tUser.UserStopTriggerWinVal = 0    -- 控赢停止值    

    -- 控牌信息
    tUser.dControlPer = 0

    -- 房间统计信息
    tUser.tRoomStat = {}

    return tUser
end

function _CreateRoom()
    local tRoom = {}
    tRoom.lstWin = {}               -- 输赢列表
    tRoom.nCountControlJS = 0       -- 已进行控制的局数
    tRoom.dStatWin = 0.00           -- 该房间输赢统计
    tRoom.bIsControl = false        -- 是否被控制中
    tRoom.nLock = 0                 -- 用户是否被锁定
    tRoom.nLuck = 0                 -- 用户的运气值
    tRoom.bWin = false              -- 是否控牌赢

    tRoom.TriggerVal = 0            -- 控输触发值
    tRoom.StopTriggerVal = 0        -- 控输停止值
    tRoom.TriggerWinVal = 0         -- 控赢触发值
    tRoom.StopTriggerWinVal = 0     -- 控赢停止值  

    -- 控牌信息
    tRoom.dControlPer = 0

    return tRoom
end

-- 是否设置有条件锁定
function _IsSetLock(ShopID)

    local tParam = Define.GetGroupParam(ShopID)

    local FirstControlPerStart = tParam.FirstControlPerStart
    local FirstControlPerEnd = tParam.FirstControlPerEnd

    -- logger:info("FirstControlPerStart:"..FirstControlPerStart..", FirstControlPerEnd:"..FirstControlPerEnd)

    if FirstControlPerStart < 0 or FirstControlPerEnd < 0 or (FirstControlPerStart > FirstControlPerEnd) then
        return 0, 0, 0, 0
    end

    local nRand = 0

    if FirstControlPerStart == FirstControlPerEnd then
        nRand = FirstControlPerStart
    else
        nRand = math.random(FirstControlPerStart, FirstControlPerEnd)
    end

    if math.random(1, 100) < nRand then

        local UnlockGamesStart = tParam.UnlockGamesStart
        local UnlockGamesEnd = tParam.UnlockGamesEnd
        local UnlockValStart = tParam.UnlockValStart
        local UnlockValEnd = tParam.UnlockValEnd

        local UnlockGames = math.random(UnlockGamesStart, UnlockGamesEnd)
        local UnlockVal = publicApi.RandDouble(UnlockValStart, UnlockValEnd)

        return 1, 4, UnlockGames, UnlockVal
    end

    return 0, 0, 0, 0
end

function _GetTriggerVal(nShopID, nGameID, nRoomID, bWin)

    local tGroupParam = Define.GetGroupParam(nShopID)
    local tRoomParam, _ = Define.GetRoomParam(nShopID, nGameID, nRoomID)
    
    local nTriggerVal = 0
    local nStopTriggerVal = 0
    local nUserTriggerVal = 0
    local nUserStopTriggerVal = 0

    if bWin == false then
        nUserTriggerVal = publicApi.RandDouble(tGroupParam.UserTriggerVal1, tGroupParam.UserTriggerVal2)        
        nUserStopTriggerVal = publicApi.RandDouble(tGroupParam.UserStopTriggerVal1, tGroupParam.UserStopTriggerVal2)

        nTriggerVal = publicApi.RandDouble(tRoomParam.TriggerControlVal1, tRoomParam.TriggerControlVal2)
        nStopTriggerVal = publicApi.RandDouble(tRoomParam.EndControlVal1, tRoomParam.EndControlVal2)
    else
        nUserTriggerVal = publicApi.RandDouble(tGroupParam.UserTriggerWinVal1, tGroupParam.UserTriggerWinVal2)
        nUserStopTriggerVal = publicApi.RandDouble(tGroupParam.UserStopTriggerWinVal1, tGroupParam.UserStopTriggerWinVal2)

        nTriggerVal = publicApi.RandDouble(tRoomParam.TriggerControlWinVal1, tRoomParam.TriggerControlWinVal2)
        nStopTriggerVal = publicApi.RandDouble(tRoomParam.EndControlWinVal1, tRoomParam.EndControlWinVal2)        
    end

    return nTriggerVal, nStopTriggerVal, nUserTriggerVal, nUserStopTriggerVal
end

function _GetRoomTriggerEndVal(nShopId, nGameId, nRoomId, bWin)

    local nStopTriggerVal = 0
    local tRoomParam, _ = Define.GetRoomParam(nShopID, nGameID, nRoomID)

    if bWin == false then
        nStopTriggerVal = publicApi.RandDouble(tRoomParam.EndControlVal1, tRoomParam.EndControlVal2)
    else
        nStopTriggerVal = publicApi.RandDouble(tRoomParam.EndControlWinVal1, tRoomParam.EndControlWinVal2)
    end

    return nStopTriggerVal
end

function _GetControlPer(nShopId, nGameId, nRoomId, bWin)

    local nUserAddPerStep, nUserMaxPer, nUserAddPerInit = 0, 0, 0

    if nGameId == -1 or nRoomId == -1 then
        local tGroupParam = Define.GetGroupParam(nShopId)
        if bWin == false then
            nUserAddPerInit = tGroupParam.UserAddPerInit
            nUserMaxPer = tGroupParam.UserMaxPer
            nUserAddPerStep = tGroupParam.UserAddPerStep
        else
            nUserAddPerInit = tGroupParam.UserAddPerInitWin
            nUserMaxPer = tGroupParam.UserMaxPerWin
            nUserAddPerStep = tGroupParam.UserAddPerStepWin
        end
    else
        local tRoomParam, _ = Define.GetRoomParam(nShopId, nGameId, nRoomId)
        if bWin == false then
            nUserAddPerInit = tRoomParam.UserAddPerInit
            nUserMaxPer = tRoomParam.UserMaxPer
            nUserAddPerStep = tRoomParam.UserAddPerStep
        else
            nUserAddPerInit = tRoomParam.UserAddPerInitWin
            nUserMaxPer = tRoomParam.UserMaxPerWin
            nUserAddPerStep = tRoomParam.UserAddPerStepWin
        end
    end

    return nUserAddPerStep, nUserMaxPer, nUserAddPerInit
end

function ControlLink.IsControl(tItem)

    local nShopID = tItem.nShopId
    local nGameID = tItem.nGameId
    local nRoomID = tItem.nLevelId
    local nUserID = tItem.nUserId
    local dWin = tItem.dWinLose + tItem.dDrawWater

    local tGroupParam = Define.GetGroupParam(nShopID)

    -- 获取控牌输的触发值
    local nTriggerVal, nStopTriggerVal, nUserTriggerVal, nUserStopTriggerVal = _GetTriggerVal(nShopID, nGameID, nRoomID, false)
    
    -- 获取控牌赢的触发值
    local nTriggerVal_Win, nStopTriggerVal_Win, nUserTriggerVal_Win, nUserStopTriggerVal_Win = _GetTriggerVal(nShopID, nGameID, nRoomID, true)
    ---------

    -- 获取玩家其它厂商的输赢
    local otherWinLose = ControlPublic.GetOtherWinLose(nShopID, nUserID)

    -- 生成本地的风控值
    nUserTriggerVal = nUserTriggerVal - otherWinLose
    nUserStopTriggerVal = nUserStopTriggerVal - otherWinLose
    if otherWinLose > 0 then
        nUserTriggerVal_Win = nUserTriggerVal_Win - otherWinLose
        nUserStopTriggerVal_Win = nUserStopTriggerVal_Win - otherWinLose
    end

    --
    if ControlLink.m_lstControl[nUserID] == nil and tItem.nLock == 0 and tItem.nRoomLock == 0 and  
            tItem.dUserStat > nUserTriggerVal_Win and tItem.dUserStat < nUserTriggerVal and 
            tItem.dRoomUserStat > nTriggerVal_Win and tItem.dRoomUserStat < nTriggerVal  then

        if tItem.isFirst == true then -- 如果是新注册用户，且没有被控制的
            local LockRes, FirstControlLuck, UnlockGames, UnlockVal = _IsSetLock(nShopID)
            if LockRes == 1 then -- 新用户，只设置全局锁定
                tItem.nLock = 2
                tItem.nLuck = FirstControlLuck
                tItem.dUnlockGames = UnlockGames
                tItem.dUnlockVal = UnlockVal
                logger:info("[U] FirstLuck:"..tItem.nLuck..", UnlockGames:"..tItem.dUnlockGames..", UnlockVal:"..tItem.dUnlockVal)
            else
                return
            end
        else
            return
        end
    end

    -- 插入用户数据
    if ControlLink.m_lstControl[nUserID] == nil then
        ControlLink.m_lstControl[nUserID] = _CreateUser()
        logger:info("[U] CreateUser:"..nUserID)
    end

    -- 获取用户数据
    local tUser = ControlLink.m_lstControl[nUserID]
    tUser.UserTriggerVal = nUserTriggerVal                  -- 控输触发值
    tUser.UserStopTriggerVal = nUserStopTriggerVal          -- 控输停止值
    tUser.UserTriggerWinVal = nUserTriggerVal_Win           -- 控赢触发值
    tUser.UserStopTriggerWinVal = nUserStopTriggerVal_Win   -- 控赢停止值

    logger:info('[U] IsControl UserID:'..tItem.nUserId..', dUserStat:'..tItem.dUserStat..',dRoomUserStat:'..tItem.dRoomUserStat..', lock:'..tItem.nLock..', RoomLock:'..tItem.nRoomLock..', UnlockGames:'..tUser.dUnlockGames..', UnlockVal:'..tUser.dUnlockVal..', OtherWinLose:'..otherWinLose)

    -- 插入输赢缓存数据，用于趋势判断
    table.insert(tUser.lstWin, dWin)
    if #tUser.lstWin > tGroupParam.MaxUserCheckJS then 
        table.remove(tUser.lstWin, 1) -- 只保留一定数量
    end

    -- 最近获取数据时间
    tUser.sRTime = _gettime()

    -- 全局监控判断
    if tItem.dUserStat < tUser.UserTriggerWinVal or tItem.dUserStat > tUser.UserTriggerVal or tItem.nLock >= 1 then
        if tUser.dUserStatWin == nil then  -- 首次进行全局监控

            tUser.dUserStatWin = tItem.dUserStat

            -- 锁定优先
            if tItem.nLock >= 1 then
                if tItem.nLuck == 1 or tItem.nLuck == 2 then
                    tUser.bWin = false
                end
                if tItem.nLuck == 3 or tItem.nLuck == 4 then
                    tUser.bWin = true
                end                
            else
                if tItem.dUserStat > nUserTriggerVal then   -- 先判断控输
                    tUser.bWin = false
                elseif tItem.dUserStat < nUserTriggerVal_Win then
                    tUser.bWin = true
                end                
            end

            _, _, tUser.dControlPer = _GetControlPer(nShopID, -1, -1, tUser.bWin)

            local nType = 21
            if tUser.bWin == true then
                nType = 31
            end
            ControlLink.WriteControlRecord({nSId = -1, nGId = -1, nLId = -1, 
            nUId = nUserID, 
            nType = nType, 
            dTime = os.date("%Y-%m-%d %H:%M:%S"),
            nIsDel = 0,
            nIsLock = tItem.nLock >= 1 and tItem.nLock or 0,
            nIsLuck = tItem.nLuck >= 1 and tItem.nLuck or (tUser.bWin == false and 2 or 4)})

            if tItem.nLock == 2 then
                tUser.dUnlockGames = tItem.dUnlockGames -- 解锁局数
                tUser.dUnlockVal = tItem.dUnlockVal     -- 解锁金额 
            end
        end
    end
    if tUser.dUserStatWin ~= nil then   -- 设置数据
        tUser.dUserStatWin = tItem.dUserStat
        tUser.nLock = tItem.nLock       -- 设置是否锁定
        tUser.nLuck = tItem.nLuck

        if tUser.nLock == 2 then

            if tUser.dUnlockGames > 0 then
                tUser.dUnlockGames = tUser.dUnlockGames - 1
                logger:info('[U] Reduce UserID:'..tItem.nUserId..', UnlockGames:'..tUser.dUnlockGames..', UnlockVal:'..tUser.dUnlockVal)
            end
    
            if tUser.bWin == true and otherWinLose > 0 then 
                tUser.dCurUnlockVal = tUser.dUnlockVal - otherWinLose
            else
                tUser.dCurUnlockVal = tUser.dUnlockVal
            end
        end
    end
    


    -- 房间监控判断
    local sRoomKey = nShopID.."_"..nGameID.."_"..nRoomID
    if tItem.dRoomUserStat < nTriggerVal_Win or tItem.dRoomUserStat > nTriggerVal or tItem.nRoomLock == 1 then
        if tUser.tRoomStat[sRoomKey] == nil then
            tUser.tRoomStat[sRoomKey] = _CreateRoom()

            local tRoom = tUser.tRoomStat[sRoomKey]

            -- 锁定优先
            if tItem.nRoomLock >= 1 then
                if tItem.nRoomLuck == 1 or tItem.nRoomLuck == 2 then
                    tRoom.bWin = false
                end
                if tItem.nRoomLuck == 3 or tItem.nRoomLuck == 4 then
                    tRoom.bWin = true
                end                
            else
                if tItem.dRoomUserStat > nTriggerVal then
                    tRoom.bWin = false
                elseif tItem.dRoomUserStat < nTriggerVal_Win then
                    tRoom.bWin = true
                end                
            end

            _, _, tRoom.dControlPer = _GetControlPer(nShopID, nGameID, nRoomID, tRoom.bWin)

            -- 记录控牌信息
            local nType = 51
            if tRoom.bWin == true then
                nType = 61
            end            
            ControlLink.WriteControlRecord({nSId = nShopID, nGId = nGameID, nLId = nRoomID, 
            nUId = nUserID, 
            nType = nType, 
            dTime = os.date("%Y-%m-%d %H:%M:%S"),
            nIsDel = 0,
            nIsLock = tItem.nRoomLock >= 1 and tItem.nRoomLock or 0,
            nIsLuck = tItem.nRoomLuck >= 1 and tItem.nRoomLuck or (tRoom.bWin == false and 2 or 4)})
        end
    end
    local tRoom = tUser.tRoomStat[sRoomKey]
    if tRoom ~= nil then            -- 设置数据
        tRoom.dStatWin = tItem.dRoomUserStat
        tRoom.nLock = tItem.nRoomLock   -- 设置是否锁定
        tRoom.nLuck = tItem.nRoomLuck   

        tRoom.TriggerVal = nTriggerVal
        tRoom.StopTriggerVal = nStopTriggerVal
        tRoom.TriggerWinVal = nTriggerVal_Win
        tRoom.StopTriggerWinVal = nStopTriggerVal_Win

        -- 插入输赢缓存数据，用于趋势判断
        table.insert(tRoom.lstWin, dWin)
        if #tRoom.lstWin > tGroupParam.MaxUserCheckJS then
            table.remove(tRoom.lstWin, 1) -- 只保留一定数量
        end        
    end

    -- 累计控牌的局数
    if tItem.isControl == true then 
        tUser.nCountControlJS = tUser.nCountControlJS + 1
        logger:info('[U] isControl, UserID '..nUserID..', nCountControlJS:'..tUser.nCountControlJS)

        if tRoom ~= nil then
            tRoom.nCountControlJS = tRoom.nCountControlJS + 1
            logger:info('[R] isControl, UserID '..nUserID..', nShopID:'..nShopID..', nGameId:'..nGameID..', nLevelId:'..nRoomID..', nCountControlJS:'..tRoom.nCountControlJS)
        end
    end

    logger:info('[U] CheckShop, nShopID:'..nShopID..', nGameId:'..nGameID..', nLevelId:'..nRoomID..
                    ', nUserID:'..nUserID..', dWin:'..dWin..', sRTime:'..tUser.sRTime..', dUserStat:'..tItem.dUserStat..
                    ', dRoomUserStatWin:'..tItem.dRoomUserStat..', lock:'..tItem.nLock..', room lock:'..tItem.nRoomLock)

end

-- 对用户进行干预
function ControlLink.ControlUser(nUserId, nShopId)

    -- 是否够检查时间间隔
    local sCheckKey = nShopId.."_"..nUserId
    if ControlLink.m_CheckTime[sCheckKey] == nil then
        ControlLink.m_CheckTime[sCheckKey] = _gettime()
    end
    local nCurTime = _gettime()

    -- 防止时间重置
    if nCurTime < ControlLink.m_CheckTime[sCheckKey] then
        ControlLink.m_CheckTime[sCheckKey] = nCurTime
    end

    if nCurTime - ControlLink.m_CheckTime[sCheckKey] < Define.m_Setting.nCheckRoomTimeOut then
        logger:info("[U] Time info:"..(nCurTime - ControlLink.m_CheckTime[sCheckKey]))
        if nCurTime - ControlLink.m_CheckTime[sCheckKey] < 0 then
            logger:error("[U] Time info:"..(nCurTime - ControlLink.m_CheckTime[sCheckKey]))
        end        
        return
    end
    ControlLink.m_CheckTime[sCheckKey] = nCurTime

    -------------------------------------------------------------------------------
    -- 进行取消监控操作

    local bControl = false
    local tUser = ControlLink.m_lstControl[nUserId]
    if tUser == nil then
        return
    end

    -- 是否取消个人全局监控操作
    if tUser.dUserStatWin ~= nil then

        if tUser.nLock >= 1 then
            -- 如果锁定的控牌输或赢，跟原来的控牌输或赢方向相同，则继续控牌
            if not ((tUser.bWin == false and (tUser.nLuck == 3 or tUser.nLuck == 4)) or 
                (tUser.bWin == true and (tUser.nLuck == 1 or tUser.nLuck == 2))) then

                if tUser.nLock == 1 then
                    bControl = true
                elseif tUser.nLock == 2 then
                    -- 看是否达到解锁条件
                    if tUser.dUnlockGames > 0 and 
                    ((tUser.bWin == true and tUser.dUserStatWin < tUser.dCurUnlockVal) or 
                    (tUser.bWin == false and tUser.dUserStatWin > tUser.dCurUnlockVal))
                     then
                        bControl = true
                    end
                end
            end
        else
            -- 控牌中，且没达到结束要求
            if ((tUser.bWin == false and tUser.dUserStatWin > tUser.UserStopTriggerVal) or 
                (tUser.bWin == true and tUser.dUserStatWin < tUser.UserStopTriggerWinVal)) then
                bControl = true
            end
        end

        if bControl == false then
            -- 符合取消监控要求，进行取消操作
            tUser.dUserStatWin = nil
            logger:info("[U] UserID:"..nUserId.." Cancel Monitor")

            -- 记录控牌信息
            local nType = 22
            if tUser.bWin == true then
                nType = 32
            end
            ControlLink.WriteControlRecord({nSId = -1, nGId = -1, nLId = -1, 
            nUId = nUserId, 
            nType = nType, 
            dTime = os.date("%Y-%m-%d %H:%M:%S"),
            nIsDel = 1,
            nIsLock = tUser.nLock >= 1 and tUser.nLock or 0,
            nIsLuck = tUser.nLuck >= 1 and tUser.nLuck or 0})
        end
    end

    -- 是否取消个人房间监控操作

    local tDelRoom = {}
    for sRoomKey, tRoom in pairs(tUser.tRoomStat) do 

        local bRoomControl = false

        local tV = publicApi.string_split(sRoomKey, '_')
        local nGameId = tV[2]
        local nRoomId = tV[3]

        if tRoom.nLock == 1 then
            -- 如果锁定的控牌输或赢，跟原来的控牌输或赢方向相同，则继续控牌
            if not ((tRoom.bWin == false and (tRoom.nLuck == 3 or tRoom.nLuck == 4)) or 
                (tRoom.bWin == true and (tRoom.nLuck == 1 or tRoom.nLuck == 2))) then
                bRoomControl = true
            end
        else
            -- 控牌中，且没达到结束要求
            if ((tRoom.bWin == false and tRoom.dStatWin > tRoom.StopTriggerVal) or 
                (tRoom.bWin == true and tRoom.dStatWin < tRoom.StopTriggerWinVal)) then
                bRoomControl = true
            end            
        end

        if bRoomControl == true then
            bControl = true
        else
            table.insert(tDelRoom, sRoomKey) -- 记录符合取消要求的房间
            logger:info("[R] UserID:"..nUserId..", RoomKey:"..sRoomKey.." Cancel Monitor")
        end
    end
    for i, sRoomKey in ipairs(tDelRoom) do -- 删除相应房间的监控

        local nType = 52
        if tUser.tRoomStat[sRoomKey].bWin == true then
            nType = 62
        end  
        local tV = publicApi.string_split(sRoomKey, '_')
        local nGameId = tV[2]
        local nRoomId = tV[3]

        local tRoom = tUser.tRoomStat[sRoomKey]

        -- 记录控牌信息
        ControlLink.WriteControlRecord({nSId = nShopId, nGId = nGameId, nLId = nRoomId, 
        nUId = nUserId, 
        nType = nType, 
        dTime = os.date("%Y-%m-%d %H:%M:%S"),
        nIsDel = 1,
        nIsLock = tRoom.nLock >= 1 and tRoom.nLock or 0,
        nIsLuck = tRoom.nLuck >= 1 and tRoom.nLuck or 0})

        tUser.tRoomStat[sRoomKey] = nil
    end

    -- 本用户的所有监控都可以删除
    if bControl == false then
        ControlLink.m_lstControl[nUserId] = nil
        logger:info("[U] UserID:"..nUserId..", Cancel All Monitor")
        return
    end

    -------------------------------------------------------------------------------
    local tGroupParam = Define.GetGroupParam(nShopId)

    -- 进行增加概率操作
    local nCheckUserMinCount = tGroupParam.CheckUserMinCount

    -- 再看是否增加调控
    logger:info('[U] nUserID:'..nUserId..', lstWinlose Count:'..tUser.nCountControlJS..'; tag Count:'..nCheckUserMinCount)

    if tUser.nCountControlJS >= nCheckUserMinCount and #tUser.lstWin > 0 then
        tUser.nCountControlJS = 0
        logger:info('[U] nCountControlJS reset:'..nUserId)
        tUser.dControlPer = ControlLink.AddControlPer(nShopId, -1, -1, tUser.bWin, tUser.lstWin, tUser.dControlPer)
    end

    for sRoomKey, tRoom in pairs(tUser.tRoomStat) do 
        logger:info('[R] nUserID:'..nUserId..', sRoomKey:'..sRoomKey..', lstWinlose Count:'..tRoom.nCountControlJS..'; tag Count:'..nCheckUserMinCount)

        if tRoom.nCountControlJS >= nCheckUserMinCount and #tRoom.lstWin > 0 then
            tRoom.nCountControlJS = 0
            logger:info('[R] nCountControlJS reset:'..nUserId)

            local tV = publicApi.string_split(sRoomKey, '_')
            local nGameId = tonumber(tV[2])
            local nRoomId = tonumber(tV[3])

            tRoom.dControlPer = ControlLink.AddControlPer(nShopId, nGameId, nRoomId, tRoom.bWin, tRoom.lstWin, tRoom.dControlPer)
        end
    end

end

-- 是否增加概率
function ControlLink.AddControlPer(nShopID, nGameID, nRoomID, bWin, lstWin, dControlPer)

    local tGroupParam = Define.GetGroupParam(nShopID)

    local nTriggerPpcc = tGroupParam.PpccPer

    local nUserAddPerStep, nUserMaxPer, nUserAddPerInit = _GetControlPer(nShopID, nGameID, nRoomID, bWin)

    nTriggerPpcc = nTriggerPpcc * -1

    -- 生成一个增长态势的随机数列
    local tTestWin = {0}
    for i = 2, #lstWin, 1 do
        local nRV = math.random(1, 100)
        if bWin == true then
            nRV = nRV * -1
        end
        tTestWin[i] = tTestWin[i -1] + nRV
    end

    -- 转换成有趋势的形式
    local tUserVal = ControlAPI.GetValToAvg(lstWin, 1, #lstWin, #tTestWin)

    -- 获取相关系数
    local nPpcc = Statist.Ppcc(tUserVal, tTestWin, 1)
    logger:info('[U] nPpcc:'..nPpcc..', nPpccPer:'..nTriggerPpcc)

    if nPpcc > nTriggerPpcc then -- 个人还是增张态势，那要加大控制概率，希望可以扭转为负增长

        local dPer = dControlPer
        assert(dPer ~= nil)
        dPer = dPer + nUserAddPerStep

        logger:info('[U] dPer:'..dPer)

        if dPer >= nUserMaxPer then
            dPer = nUserAddPerInit
            logger:info('[U] per max')
        end

        dControlPer = dPer
    else
        logger:info('[U] nPpcc:'..nPpcc)
    end

    return dControlPer
end

-- 设置redis控牌的用户
function ControlLink.SetRedisControlUser(nShopID, nGameID, nRoomID, nUserID)

    local tUser = ControlLink.m_lstControl[nUserID]
    if tUser == nil then
        return
    end

    local tRoomParam, _ = Define.GetRoomParam(nShopID, nGameID, nRoomID)
    local isCtl = tRoomParam.IsControl or 1
    if isCtl == 0 then
        logger:info('[R] close control:'..nShopID..","..nGameID..","..nRoomID)
        return
    end

    local tBlacklst = ControlPublic.GetBlacklist(nShopID)

    local sRoomKey = nShopID.."_"..nGameID.."_"..nRoomID
    local tRoom = tUser.tRoomStat[sRoomKey]

    -- 设置风控结果
    local SetRes = function(sKey, sMember, nUserID, nRes, dStat)

        -- 黑名单用户不控赢
        if nRes > 3 and tBlacklst[tostring(nUserID)] == tostring(nUserID) then
            logger:info('[U] Blacklst Userid:'..nUserID)
            nRes = 1
        end

        local tData = {}
        tData[sMember] = nUserID..'\n'..nRes..'\n'..dStat
        base.m_MyRedisData[1].redis:hmset(sKey, tData)
    end

    -- 全局控设置
    local funcUser = function ()
        logger:info('[U] set control Userid:'..nUserID)
        local tData = {}
        if tUser.nLock ~= 2 then
            local sKey ="GameControlUser"
            local sMember = string.format("%d",nUserID)
            local nRes = ControlLink.ProPer(nShopID, nGameID, nRoomID, tUser.dControlPer, tUser.nLock, tUser.nLuck, tUser.bWin)
            SetRes(sKey, sMember, nUserID, nRes, tUser.dUserStatWin)
        else
            local sKey ="GameControl"
            local sMember = string.format("%d_%d_%d",nGameID,nRoomID,nUserID)
            local nRes = ControlLink.ProPer(nShopID, nGameID, nRoomID, tUser.dControlPer, tUser.nLock, tUser.nLuck, tUser.bWin)
            SetRes(sKey, sMember, nUserID, nRes, tUser.dUserStatWin)
        end
    end

    -- 房间控设置
    local funcRoom = function ()
        logger:info('[R] set control Userid:'..nUserID..', RoomKey:'..sRoomKey)
        local tData = {}
        local sKey ="GameControl"
        local sMember = string.format("%d_%d_%d",nGameID,nRoomID,nUserID)
        local nRes = ControlLink.ProPer(nShopID, nGameID, nRoomID, tRoom.dControlPer, tRoom.nLock, tRoom.nLuck, tRoom.bWin)
        SetRes(sKey, sMember, nUserID, nRes, tRoom.dStatWin)
    end

    -- 全局和房间都监控时
        -- 一.同方向
        -- 1.都没锁定(只控房间)
        -- 2.都锁定(只控房间)
        -- 3.其中一个锁定(控锁定那个)

        -- 一.反方向
        -- 1.都没锁定(只控输那个)
        -- 2.都锁定(只控输那个)
        -- 3.其中一个锁定(控锁定那个)
    -- 只有全局监控时
        -- 只控全局
    -- 只有房间监控时
        -- 只控房间

    if tUser.dUserStatWin ~= nil and tRoom ~= nil then
        -- 一.同方向
        if tUser.bWin == tRoom.bWin then
            -- 1.都没锁定
            if tUser.nLock == 0 and tRoom.nLock == 0 then
                funcRoom()
            -- 2.都锁定
            elseif tUser.nLock >= 1 and tRoom.nLock >= 1 then                
                funcRoom()
            -- 3.其中一个锁定
            elseif tUser.nLock >= 1 and tRoom.nLock == 0 then 
                funcUser()
            elseif tUser.nLock == 0 and tRoom.nLock >= 1 then 
                funcRoom()
            end
        -- 一.反方向
        elseif tUser.bWin ~= tRoom.bWin then
            -- 1.都没锁定
            if tUser.nLock == 0 and tRoom.nLock == 0 then
                if tUser.bWin == false then -- 只控输
                    funcUser()
                else
                    funcRoom()
                end
            -- 2.都锁定
            elseif tUser.nLock >= 1 and tRoom.nLock >= 1 then
                if tUser.bWin == false then -- 只控输
                    funcUser()
                else
                    funcRoom()
                end   
            -- 3.其中一个锁定
            elseif tUser.nLock >= 1 and tRoom.nLock == 0 then 
                funcUser()
            elseif tUser.nLock == 0 and tRoom.nLock >= 1 then 
                funcRoom()                         
            end
        end
    elseif tUser.dUserStatWin ~= nil then
        funcUser()
    elseif tRoom ~= nil then
        funcRoom()
    end
end

-- 根据概率，产生控牌结果
function ControlLink.ProPer(nShopID, nGameID, nRoomID, dPer, nLock, nLuck, bWin)

    local tGroupParam = Define.GetGroupParam(nShopID)
    local tRoomParam, bDefault = Define.GetRoomParam(nShopID, nGameID, nRoomID)

    local nUserSecondGoordCardPer = tGroupParam.UserSecondGoordCardPer
    local dUserLuckPer1 = tGroupParam.UserLuckPer1
    local dUserLuckPer2 = tGroupParam.UserLuckPer2
    local dUserLuckPer3 = tGroupParam.UserLuckPer3
    local dUserLuckPer4 = tGroupParam.UserLuckPer4

    -- 如果锁定，要拿锁定的概率
    if nLock == 1 then
        if nLuck == 1 then
            dPer = dUserLuckPer1
        elseif nLuck == 2 then
            dPer = dUserLuckPer2
        elseif nLuck == 3 then
            dPer = dUserLuckPer3
        elseif nLuck == 4 then
            dPer = dUserLuckPer4                        
        end
    elseif nLock == 2 then
        if bDefault then -- 房间没设置的，就用分组公共的
            dPer = tGroupParam.FirstControlPer
        else
            dPer = tRoomParam.FirstControlPer
        end
    end

    assert(dPer >= 0)
    
    local nRes = 1
    logger:info('Per:'..dPer)
    if math.random(1, 100) < dPer then
        nRes = 2
        if math.random(1, 100) < nUserSecondGoordCardPer then -- 第二好牌
            nRes = 3
        end
        -- 控牌赢
        if bWin == true then
            nRes = 4
        end
    end
    
    if nRes == 1 then
        logger:info('C n C')
    elseif nRes == 2 then
        logger:info('C 1')
    elseif nRes == 3 then
        logger:info('C 2')
    elseif nRes == 4 then
        logger:info('C 3')
    end    
    return nRes
end

-- 为了提高游戏难度，对一般情况下，都要有一定的控牌概率
function ControlLink.SetRedisControlUser_Normal(nShopID, nGameID, nRoomID, nUserID)
    
    logger:info("SetRedisControlUser2:"..nGameID)

    local tGroupParam = Define.GetGroupParam(nShopID)
    local tRoomParam, _ = Define.GetRoomParam(nShopID, nGameID, nRoomID)

    local isCtl = tRoomParam.IsControl or 1
    if isCtl == 0 then
        logger:info('[R] close control:'..nShopID..","..nGameID..","..nRoomID)
        return
    end

    local nTmpUserSecondGoordCardPer = tRoomParam.NormalGoordCardPer
    if nTmpUserSecondGoordCardPer <= 0 then
        logger:info("SetRedisControlUser not set")
        return
    end

    local dMyStatWin = 0
    local sKey ="GameControl"
    local sMember =string.format("%d_%d_%d",nGameID,nRoomID,nUserID)

    local nTmpUserSecondGoordCardPer2 = tGroupParam.UserSecondGoordCardPer

    logger:info('[U] 2 nUserID:'..nUserID..', Per:'..nTmpUserSecondGoordCardPer)

    local nControlType = tonumber(base.m_MyRedisData[1].redis:hget(sKey, sMember))

    local tData = {}
    local nTypeVal = 1
    if math.random(1, 100) < nTmpUserSecondGoordCardPer then
        if math.random(1, 100) < nTmpUserSecondGoordCardPer2 then
            nTypeVal = 2
        else
            nTypeVal = 3
        end

        tData[sMember] = nUserID..'\n'..nTypeVal..'\n'..dMyStatWin

        if nControlType ~= nil and nControlType <= 3 and nControlType > nTypeVal then       
            return
        end

        base.m_MyRedisData[1].redis:hmset(sKey, tData)

        if nTypeVal == 1 then
            logger:info('[U] 2 nUserID:'..nUserID..', C n C')
        elseif nTypeVal == 2 then
            logger:info('[U] 2 nUserID:'..nUserID..', C 1')
        elseif nTypeVal == 3 then
            logger:info('[U] 2 nUserID:'..nUserID..', C 2')
        end
    end

end

function ControlLink.CheckShop(tItem)
    logger:info('[U] CheckShop: '..tItem.nShopId)
    ControlLink.IsControl(tItem)
    ControlLink.ControlUser(tItem.nUserId, tItem.nShopId)
end

-- 记录用户输赢
function ControlLink.OnSetUserInfo(sClientID, Data, len)    

    logger:info("OnSetUserInfo")

    local s = base.GetRP().new(Data, len)
    local Read = ProtoManager.PubProto_1_pb.REQ_Control_Room_Data()
    Read:ParseFromString(s:GetString())

    Read.nShopId = math.floor(Read.nShopId)
    Read.nGameId = math.floor(Read.nGameId)
    Read.nLevelId = math.floor(Read.nLevelId)
    Read.nUserId = math.floor(Read.nUserId)


    if Read.nShopId == -1 then
        logger:error('shopid == -1: '..sClientID)
        return
    end

    local sServerKey = ControlPublic.GetServerKeyByShopID(Read.nShopId)
    if base.m_tKey ~= sServerKey then
        if (sServerKey ~= nil) then
            base.PostToServer(sServerKey, 0, Data, len)

            logger:info('[U] Send Room other C:'..sServerKey)
        else
            logger:error('[U] C Room is nil : '..sClientID..', ShopId:'..Read.nShopId)
        end

        return
    end

    if Read.isControl == true then
        logger:info('[U] nControlType true')
    end

    ControlLink.CheckShop(Read)

    -- 清除控牌
    tPubUser.DelRedisControlUser(Read.nUserId)
    tPubUser.DelRedisControlRoom(Read.nShopId, Read.nGameId, Read.nLevelId, Read.nUserId)

    -- 是否控牌
    ControlLink.SetRedisControlUser(Read.nShopId, Read.nGameId, Read.nLevelId, Read.nUserId)

    -- 一般性控牌
    ControlLink.SetRedisControlUser_Normal(Read.nShopId, Read.nGameId, Read.nLevelId, Read.nUserId)
end

-- 记录控制操作
function ControlLink.WriteControlRecord(tData)

    if tData.nType == nil then
        tData.nType = 0
    end
    
    if tData.dVal == nil then
        tData.dVal = 0.00
    end

    local Send = ProtoManager.PubProto_1_pb.REQ_Control_Record()
    local s = base.GetSP().new(ProtoManager.Sys.DB, ProtoManager.Sub_DB.SUB_REQ_CONTROL_RECORD)

    Send.sSql = "Call ControlRecordWrite("..tData.nSId..
        ","..tData.nGId..
        ","..tData.nLId..
        ","..tData.nUId..
        ","..tData.nType..
        ",\'"..tData.dTime..
        "\',"..tData.dVal..
        ")"

    s:AddString(Send:SerializeToString())     
    base.PostDatasByType(typename.db, tData.nUId, tData.nUId, s:GetData(), s:GetSize())

    logger:info('[U] ControlRecordWrite: '..Send.sSql)
    ----------------

    local Send2 = ProtoManager.PubProto_1_pb.REQ_Control_Record() 
    Send2.sSql = "Call R_SetUserControl("..tData.nSId..
    ","..tData.nGId..
    ","..tData.nLId..
    ","..tData.nUId..
    ","..tData.nIsDel..
    ","..tData.nIsLock..
    ","..tData.nIsLuck..
    ")"
    local s2 = base.GetSP().new(ProtoManager.Sys.DB, ProtoManager.Sub_DB.SUB_REQ_CONTROL_INFO)
    s2:AddString(Send2:SerializeToString()) 
    base.PostDatasByType(typename.db, tData.nUId, tData.nUId, s2:GetData(), s2:GetSize())
    
    logger:info('[U] R_SetUserControl: '..Send2.sSql)
end

-- 删除过期数据
function ControlLink.CheckTimeOut()

    local dwCurTime = _gettime()
    local tDelUser = {}
    for nUserID, tUser in pairs(ControlLink.m_lstControl) do 
        if (dwCurTime - tUser.sRTime) > Define.m_Setting.nRoomTimeOut then
            table.insert(tDelUser, nUserID)
        end

        local tmpV = dwCurTime - tUser.sRTime
        if tmpV < 0 then
            logger:error("[U] CheckTimeOut:"..tmpV)
        end
    end

    logger:info('[U] CheckTimeOut del count:'..#tDelUser)

    for _, nUserID in ipairs(tDelUser) do 
        local tUser = ControlLink.m_lstControl[nUserID]

        logger:info("[U] UserID:"..nUserID.." Cancel Monitor timeout")

        if tUser.dUserStatWin ~= nil then

            local nType = 22
            if tUser.bWin == true then
                nType = 32
            end

            ControlLink.WriteControlRecord({nSId = -1, nGId = -1, nLId = -1, 
            nUId = nUserID, 
            nType = nType, 
            dTime = os.date("%Y-%m-%d %H:%M:%S"),
            nIsDel = 1,
            nIsLock = tUser.nLock >= 1 and tUser.nLock or 0,
            nIsLuck = tUser.nLuck >= 1 and tUser.nLuck or 0})
        end

        for sRoomKey, tRoom in pairs(tUser.tRoomStat) do
            
            local tV = publicApi.string_split(sRoomKey, '_')
            local nShopid = tonumber(tV[1])
            local nGameId = tonumber(tV[2])
            local nRoomId = tonumber(tV[3])

            local nType = 52
            if tRoom.bWin == true then
                nType = 62
            end  

            ControlLink.WriteControlRecord({nSId = nShopid, nGId = nGameId, nLId = nRoomId, 
            nUId = nUserID, 
            nType = nType, 
            dTime = os.date("%Y-%m-%d %H:%M:%S"),
            nIsDel = 1,
            nIsLock = tRoom.nLock >= 1 and tRoom.nLock or 0,
            nIsLuck = tRoom.nLuck >= 1 and tRoom.nLuck or 0})           
        end
        
        ControlLink.m_lstControl[nUserID] = nil
    end

end

return ControlLink