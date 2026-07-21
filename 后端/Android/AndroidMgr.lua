--机器人管理（存，取，新增）
local Define = require("Define")
local tPublicRedis = require("PublicRedis")
local tSrvInfo = require("ServerInfo")
local tALog = require("AndroidLog")
local NameLibMgr = require("NameLibMgr")
local tBaseSink = require("BaseSink")
local tAndroidData = require("AndroidData")
local FactoryUserId = require("FactoryUserId")
local cjson = require("cjson")
local tBase = require("base")
local ProtoManager = require("ProtoManager")
local tPublicApi = require("publicApi")

local AndroidMgr = {}

function AndroidMgr.Init()
    AndroidMgr.CheckInvalid()
    NameLibMgr.Init()
    FactoryUserId.InitBaseUserId()
    AndroidMgr.ReCoverRedisData()
end

local function _GetAnCfgStr(nAnCfgId)
    local str = "合集机器人"
    if nAnCfgId and nAnCfgId == 2 then 
        str = "app机器人"
    end 
    -- if nAnCfgId and nAnCfgId == 3 then
    --     str = "后端生成机器人"
    -- end
    return str
end

--创建新的机器人
--@params nGrpId分组id  nAnCfgId:机器人类型id:1:合集机器人,2:app机器人
--@return true:成功  false:失败
function AndroidMgr.CreateNewAndroid(nGrpId,nAnCfgId)
    --先判断下有没有别的服设置了事务锁
    local arrAndroidLock = tPublicRedis.GetAndroidLock(tSrvInfo.nServerId)
    if #arrAndroidLock>0 then
        tALog.Print("_CreateNewAndroid 有别的机器人服(%s)设置了事务锁",cjson.encode(arrAndroidLock))
        return false
    end
    local sAnCfgStr = _GetAnCfgStr(nAnCfgId)
    local arrManHead = {}
    local arrLadyHead = {}
    local min = math.floor(tAndroidData.AnConfig.nHeadIdRangeMin)
    local max = math.floor(tAndroidData.AnConfig.nHeadIdRangeMax)
    for i=min,max do
        if i % 2 == 1 then
            table.insert(arrManHead, i)
        else
            table.insert(arrLadyHead, i)
        end
    end
    local tempArrManHead = arrManHead
    local temparrLadyHead = arrLadyHead
    FactoryUserId.RefreshUserId()
    local nRealNameMax = AndroidMgr.GetProduceRealNameAnCnt(nGrpId,Define.CreateCount,nAnCfgId)
    tALog.Print("_CreateNewAndroid 分组_%d %s 需要生成昵称机器人 %d个",nGrpId,sAnCfgStr,nRealNameMax)
    local arrAndroidName = NameLibMgr.PopAndroidNBatch(nGrpId,nAnCfgId,nRealNameMax) --先取一批机器人昵称出来
    local nNickLib, nNotNickLib = 0, 0
    local sErr = ""
    local nRealRate = NameLibMgr.GetGrpRealRate(nGrpId) or 1 --分组昵称机器人比例
    -- if nAnCfgId == 3 then
    --     nRealRate = 0
    -- end
    if nAnCfgId==2 and #arrAndroidName==0 then
        return false
    end
    local tLoadAndroid = {}
    local tNickAndroid = {}
    local tNotNickAndroid = {}
    local arrAnItem = {} 
    local sArrUserId = ""
    for i=1, Define.CreateCount do
        local nUserId = FactoryUserId.GetOneUserId()
        local tAnLib = table.remove(arrAndroidName,1)
        if tAnLib then
            tAnLib.isNickLib = true
        else
            --没有昵称就用默认的非昵称lib数据
            local nSex, nHeadId = AndroidMgr.GetSexAndHeadId(i,tempArrManHead,arrManHead,temparrLadyHead,arrLadyHead)
            tAnLib = AndroidMgr.GetGuestAnLib(nGrpId,nUserId,nSex,nHeadId)
        end
        -- if nAnCfgId == 3 then
        --     local nSex, nHeadId = AndroidMgr.GetSexAndHeadId(i,tempArrManHead,arrManHead,temparrLadyHead,arrLadyHead)
        --     tAnLib = AndroidMgr.GetGuestAnLib(nGrpId,nUserId,nSex,nHeadId)
        -- end
        if not tAnLib.isNickLib and nRealRate and nRealRate==1 then
            sErr = string.format("_CreateNewAndroid  分组_%d,昵称机器人占比为%d%%，昵称已用完, 无法生成新的机器人",nGrpId,nRealRate*100)
            break
        end
        if nUserId <= 0 then
            sErr = string.format("_CreateNewAndroid  机器人UserId已用完，无法生成新的机器人",nGrpId)
            break
        end
        tLoadAndroid[nUserId] = nUserId
        if tAnLib.isNickLib then
            nNickLib = nNickLib + 1
            tNickAndroid[nUserId] = nUserId
        else
            nNotNickLib = nNotNickLib + 1
            tNotNickAndroid[nUserId] = nUserId
        end
        local tAnItem = AndroidMgr.CreateAnItem()
        tAnItem.nUserId = nUserId
        tAnItem.sNickName = tAnLib.sNickName
        tAnItem.sHeadUrl = tAnLib.sHeadUrl
        tAnItem.nSex = tAnLib.nSex --nSex 
        tAnItem.nGrpId = nGrpId
        tAnItem.sShopAcc = tAnLib.sShopAcc or ""
        tAnItem.nLanguageId = tAnLib.nLanguage or 0
        -- tAnItem.nAnCfgId = nAnCfgId
        tAnItem.nChannelID =tAnLib.nChannelID
        tAnItem.nShopId =tAnLib.nShopId

        AndroidMgr.PushAndroid(tAnItem)
        AndroidMgr.PushAndroidToFreeQueue(tAnItem)
        table.insert(arrAnItem,tAnItem)
        -- tALog.Print("_CreateNewAndroid  分组GrpId_%d %s  新生成nUserId_%d,sShopAcc_%s,nLanguageId_%d",
        -- nGrpId,nAnCfgId,nUserId,tAnItem.sShopAcc,tAnItem.nLanguageId)

        sArrUserId = sArrUserId..string.format("%d,",nUserId) 
    end
    --保存服务器加载的机器人id
    if nNickLib+nNotNickLib>0 then
        tPublicRedis.SetRedisAndroidInfoBatch(arrAnItem)
        tPublicRedis.SetServerLoadAndroid(tSrvInfo.nServerId,tLoadAndroid)
        FactoryUserId.SetUseUserIdToRedis()
    end

    --按分组保存新生成的昵称机器人key
    if nNickLib>0 then
        tPublicRedis.SetAndroidGrpKey(nGrpId,nAnCfgId,tNickAndroid)
    end

    --按分组保存新生成的非昵称机器人key
    if nNotNickLib>0 then
        tPublicRedis.SetAndroidGrpKey(nGrpId,1,tNotNickAndroid)
    end  
    local sStr=string.format("空闲: %d=[app: %d 合集: %d  非昵称: %d ]",AndroidMgr.GetFreeAndroidCnt(nGrpId))
    local Str=string.format("新生成昵称: %d  非昵称_%d  新生成ArrUserId: %s  ",nNickLib, nNotNickLib,sArrUserId)
    tALog.Print("_CreateNewAndroid   分组_%d %s %s   ",nGrpId,sStr,Str)
    return true
