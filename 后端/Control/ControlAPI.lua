
ControlAPI = {}

ControlAPI.m_lstInfo = {}

-- -- 排序辅助函数
-- function ControlAPI.PairsBySort(tb, func)
--     local a = {}
--     for n in pairs(tb) do a[#a + 1] = n end
--     table.sort(a, func)
--     local i = 0
--     return function()
--         i = i + 1
--         return a[i], tb[a[i]]
--     end
-- end

-- -- 排序辅助函数
-- function ControlAPI.sortFunc(a, b)
--     return ControlAPI.m_lstInfo[a] > ControlAPI.m_lstInfo[b]
-- end

-- -- 根据 val 从大到小排序，把相应的 key 排序输出，要先对 ControlAPI.m_lstInfo 赋值
-- function ControlAPI.SortKeyByVal()
--     local lstInfo_key = {}
--     local lstInfo_val = {}
--     for k,v in ControlAPI.PairsBySort(ControlAPI.m_lstInfo, ControlAPI.sortFunc) do
--         lstInfo_key[#lstInfo_key + 1] = k
--         lstInfo_val[#lstInfo_val + 1] = v
--     end

--     return lstInfo_key, lstInfo_val
-- end

-- -- 返回平均值
-- function ControlAPI.GetAvg(tData, dV)
--     table.insert(tData, dV)
--     local dAvg = Statist.Avg(tData)
--     table.remove(tData)
--     return dAvg
-- end

-- -- 返回和值
-- function ControlAPI.GetSum(tData, dV)
--     local dSum = Statist.Sum(tData) + dV
--     return dSum
-- end

-- -- 获取用户的redis控牌信息
-- function ControlLink.GetRedisControlUser(nShopID, nGameID, nRoomID, nUserID)
    
--     local sKey ="GameControl"
--     local sMember =string.format("%d_%d_%d",nGameID,nRoomID,nUserID)

--     local sVal = base.m_MyRedisData[1].redis:hget(sKey, sMember)

--     if sVal ~= nil then
--         return math.floor(tonumber(sVal))
--     end

--     return nil
-- end


-- -- 保存用户数据到redis

-- function ControlAPI.SaveUserData(nType, nShopId, nGameId, nLevelId, nUserId, dWinlose)

--     logger:info('SaveUserData nUserID:'..nUserId)

--     local sUserKey =string.format("ControlUser_%d_%d_%d", nShopId, nGameId, nLevelId)

--     local sVal = string.format('%d_%d_%f', nUserId, nType, dWinlose)
    
--     base.m_MyRedisData[3].redis:rpush(sUserKey, sVal)
-- end


-- 先将数据转换为有趋势的形式，再平均抽取nCount个元素出来
function ControlAPI.GetValToAvg(tSrcObj, nStart, nEnd, nCount)

    logger:info('GetValToAvg, nStart:'..nStart..', nEnd:'..nEnd..', nCount:'..nCount)

    assert(nCount <= #tSrcObj)

    -- 转换为有趋势形式
    local tSrcTmp = {}
    for i = nStart, nEnd, 1 do
        if #tSrcTmp == 0 then
            table.insert( tSrcTmp, tSrcObj[i])
        else
            table.insert( tSrcTmp, tSrcTmp[#tSrcTmp] + tSrcObj[i])
        end
    end


    local tRes = {}

    local nStep = publicApi.Double2Int((nEnd - nStart + 1) / nCount)
    local nIndex = 1
    for i = 1, #tSrcTmp, 1 do

        if i ==  nIndex and #tRes < nCount  then
            table.insert( tRes, tSrcTmp[i])
            nIndex = i + nStep
        end

        -- logger:info('nIndex :'..nIndex..', i:'..i)
    end

    logger:info('GetValToAvg Res:'..nCount..', :'..#tRes..', step:'..nStep)

    assert(#tRes == nCount)

    return tRes
end

return ControlAPI