end

--加载redis上的机器人
--@params nGrpId 分组id nAnCfgId:机器人类型id:1:合集机器人,2:app机器人
--@Return true:加载成功，false:加载失败
function AndroidMgr.LoadRedisAndroid(nGrpId,nAnCfgId)
    --先判断下有没有别的服设置了事务锁
    local arrAndroidLock = tPublicRedis.GetAndroidLock(tSrvInfo.nServerId)
    if #arrAndroidLock>0 then
        tALog.Print("_LoadRedisAndroid  有别的机器人服(%s)设置了事务锁",cjson.encode(arrAndroidLock))
        return false
    end
    --获取各个机器人服从redis上获取的机器人id
    local tServerAndroidId = tPublicRedis.GetAllServerLoadAndroid()
    local tAndroidId = {}
    for nServerId,arrUserId in pairs(tServerAndroidId) do
        for _,nUserId in pairs(arrUserId) do
            tAndroidId[nUserId] = nUserId
        end
    end
    -- tBase.LogT("[AndroidMgr.LoadRedisAndroid] tAndroidId = ",tAndroidId)
    local tS = tAndroidData.tRedisDataToStr
    local sAnCfgStr = _GetAnCfgStr(nAnCfgId) 

    local nCnt = 0 --从redis上获取的机器人个数
    local tFreeAndroidId = {} --本次从redis上获取的机器人
    local arrAndroidKey = tPublicRedis.GetAndroidKey(nGrpId,nAnCfgId)
    local tDelAndroid = {} --被删除掉数据的机器人
    for _, sUserId in pairs(arrAndroidKey) do
        local nUserId = tonumber(sUserId) or 0
        nUserId = math.floor(nUserId)
        if nUserId~=0 and not tAndroidId[nUserId] then
            --还没被任何一个机器人服获取
            if not AndroidMgr.HasLoadThisAndroid(nUserId) then
                local tItem =  tPublicRedis.GetRedisAndroidInfo(nUserId)
                if tItem and tItem.nUserId then
                    local tAnItem = {}
                    for k, v in pairs(tItem) do
                        if not tS[k] then
                            tAnItem[k] = tonumber(v)
                        else
                            tAnItem[k] = v
                        end
                    end
                    AndroidMgr.PushAndroid(tAnItem)
                    AndroidMgr.PushAndroidToFreeQueue(tAnItem) --将机器人插入空闲队列末尾
                    tFreeAndroidId[nUserId] = nUserId --记录
                    nCnt = nCnt + 1
                    tALog.Print("_LoadRedisAndroid nGrpId_%d,nAnCfgId_%d(1:合集机器人,2:app机器人),从redis上读取机器人:nUserId_%d,sShopAcc_%s,nLanguageId_%d",
                    nGrpId,nAnCfgId,tAnItem.nUserId,tAnItem.sShopAcc,tAnItem.nLanguageId)
                else
                    tDelAndroid[nUserId] = {nGrpId=nGrpId,nAnCfgId=nAnCfgId,nUserId=nUserId}
                    tALog.Print("_LoadRedisAndroid  nGrpId_%d,nAnCfgId_%d %s,nUserId_%d已从redis上删除",
                    nGrpId,nAnCfgId,sAnCfgStr,nUserId)
                end
            else
                tALog.Print("_LoadRedisAndroid nGrpId_%d,nAnCfgId_%d %s ,nUserId_%d加载数据被异常清除",
                    nGrpId,nAnCfgId,sAnCfgStr,nUserId)
                tFreeAndroidId[nUserId] = nUserId --记录
            end
        end
        if nCnt>=Define.LoadCount then
            break
        end
    end
    tPublicRedis.DelAndroidKey(tDelAndroid)
    --记录到本服获取的机器人到redis上
    if nCnt>0 then
        tPublicRedis.SetServerLoadAndroid(tSrvInfo.nServerId,tFreeAndroidId)
    end
    tALog.Print("_LoadRedisAndroid  本服分组:%d空闲机器人%d个(app机器人:%d个,合集机器人:%d个,非昵称机器人:%d个)",nGrpId,AndroidMgr.GetFreeAndroidCnt(nGrpId))
    return true
end

--在空闲队列中取出机器人
--@params nGrpId分组id  nAnCfgId:机器人类型id:1:合集机器人,2:app机器人 nCnt需要人数
--@return 机器人数组{tAnItem,tAnItem,...} 
function AndroidMgr.GetAndroidInFreeQueue(nGrpId,nAnCfgId,nCnt) 
    local arrData = {}
    if tAndroidData.arrFreeQueue[nGrpId] and nCnt > 0 then
        for i=1,nCnt do
            for nIndex,v in pairs(tAndroidData.arrFreeQueue[nGrpId]) do
                local tAnItem = AndroidMgr.GetAndroid(nGrpId,v.nUserId)
                if tAnItem then
                    local isAppAn = AndroidMgr.IsAppAndroid(tAnItem)
                    if (nAnCfgId==1 and not isAppAn) or (nAnCfgId==2 and isAppAn) then --todo 
                        --（需要合集机器人时，这个机器人不是app机器人） 或者  （需要app机器人时，这个机器人是app机器人）
                        table.insert(arrData,tAnItem)
                        tAndroidData.arrFreeQueue[nGrpId][nIndex] = nil
                        -- tALog.Print("[AndroidMgr.GetAndroidInFreeQueue]找到机器人:nIndex:%d,nUserId_%d,sShopAcc_%s,nLanguageId_%d",
                        --     nIndex,tAnItem.nUserId,tAnItem.sShopAcc,tAnItem.nLanguageId)
                        break
                    end
                else
                    tALog.Print("_GetAndroidInFreeQueue  机器人不存在:nGrpId_%d,nUserId_%d,nIndex:%d",nGrpId,tAnItem.nUserId,nIndex)
                    tAndroidData.arrFreeQueue[nGrpId][nIndex] = nil
                end
            end
        end
    end
    return arrData
end

--是不是app机器人
--@params nGrpId分组id  nAnCfgId:机器人类型id:1:合集机器人,2:app机器人 nCnt需要人数
--@return true 是  false 不是
function AndroidMgr.IsAppAndroid(tAnItem)
    --app机器人的第三方id是一串比较长的字符串，如1205050830
    if tAnItem and tAnItem.sShopAcc and tAnItem.sShopAcc~="" and tAnItem.sShopAcc~="0" then
        return true
    end
    return false
end

--从空闲机器人的队列取出机器人
--tData = {nGrpId=23,nMin=1, nHigh=100000, nCnt=3} nAnCfgId 机器人类型id:1:合集机器人,2:app机器人
--@return 机器人数组{tAnItem,tAnItem,...}
function AndroidMgr.PopAndroid(tData,nAnCfgId)
    local isNeedLoad,isNeedCreate = false,false
    local nCnt = tData.nCnt
	local arrAndroid = AndroidMgr.GetAndroidInFreeQueue(tData.nGrpId,nAnCfgId,tData.nCnt) --先从空闲队列中取出机器人

    --空闲队列没有机器人
    if #arrAndroid == 0 then
        isNeedLoad = true
        --设置事务锁
        local arrAndroidLock = tPublicRedis.GetAndroidLock(tSrvInfo.nServerId)
        if #arrAndroidLock>0 then
            tALog.Print("_PopAndroid    有别的机器人服(%s)设置了事务锁",cjson.encode(arrAndroidLock))
            return arrAndroid
        end
        tPublicRedis.SetAndroidLock(tSrvInfo.nServerId)
    end    
    if isNeedLoad then
        --从redis上加载一批机器人并加入空闲队列
        AndroidMgr.GetAndroidBasicConfig(tData.nGrpId) --获取机器人后台配置信息
        local isSuccee = AndroidMgr.LoadRedisAndroid(tData.nGrpId,nAnCfgId) 
        if isSuccee then
            arrAndroid = AndroidMgr.GetAndroidInFreeQueue(tData.nGrpId,nAnCfgId,tData.nCnt) --再从空闲队列中取出机器人
            --从redis上也没获取到机器人，那就要新生成一批机器人了
            if #arrAndroid == 0 then
                isNeedCreate = true
            end
        end
    end
    if isNeedCreate then
        --新生成一批机器人
        local isSuccee = AndroidMgr.CreateNewAndroid(tData.nGrpId,nAnCfgId) 
        if isSuccee then
            arrAndroid = AndroidMgr.GetAndroidInFreeQueue(tData.nGrpId,nAnCfgId,tData.nCnt) --再从空闲队列中取出机器人
        end
    end
    if isNeedLoad or isNeedCreate then
        --删除事务锁
        tPublicRedis.DelAndroidLock(tSrvInfo.nServerId)
    end
    return arrAndroid
end

--把机器人加入到空闲队列
--@params tAnItem机器人信息
function AndroidMgr.PushAndroidToFreeQueue(tAnItem)
    local nGrpId = tAnItem.nGrpId
    local nUserId = tAnItem.nUserId
    if not tAndroidData.arrFreeQueue[nGrpId] then
        tAndroidData.arrFreeQueue[nGrpId] = {}
    end
    local t = {}
    t.nUserId = nUserId
    t.nGrpId = nGrpId
    tAndroidData.arrFreeQueue[nGrpId][nUserId] = t
end

--把机器人加入休息队列
--@params tAnItem机器人信息
function AndroidMgr.PushAndroidToRestQueue(tAnItem)
    local nGrpId = tAnItem.nGrpId
    local nUserId = tAnItem.nUserId
    if not nGrpId or not nUserId then
        tALog.Print("_PushAndroidToRestQueue  参数错误,nGrpId:%s,nUserId:%s",tostring(nGrpId),tostring(nUserId))
        return
    end
    if not tAndroidData.arrRestQueue[nGrpId] then
        tAndroidData.arrRestQueue[nGrpId] = {}
    end
    local t = {}
    t.nUserId = nUserId
    t.nGrpId = nGrpId
    t.nTime = os.time()
    t.nRestTime = AndroidMgr.GetRestTime(nGrpId)
    tAndroidData.arrRestQueue[nGrpId][nUserId] = t
end

--记录本服的机器人信息
--@params tAnItem机器人信息
function AndroidMgr.PushAndroid(tAnItem)
    local nGrpId = tAnItem.nGrpId
    local nUserId = tAnItem.nUserId
    if not tAndroidData.arrAllAndroid[nGrpId] then
        tAndroidData.arrAllAndroid[nGrpId] = {}
    end
    tAndroidData.arrAllAndroid[nGrpId][nUserId] = tAnItem
end

--获取机器人信息
--@params nGrpId:分组id  nUserId:机器人id
--@return tAnItem机器人信息
function AndroidMgr.GetAndroid(nGrpId,nUserId)
    if tAndroidData.arrAllAndroid[nGrpId] then
        return tAndroidData.arrAllAndroid[nGrpId][nUserId]
    end
    return
end

--获取本服机器人数量
--@params nGrpId分组id
--@return 机器人总数,app机器人数(昵称),合集机器人数(昵称),非昵称机器人数
function AndroidMgr.GetAndroidCnt(nGrpId)
    local nTotalCnt = 0
    local nAppNameCnt = 0
    local nHJNameCnt = 0
    local nNotNameCnt = 0
    if tAndroidData.arrAllAndroid[nGrpId] then
        for nUserId,tAnItem in pairs(tAndroidData.arrAllAndroid[nGrpId]) do
            nTotalCnt = nTotalCnt + 1
            if tAnItem.sShopAcc and tAnItem.sShopAcc~="" then
                if tAnItem.sShopAcc=="0" then
                    nHJNameCnt = nHJNameCnt + 1
                else
                    nAppNameCnt = nAppNameCnt + 1
                end
            else
                nNotNameCnt = nNotNameCnt + 1
            end
        end
    end
    -- tALog.Print("[AndroidMgr.GetAndroidCnt]本服分组:%d机器人%d个(app机器人:%d个,合集机器人:%d个,非昵称机器人:%d个)",
    -- nGrpId,nTotalCnt,nAppNameCnt,nHJNameCnt,nNotNameCnt)
    return nTotalCnt,nAppNameCnt,nHJNameCnt,nNotNameCnt
end

--获取本服空闲机器人数量
--@params nGrpId分组id
--@return 机器人总数,app机器人数(昵称),合集机器人数(昵称),非昵称机器人数
function AndroidMgr.GetFreeAndroidCnt(nGrpId)
    local nTotalCnt = 0
    local nAppNameCnt = 0
    local nHJNameCnt = 0
    local nNotNameCnt = 0
    if tAndroidData.arrFreeQueue[nGrpId] then
        for _,v in pairs(tAndroidData.arrFreeQueue[nGrpId]) do
            local tAnItem = AndroidMgr.GetAndroid(nGrpId,v.nUserId)
            if tAnItem then
                nTotalCnt = nTotalCnt + 1
                if tAnItem.sShopAcc and tAnItem.sShopAcc~="" then
                    if tAnItem.sShopAcc=="0" then
                        nHJNameCnt = nHJNameCnt + 1
                    else
                        nAppNameCnt = nAppNameCnt + 1
                    end
                else
                    nNotNameCnt = nNotNameCnt + 1
                end
            else
                tAndroidData.arrFreeQueue[nGrpId][v.nUserId] = nil
            end
        end
    end
    -- tALog.Print("[AndroidMgr.GetFreeAndroidCnt]本服分组:%d空闲机器人%d个(app机器人:%d个,合集机器人:%d个,非昵称机器人:%d个)",
    -- nGrpId,nTotalCnt,nAppNameCnt,nHJNameCnt,nNotNameCnt)
    return nTotalCnt,nAppNameCnt,nHJNameCnt,nNotNameCnt
end

--获取本服休息中机器人数量
--@params nGrpId分组id
--@return 机器人总数,app机器人数(昵称),合集机器人数(昵称),非昵称机器人数
function AndroidMgr.GetRestAndroidCnt(nGrpId)
    local nTotalCnt = 0
    local nAppNameCnt = 0
    local nHJNameCnt = 0
    local nNotNameCnt = 0
    if tAndroidData.arrRestQueue[nGrpId] then
        for _,v in pairs(tAndroidData.arrRestQueue[nGrpId]) do
            local tAnItem = AndroidMgr.GetAndroid(nGrpId,v.nUserId)
            if tAnItem then
                nTotalCnt = nTotalCnt + 1
                if tAnItem.sShopAcc and tAnItem.sShopAcc~="" then
                    if tAnItem.sShopAcc=="0" then
                        nHJNameCnt = nHJNameCnt + 1
                    else
                        nAppNameCnt = nAppNameCnt + 1
                    end
                else
                    nNotNameCnt = nNotNameCnt + 1
                end
            else
                tAndroidData.arrRestQueue[nGrpId][v.nUserId] = nil
            end
        end
    end
    -- tALog.Print("[AndroidMgr.GetFreeAndroidCnt]本服分组:%d空闲机器人%d个(app机器人:%d个,合集机器人:%d个,非昵称机器人:%d个)",
    -- nGrpId,nTotalCnt,nAppNameCnt,nHJNameCnt,nNotNameCnt)
    return nTotalCnt,nAppNameCnt,nHJNameCnt,nNotNameCnt
end

--根据当前分组的实际真人昵称比例，与系统昵称比例生成真人机器人数
--@params nGrpId:分组，nProduceCnt:个数， nAnCfgId:机器人类型id:1:合集机器人,2:app机器人
--@return nRealCnt 要生成的昵称机器人个数(默认0个)
function AndroidMgr.GetProduceRealNameAnCnt(nGrpId, nProduceCnt, nAnCfgId)
    local nRealRate = NameLibMgr.GetGrpRealRate(nGrpId)
    -- if nAnCfgId == 3 then
    --     nRealRate = 0
    -- end
    if not nRealRate then
        nRealRate = 1
        local sKey = string.format("_GetProduceRealNameAnCn   分组_%d 没有设置昵称机器人比例,默认采用比例_%d,",nGrpId,nAnCfgId,nRealRate)
        local sErr = sKey.."防止生成非昵称机器人,请在后台设置昵称机器人比例"
        tALog.Print(sErr)
        tALog.SendMsgToTG(sKey,sErr)
    end
    local nTotalCnt,nAppNameCnt,nHJNameCnt,nNotNameCnt = AndroidMgr.GetAndroidCnt(nGrpId)
    local nTotalAn = nTotalCnt --机器人总数
    local nNickAn = nHJNameCnt --昵称机器人数量
    if nAnCfgId == 2 then
        nNickAn = nAppNameCnt
    end
    local nRealCnt, nRound = 0, 0
    while (nRound <= nProduceCnt) do
        local nNowRate = (nTotalAn==0 and 0) or (nNickAn / nTotalAn)
        if nRealRate > nNowRate then
            nNickAn = nNickAn + 1
            nRealCnt = nRealCnt + 1
        end
        nTotalAn = nTotalAn + 1
        nRound = nRound + 1
    end
    if nRealCnt>nProduceCnt then
        nRealCnt = nProduceCnt
    end
    return nRealCnt
end

--获取机器人后台配置信息
--@params nGrpId分组id
function AndroidMgr.GetAndroidBasicConfig(nGrpId)
    --默认头像路径
    tALog.Print("_GetAndroidBasicConfig  nGrpId_%d",nGrpId)
    local defaultSheadPath = "game/head/"
    local tConfig = tPublicRedis._GetAndroidBasicConfig(nGrpId)
    if tConfig then
        if tConfig.sHeadPath then
            tAndroidData.AnConfig.sHeadPath = tConfig.sHeadPath
            tAndroidData.AnConfig.IsDefaultHeadPath = false
        else
            tAndroidData.AnConfig.sHeadPath = defaultSheadPath
            tAndroidData.AnConfig.IsDefaultHeadPath = true
        end
        
        tAndroidData.AnConfig.nHeadIdRangeMin = tonumber(tConfig.nHeadIdRangeMin)
        tAndroidData.AnConfig.nHeadIdRangeMax = tonumber(tConfig.nHeadIdRangeMax)
        tAndroidData.AnConfig.nMinRound = tonumber(tConfig.nMinRound) 
        tAndroidData.AnConfig.nMaxRound = tonumber(tConfig.nMaxRound) 
        tAndroidData.AnConfig.nProductCnt = tonumber(tConfig.nProductCnt)
        tAndroidData.AnConfig.nLongReleaxMin = tonumber(tConfig.nLongReleaxMin)  
        tAndroidData.AnConfig.nLongReleaxMax = tonumber(tConfig.nLongReleaxMax) 
        tAndroidData.AnConfig.nShortReleaxMin = tonumber(tConfig.nShortReleaxMin)    
        tAndroidData.AnConfig.nShortReleaxMax = tonumber(tConfig.nShortReleaxMax) 
        tALog.Print("_GetAndroidBasicConfig  from redis: nLongReleaxMin:%d nMinRound:%d nMaxRound:%d nProductCnt:%d", tAndroidData.AnConfig.nLongReleaxMin, tAndroidData.AnConfig.nMinRound,
        tAndroidData.AnConfig.nMaxRound, tAndroidData.AnConfig.nProductCnt)
    else
        tAndroidData.AnConfig.sHeadPath = defaultSheadPath
        tAndroidData.AnConfig.nHeadIdRangeMin = 1
        tAndroidData.AnConfig.nHeadIdRangeMax = 30
        tAndroidData.AnConfig.nMinRound = 50
        tAndroidData.AnConfig.nMaxRound = 100 
        tAndroidData.AnConfig.nProductCnt = 500
        tAndroidData.AnConfig.nLongReleaxMin = 60  
        tAndroidData.AnConfig.nLongReleaxMax = 60*2  
        tAndroidData.AnConfig.nShortReleaxMin = 60  
        tAndroidData.AnConfig.nShortReleaxMax = 60*2  
        tAndroidData.AnConfig.IsDefaultHeadPath = true
        tALog.Print("_GetAndroidBasicConfig from default nLongReleaxMin:%d nMinRound:%d nMaxRound:%d nProductCnt:%d", tAndroidData.AnConfig.nLongReleaxMin, tAndroidData.AnConfig.nMinRound,
             tAndroidData.AnConfig.nMaxRound, tAndroidData.AnConfig.nProductCnt)
    end
end

--构建机器人数据
--@return tAnItem:机器人信息
function AndroidMgr.CreateAnItem()
    local tAnItem = {}
    tAnItem.nUserId = 0
    tAnItem.sAccounts = "xiaodandan"
    tAnItem.sNickName = "MA=="
    tAnItem.sHeadUrl = "game/head/0"
    tAnItem.nSex = 0 
    tAnItem.nSleep = 77
    tAnItem.nDiamond = 77
    tAnItem.nMinRound =  tAndroidData.AnConfig.nMinRound or 50
    tAnItem.nMaxRound = tAndroidData.AnConfig.nMaxRound or 100
    tAnItem.nMinppty = 88
    tAnItem.nMaxppty = 88
    tAnItem.sInvite_Code = "xiaodandan"
    tAnItem.sLocation = "xiaoaa"
    tAnItem.nStatus = 0
    tAnItem.nGold = math.random(7000, 1000000)
    tAnItem.nGrpId = 0
    tAnItem.sOnlineT = "#0#1#2#3#4#5#6#7#8#9#10#11#12#13#14#15#16#17#18#19#20#21#22#23#24#"
    tAnItem.nWin = math.random(10,20)
    tAnItem.nLose = math.random(tAnItem.nWin - 5,tAnItem.nWin + 5)
    tAnItem.nSimilar = 0
    tAnItem.sShopAcc = ""
    tAnItem.nLanguageId = 0
    tAnItem.nServerId = 0
    tAnItem.nChannelID =-1
    tAnItem.nShopId =-1
    -- tAnItem.nAnCfgId = 1
    return tAnItem
end

--获取非昵称机器人
--@params nGrpId:分组id nUserId:机器人id nSex:性别 nHeadId:头像id
--@return tAnLib:昵称信息
function AndroidMgr.GetGuestAnLib(nGrpId,nUserId,nSex,nHeadId)
    local tAnLib = {}
    tAnLib.sNickName = string.format("%s%.3d", NameLibMgr.GetFirstName(nGrpId), ((nUserId) % 1000))
    tAnLib.sNickName = tBaseSink.encode(tAnLib.sNickName)
    local headLocation = tAndroidData.AnConfig.sHeadPath
    if tAndroidData.AnConfig.IsDefaultHeadPath then
        tAnLib.sHeadUrl = headLocation..nHeadId
    else
        tAnLib.sHeadUrl = headLocation..nHeadId..".jpg"
    end
    tAnLib.nSex = nSex
    tAnLib.isNickLib = false
    tAnLib.nId = -0xFF
    tAnLib.sShopAcc = ""
    tAnLib.nLanguageId = 0
    tAnLib.nChannelID =-1
    tAnLib.nShopId =-1
    return tAnLib
end

--获取性别和头像id
--@params idx：第几个  tempArrManHead:男机器人临时头像id数组 arrManHead:男机器人头像id数组
--@params temparrLadyHead:女机器人临时头像id数组 arrLadyHead:女机器人头像id数组
--@return nSex:性别 nHeadId:头像id
function AndroidMgr.GetSexAndHeadId(idx,tempArrManHead,arrManHead,temparrLadyHead,arrLadyHead)
    local nSex, nHeadId = -1, -1
    if #tempArrManHead <= 0 then
        tempArrManHead = arrManHead
    end
    if #temparrLadyHead <= 0 then
        temparrLadyHead = arrLadyHead
    end
    if idx % 2 == 0 then
        nSex = 0
        nHeadId = tempArrManHead[1]
        table.remove(tempArrManHead,1)
    else
        nSex = 1
        nHeadId = temparrLadyHead[1]
        table.remove(tempArrManHead,1)
    end
    if not nHeadId then 
        nHeadId = math.random(1,30)
    end 
    return nSex, nHeadId
end

--每秒检查机器人状态
function AndroidMgr.CheckAndroid()
    -- tALog.Print("==================例行检测 start ==================")
    local nNowTime = os.time()
    --把休息完的机器人放回空闲队列
    for nGrpId,arrRestAndroid in pairs(tAndroidData.arrRestQueue) do
        for nUserId,tRestAn in pairs(arrRestAndroid) do
            if nNowTime - tRestAn.nTime > tRestAn.nRestTime then
                AndroidMgr.PushAndroidToFreeQueue(tRestAn)
                tAndroidData.arrRestQueue[nGrpId][nUserId] = nil
            end
        end
    end
    --各分组空闲机器人情况
    for nGrpId,tGrpAn in pairs(tAndroidData.arrAllAndroid) do
        local nTotalAnCnt = AndroidMgr.GetAndroidCnt(nGrpId)
        local nTotalFreeAnCnt = AndroidMgr.GetFreeAndroidCnt(nGrpId)
        if nTotalAnCnt>0 then
            tAndroidData.tCanUseRate[nGrpId] = math.floor(nTotalFreeAnCnt/nTotalAnCnt*100)
        else
            tAndroidData.tCanUseRate[nGrpId] = 0
        end
    end
    -- tALog.Print("==================例行检测  end ==================")
end

--获取机器人休息时间
--@params nGrpId:分组id
--@return nRetTime:休息时间
function AndroidMgr.GetRestTime(nGrpId)
    local LIMIT = 70
    local nDeductPercent = 0
    local nCanUseRate = tAndroidData.tCanUseRate[nGrpId] or 0
    local isRelaxLong = true
    if nCanUseRate < LIMIT then
        --空闲的机器人少，用短休息时间
        isRelaxLong = false
    end
    local nRetTime = 0
    local nReleaxMinTime = 0
    local nReleaxMaxTime = 0
    if isRelaxLong then
        nReleaxMinTime = tAndroidData.AnConfig.nLongReleaxMin
        nReleaxMaxTime = tAndroidData.AnConfig.nLongReleaxMax
    else
        nReleaxMinTime = tAndroidData.AnConfig.nShortReleaxMin
        nReleaxMaxTime = tAndroidData.AnConfig.nShortReleaxMax
    end
    if not nReleaxMinTime or nReleaxMinTime==0 then
        nReleaxMinTime = 60
    end
    if not nReleaxMaxTime or nReleaxMaxTime==0 then
        nReleaxMaxTime = nReleaxMinTime*2
    end
    nRetTime = math.random(nReleaxMinTime,nReleaxMaxTime)
    return nRetTime
end

--设置机器人借出
--@params sClientID:服务器key arrAndroid:机器人数组
function AndroidMgr.SetAndroidLend(sClientID,arrAndroid)
    local sServerKey = tPublicApi.GetServerKey(sClientID)
    if not tAndroidData.tLendAndroid[sServerKey] then
        tAndroidData.tLendAndroid[sServerKey] = {}
    end
    local tAndroidKey = {}
    for _,tItem in pairs(arrAndroid) do
        local tAnItem = {}
        for a, b in pairs(ProtoManager.PubProto_pb.AndroidItem()._setter) do 
            tAnItem[a] = tItem[a]
        end
        tAndroidKey[tAnItem.nUserId] = sServerKey
        if not tAndroidData.tLendAndroid[sServerKey][tAnItem.nGrpId] then
            tAndroidData.tLendAndroid[sServerKey][tAnItem.nGrpId] = {}
        end
        tAndroidData.tLendAndroid[sServerKey][tAnItem.nGrpId][tAnItem.nUserId] = tAnItem
    end
    tPublicRedis.SetLendAndroid(tSrvInfo.nServerId,tAndroidKey)
end

--是否是本服借出的机器人
--@params tAnItem：机器人信息
--@return true:是   false:不是
function AndroidMgr.IsServerAndroid(sClientID,tAnItem)
    local sServerKey = tPublicApi.GetServerKey(sClientID)
    --是否是本服的机器人
    if tAnItem.nServerId == tSrvInfo.nServerId then
        --是否是本服借出给游戏服的机器人
        if tAndroidData.tLendAndroid[sServerKey] then
            local tData = tAndroidData.tLendAndroid[sServerKey]
            if tData[tAnItem.nGrpId] and tData[tAnItem.nGrpId][tAnItem.nUserId] then
                --是否是这个游戏服借了的机器人
                return true
            else
                tALog.Print("_IsServerAndroid  游戏服_%s机器人重复归还,nUserId_%d,nServerId_%d",sServerKey,tAnItem.nUserId,tAnItem.nServerId)
            end
        else
            tALog.Print("_IsServerAndroid  不本服借出给游戏服%s的机器人,nUserId_%d,nServerId_%d",sServerKey,tAnItem.nUserId,tAnItem.nServerId)
        end
    else
        tALog.Print("_IsServerAndroid  不是本服的机器人,nUserId_%d,nServerId_%d",tAnItem.nUserId,tAnItem.nServerId)
    end
    return false
end

--是否借出该机器人
--@params nGrpId:分组id  nUserId:玩家id
--@return true：是， false：不是
function AndroidMgr.IsLend(nGrpId,nUserId)
    for _, tData in pairs(tAndroidData.tLendAndroid) do
        if tData[nGrpId] and tData[nGrpId][nUserId] then
            return true
        end
    end
    return false
end

--设置机器人归还
--@params sClientID:服务器key arrAndroid:机器人数组
function AndroidMgr.SetAndroidReturn(sClientID,arrAndroid)
    local sServerKey = tPublicApi.GetServerKey(sClientID)
    if not tAndroidData.tLendAndroid[sServerKey] then
        tALog.Print("_SetAndroidReturn  Error:没有借过机器人给游戏服%s",sServerKey)
        return
    end
    local tAndroidId = {}
    local tGrpAndroid = {}
    for _,tAnItem in pairs(arrAndroid) do
        tAndroidId[tAnItem.nUserId] = {nUserId=tAnItem.nUserId}
        AndroidMgr.PushAndroidToRestQueue(tAnItem)
        if tAndroidData.tLendAndroid[sServerKey][tAnItem.nGrpId] then
            tAndroidData.tLendAndroid[sServerKey][tAnItem.nGrpId][tAnItem.nUserId] = nil
            if not tGrpAndroid[tAnItem.nGrpId] then
                tGrpAndroid[tAnItem.nGrpId] = {}
            end
            table.insert(tGrpAndroid[tAnItem.nGrpId],tAnItem.nUserId)
        else
            tALog.Print("_SetAndroidReturn  Error:没有借过分组%d的机器人%d给游戏服%s",tAnItem.nGrpId,tAnItem.nUserId,sServerKey)
        end
    end
    tPublicRedis.DelLendAndroid(tSrvInfo.nServerId,tAndroidId)

    for nGrpId,arrUserId in pairs(tGrpAndroid) do
        local str = string.format("_SetAndroidReturn 机器人服回收分组%d的机器人:",nGrpId)
        for _,nUserId in pairs(arrUserId) do
            str= str..string.format("%d,",nUserId)
        end
        tALog.Print(str)
    end
end

--同步金币
--@params tAnItem:机器人信息
function AndroidMgr.ChangeGold(tAnItem)
    local tAndroid = AndroidMgr.GetAndroid(tAnItem.nGrpId,tAnItem.nUserId)
    if tAndroid then
        tAndroid.nGold = tAnItem.nGold
    end
end
 
--恢复本服从redis上获取的机器人，借出给游戏服的机器人(主要是给服务器挂掉重启用的)
function AndroidMgr.ReCoverRedisData()
    --获取各个机器人服从redis上获取的机器人id
    local tServerAndroidId = tPublicRedis.GetAllServerLoadAndroid()
    local tAndroidId = {}
    local nCnt = 0
    for nServerId,arrUserId in pairs(tServerAndroidId) do
        if nServerId == tSrvInfo.nServerId then
            --本服从redis上获取的机器人id
            for _,nUserId in pairs(arrUserId) do
                tAndroidId[nUserId] = nUserId
                nCnt = nCnt + 1
            end
            break
        end
    end

    tBase.LogT(string.format("_ReCoverRedisData 借出%d个 tAndroidId = ",nCnt),tAndroidId)

    local tS = tAndroidData.tRedisDataToStr
    --从redis上重新获取机器人数据
    for _, nUserId in pairs(tAndroidId) do
        local tItem =  tPublicRedis.GetRedisAndroidInfo(nUserId)
        if tItem then
            local tAnItem = {}
            for k, v in pairs(tItem) do
                if not tS[k] then
                    tAnItem[k] = tonumber(v)
                else
                    tAnItem[k] = v
                end
            end
            AndroidMgr.PushAndroid(tAnItem)
            tALog.Print("_ReCoverRedisData 从redis上读取机器人:nUserId_%d,sShopAcc_%s,nLanguageId_%d",tAnItem.nUserId,tAnItem.sShopAcc,tAnItem.nLanguageId)
        end
    end

    --从redis上重新获取借出给游戏服的机器人数据
    local tLendAndroidKey = tPublicRedis.GetLendAndroid(tSrvInfo.nServerId)
    for nGrpId,arrAndroid in pairs(tAndroidData.arrAllAndroid) do
        for nUserId,tAnItem in pairs(arrAndroid) do
            if tLendAndroidKey[nUserId] then
                --是借出的机器人,将其插入借出列表
                local tItem = {}
                for a, b in pairs(ProtoManager.PubProto_pb.AndroidItem()._setter) do 
                    tItem[a] = tAnItem[a]
                end
                local sServerKey = tLendAndroidKey[nUserId]
                if not tAndroidData.tLendAndroid[sServerKey] then
                    tAndroidData.tLendAndroid[sServerKey] = {}
                end
                if not tAndroidData.tLendAndroid[sServerKey][tItem.nGrpId] then
                    tAndroidData.tLendAndroid[sServerKey][tItem.nGrpId] = {}
                end
                tAndroidData.tLendAndroid[sServerKey][tItem.nGrpId][tItem.nUserId] = tItem
                tALog.Print("_ReCoverRedisData 借出的机器人:nUserId_%d,sServerKey_%s",tAnItem.nUserId,sServerKey)
            else
                AndroidMgr.PushAndroidToFreeQueue(tAnItem) --将机器人插入空闲队列末尾
                tALog.Print("_ReCoverRedisData 空闲的机器人:nUserId_%d",tAnItem.nUserId)
            end
        end
    end
end

--检查服务器状态
function AndroidMgr.CheckInvalid()
    AndroidMgr.DelAndroids()

    --本服务器状态
    local nServerState = tPublicRedis.GetServerState(tSrvInfo.nServerId)
    tAndroidData.nServerState = nServerState
    if nServerState~=1 then
        tALog.Print(string.format("_CheckInvalid   服务器状态为%d(0:未启用 1:正常 2:维护 3:测试 4:进程没开)",nServerState))
        AndroidMgr.ReturnAndroidToRedis()
    end
end

--后台请求删除机器人
function AndroidMgr.DelAndroidsReq(sReturnKey,Data,nLen)
    local s = tBase.GetRP().new(Data, nLen)
    local nMainID = s:GetModuleID() 
    local nSubID = s:GetMsgID()
    local tRead = ProtoManager.Backstage_pb.DelAndroidsReq()
    tRead:ParseFromString(s:GetString())
    local strUserId = tRead.strUserId or ""
    if strUserId=="" then
        tALog.Print("_DelAndroidsReq    Error:参数strUserId错误")
        return
    end
    local arrUserId = tPublicApi.Split(strUserId,",")
    if not arrUserId or type(arrUserId)~="table" then
        tALog.Print("_DelAndroidsReq    Error:参数strUserId分割失败,strUserId:%s",strUserId)
        return
    end
    local str = ""
    local nCnt = 0
    for _,sUserId in pairs(arrUserId) do
        local nUserId = tonumber(sUserId)
        if nUserId and type(nUserId)=="number" then
            tAndroidData.tWantDelAndroid[nUserId] = nUserId
            str = str..string.format("%d,",nUserId)
            nCnt = nCnt + 1
        else
            tALog.Print("_DelAndroidsReq    Error:UserId_%s错误",sUserId)
        end
    end
    if nCnt>0 then
        tALog.Print("_DelAndroidsReq    后台想要删除机器人nCnt_%d,机器人:%s",nCnt,str)
        AndroidMgr.DelAndroids()
    end
end

--删除后台想删除的机器人
function AndroidMgr.DelAndroids()
    local tAndroidId = {}
    for nGrpId,arrAndroid in pairs(tAndroidData.arrAllAndroid) do
        for nUserId,tAnItem in pairs(arrAndroid) do
            if tAndroidData.tWantDelAndroid[nUserId] then
                --是后台想删除的机器人
                if not AndroidMgr.IsLend(nGrpId,nUserId) then
                    --不是借出的机器人
                    local nAnCfgId = 1
                    if AndroidMgr.IsAppAndroid(tAnItem) then
                        nAnCfgId = 2
                    end

                    tAndroidData.arrAllAndroid[nGrpId][nUserId] = nil
                    if tAndroidData.arrFreeQueue[nGrpId] then
                        tAndroidData.arrFreeQueue[nGrpId][nUserId] = nil
                    end
                    if tAndroidData.arrRestQueue[nGrpId] then
                        tAndroidData.arrRestQueue[nGrpId][nUserId] = nil
                    end
                    tAndroidId[nUserId] = {nUserId=nUserId,nAnCfgId=nAnCfgId,nGrpId=nGrpId}
                    tAndroidData.tWantDelAndroid[nUserId] = nil
                    tALog.Print("[AndroidMgr.DelAndroids]删除机器人nUserId_%d",nUserId)
                end
            end
        end
    end

    tPublicRedis.DelAndroidKey(tAndroidId)
    tPublicRedis.DelLendAndroid(tSrvInfo.nServerId,tAndroidId)
    tPublicRedis.DelServerLoadAndroid(tSrvInfo.nServerId,tAndroidId)
    tPublicRedis.DelPilotFightRoadBead(tAndroidId)
end

--归还机器人到redis
function AndroidMgr.ReturnAndroidToRedis()
    --归还没有借出的机器人到redis
    local tAndroidId = {}
    local nCnt = 0
    local sArrUserId = ""
    for nGrpId,arrAndroid in pairs(tAndroidData.arrAllAndroid) do
        tAndroidData.arrFreeQueue[nGrpId] = {} --清空空闲队列
        tAndroidData.arrRestQueue[nGrpId] = {} --清空休息队列        
        for nUserId,tAnItem in pairs(arrAndroid) do
            if not AndroidMgr.IsLend(nGrpId,nUserId) then
                --不是借出的机器人
                tAndroidId[nUserId] = {nUserId=nUserId}
                tAndroidData.arrAllAndroid[nGrpId][nUserId] = nil
                nCnt = nCnt + 1
                sArrUserId = sArrUserId..string.format("%d,",nUserId)
            end
        end
    end
    tPublicRedis.DelLendAndroid(tSrvInfo.nServerId,tAndroidId)
    tPublicRedis.DelServerLoadAndroid(tSrvInfo.nServerId,tAndroidId)

    if nCnt>0 then
        tALog.Print(string.format("_ReturnAndroidToRedis    归还机器人到redis: %s",sArrUserId))
    end
end

--本服是否加载过机器人了
--@params nUserId：玩家id
--@return true 加载了 false 没加载
function AndroidMgr.HasLoadThisAndroid(nUserId)
    for nGrpId,tAndroid in pairs(tAndroidData.arrAllAndroid) do
        if tAndroid[nUserId] then
            return true
        end
    end
    return false
end

return AndroidMgr