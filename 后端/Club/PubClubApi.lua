--俱乐部公用函数
local PubClubApi = {}

--获取现在到第二天零点的时间
function PubClubApi.GetNowToNextZeroTime()
    Base.Log("获取现在到第二天零点的时间差 %d秒",PublicApi.GetLeroLeadTime())
    return PublicApi.GetLeroLeadTime()
end

--获取俱乐部后台配置
function PubClubApi.GetClubWebConfig(nGroupId)
    local tConfig = RedisCahche.GetClubConfig(nGroupId)
	Base.Log("_GetClubWebConfig 获取俱乐部后台配置  nGroupId_%d tConfig_%s",nGroupId,Cjson.encode(tConfig))

    local tNewConfig = {}
    tNewConfig.nMaxUserCnt = tConfig.nMaxUserCnt or Define.nMaxUserCnt --俱乐部成员上限
	tNewConfig.nClubTax = tConfig.nClubTax or Define.nClubTax --俱乐部服务费分成(占抽水的多少，千分比，如95%,就填950)
	tNewConfig.nInsuranceTax = tConfig.nInsuranceTax or Define.nInsuranceTax --俱乐部保险分成(占抽水的多少，千分比，如95%,就填950)
    tNewConfig.nUserOpenHallCnt = tConfig.nUserOpenHallCnt or Define.nUserOpenHallCnt --一个玩家可以在大厅开多少张桌子
	tNewConfig.nUserOpenClubCnt = tConfig.nUserOpenClubCnt or Define.nUserOpenClubCnt --一个玩家可以在一个俱乐部开多少张桌子
    tNewConfig.nUserCreateClubCnt = tConfig.nUserCreateClubCnt or Define.nUserCreateClubCnt --一个玩家可以创建的俱乐部上限
    tNewConfig.nUserApplyClubCnt = tConfig.nUserApplyClubCnt or Define.nUserApplyClubCnt --玩家加入俱乐部申请的数量上限    
    tNewConfig.nUserApplyClubGoldCnt = tConfig.nUserApplyClubGoldCnt or Define.nUserApplyClubGoldCnt --玩家俱乐部币增加退还申请的数量上限
 

	--大厅桌是否加载机器人
	if tConfig.IsNeedAndroidInHall=="true" then
        tNewConfig.IsNeedAndroidInHall = true 
    elseif tConfig.IsNeedAndroidInHall=="false" then
        tNewConfig.IsNeedAndroidInHall = false
    else
        tNewConfig.IsNeedAndroidInHall = Define.IsNeedAndroidInHall
    end
	--俱乐部桌是否加载机器人
	if tConfig.IsNeedAndroidInClub=="true" then
        tNewConfig.IsNeedAndroidInClub = true 
    elseif tConfig.IsNeedAndroidInClub=="false" then
        tNewConfig.IsNeedAndroidInClub = false
    else
        tNewConfig.IsNeedAndroidInClub = Define.IsNeedAndroidInClub
    end
	--是否使用金币
	if tConfig.IsUseGold=="true" then
        tNewConfig.IsUseGold = true 
    elseif tConfig.IsUseGold=="false" then
        tNewConfig.IsUseGold = false
    else
        tNewConfig.IsUseGold = Define.IsUseGold
    end
	--是否使用俱乐部币
	if tConfig.IsUserClubGold=="true" then
        tNewConfig.IsUserClubGold = true 
    elseif tConfig.IsUserClubGold=="false" then
        tNewConfig.IsUserClubGold = false
    else
        tNewConfig.IsUserClubGold = Define.IsUserClubGold
    end
	--是否开启大厅
	if tConfig.IsOpenHall=="true" then
        tNewConfig.IsOpenHall = true 
    elseif tConfig.IsOpenHall=="false" then
        tNewConfig.IsOpenHall = false
    else
        tNewConfig.IsOpenHall = Define.IsOpenHall
    end
	--是否开启俱乐部
	if tConfig.IsOpenClub=="true" then
        tNewConfig.IsOpenClub = true 
    elseif tConfig.IsOpenClub=="false" then
        tNewConfig.IsOpenClub = false
    else
        tNewConfig.IsOpenClub = Define.IsOpenClub
    end
	--玩家是否能创建大厅桌
	if tConfig.IsCanCreateHallTable=="true" then
        tNewConfig.IsCanCreateHallTable = true 
    elseif tConfig.IsCanCreateHallTable=="false" then
        tNewConfig.IsCanCreateHallTable = false
    else
        tNewConfig.IsCanCreateHallTable = Define.IsCanCreateHallTable
    end

	--牌桌满人开关
    tNewConfig.IsManchu = false 
	if tConfig.IsManchu== "true" then
        tNewConfig.IsManchu = true 
        -- Base.Log("_GetClubWebConfig    牌桌满人开关 true  nGroupId_%d",nGroupId)
    end 
    
    tNewConfig.arrOpenGameId = {}                 --开放游戏id 
    if tConfig.arrOpenGameId then 
        local arrOpenGameId = Cjson.decode(tConfig.arrOpenGameId)
        for _, nGameId in ipairs(arrOpenGameId) do
            if nGameId then 
                table.insert(tNewConfig.arrOpenGameId,tonumber(nGameId))
            end 
        end  
    end 
    return tNewConfig
end


function PubClubApi.GetOpenGameIdConfig(nGroupId)
    local tConfig = RedisCahche.GetClubConfig(nGroupId)
    local arrOpenGameId = {}                 --开放游戏id 
    if tConfig.arrOpenGameId then 
        local arrGameId = Cjson.decode(tConfig.arrOpenGameId)
        for _, nGameId in ipairs(arrGameId) do
            if nGameId and nGameId > 0 then 
                table.insert(arrOpenGameId,tonumber(nGameId))
            end 
        end  
    end 
    return arrOpenGameId
end

--检查公共开桌参数
function PubClubApi.CheckOpenTable(tClub,tConfig)
    local nRlt = PubErrCode.OpenTable.Success
    --校验使用的货币类型
    if not tConfig.nGoldType or not (tConfig.nGoldType>=1 and tConfig.nGoldType<=3) then
        tClub:Print("_CheckOpenTable nGoldType Err")
        nRlt = PubErrCode.OpenTable.GoldTypeErr
        return nRlt
    end
    --大厅
    if tClub.nClubId < Define.nMinClubId then
        tClub:Print("_CheckOpenTable 大厅 nClubId:%d",tClub.nClubId)
        if tConfig.nGoldType ~= 1 then
            --大厅只开金币桌
            tClub:Print("_CheckOpenTable 大厅只开金币桌 nClubId:%d",tClub.nClubId)
            nRlt = PubErrCode.OpenTable.GoldTypeErr
            return nRlt
        end
    end
    --校验是否使用金币
    if tConfig.nGoldType == 1 and not tClub.IsUseGold then
        tClub:Print("_CheckOpenTable 使用金币开关状态:关闭")
        nRlt = PubErrCode.OpenTable.GoldSwitchClose
        return nRlt
    end
    --校验是否使用俱乐部币
    if tConfig.nGoldType == 2 and not tClub.IsUserClubGold then
        tClub:Print("_CheckOpenTable 使用俱乐部币开关状态:关闭")
        nRlt = PubErrCode.OpenTable.ClubGoldSwitchClose
        return nRlt
    end
    local sTableName = tConfig.sTableName
    if sTableName == nil then
        tClub:Print("_CheckOpenTable 牌桌名字为空")
        nRlt = PubErrCode.OpenTable.ParamsErr
        return nRlt
    elseif #sTableName > Define.nNameLen then
        tClub:Print("_CheckOpenTable 牌桌名字太长了")
        nRlt = PubErrCode.OpenTable.NameTooLong
        return nRlt
    end
    --牌桌时长不存在
    if tConfig.nKeepTime == nil then
        tClub:Print("_CheckOpenTable nKeepTime Err")
        nRlt = PubErrCode.OpenTable.NoKeepTime
        return nRlt
    end
    --检查是否有相同名字的牌桌了(永久牌桌的检查此处放开,放到其它地方检查。永久牌桌（nKeepTime=-1）在一个服中只能一个A01名字,其它每个服也可以有一个A01.)
    if PubClubApi.CheckSameTableName(tClub,sTableName) and tConfig.nKeepTime > 0 then
        tClub:Print("_CheckOpenTable 有相同名字的牌桌了")
        nRlt = PubErrCode.OpenTable.SameName
        return nRlt
    end
    if tConfig.nContinuedNum then
        if (tConfig.nContinuedNum < 0 or tConfig.nContinuedNum > 10) then
            tClub:Print("_CheckOpenTable  参数有误   nContinuedNum_%d   ",tConfig.nContinuedNum or -999)
            nRlt = PubErrCode.OpenTable.ParamsErr
            return nRlt
        end
    end

    return nRlt
end

--检查德州开桌参数
function PubClubApi.CheckTexasPubOpenTable(tConfig)
    local nRlt = PubErrCode.OpenTable.Success
    --参数校验
    if type(tConfig.nPreAnte) ~= "number" then
        Base.Log("_CheckTexasOpenTable 前注类型错误")
        nRlt = PubErrCode.OpenTable.PreAnteTypeErr
        return nRlt
    elseif tConfig.nPreAnte < 0 then
        Base.Log("_CheckTexasOpenTable 前注<0")
        nRlt = PubErrCode.OpenTable.PreAnteValueErr
        return nRlt
    end
    if type(tConfig.nTakeIn) ~= "number" then
        Base.Log("_CheckTexasOpenTable 默认带入类型错误")
        nRlt = PubErrCode.OpenTable.TakeInTypeErr
        return nRlt
    elseif tConfig.nTakeIn < tConfig.nPreAnte then
        Base.Log("_CheckTexasOpenTable 默认带入< 前注")
        nRlt = PubErrCode.OpenTable.TakeInValueErr
        return nRlt
    end
    if type(tConfig.nCapacity) ~= "number" then
        Base.Log("_CheckTexasOpenTable 人数类型错误")
        nRlt = PubErrCode.OpenTable.CapacityTypeErr
        return nRlt
    elseif not (tConfig.nCapacity >= 2 and tConfig.nCapacity <= 9) then
        Base.Log("_CheckTexasOpenTable 人数不在2~9范围内")
        nRlt = PubErrCode.OpenTable.CapacityValueErr
        return nRlt
    end
    if type(tConfig.tAutostart) ~= "table" or type(tConfig.tAutostart.isOpen) ~= "boolean" then
        Base.Log("_CheckTexasOpenTable 自动开始设置类型错误")
        nRlt = PubErrCode.OpenTable.AutostartTypeErr
        return nRlt
    elseif tConfig.tAutostart.isOpen then
        --开启自动开始设置
        if type(tConfig.tAutostart.nPlayerCnt) ~= "number" then
            Base.Log("_CheckTexasOpenTable 自动开始设置-自动开始的人数错误")
            nRlt = PubErrCode.OpenTable.AutostartTypeErr
            return nRlt
        elseif not (tConfig.tAutostart.nPlayerCnt >= 2 and tConfig.tAutostart.nPlayerCnt <= tConfig.nCapacity) then
            Base.Log("_CheckTexasOpenTable 自动开始设置-自动开始的人数2~%d人的范围内",tConfig.nCapacity)
            nRlt = PubErrCode.OpenTable.AutostartValueErr
            return nRlt
        end
    end

    if type(tConfig.nMinTabkeInBB) ~= "number" then
        Base.Log("_CheckTexasOpenTable 带入筹码倍数最小值类型错误")
        nRlt = PubErrCode.OpenTable.MinTakeInBBTypeErr
        return nRlt
    elseif tConfig.nMinTabkeInBB <= 0 then
        Base.Log("_CheckTexasOpenTable 带入筹码倍数最小值<=0")
        nRlt = PubErrCode.OpenTable.MinTakeInBBValueErr
        return nRlt
    end

    if type(tConfig.nMaxTabkeInBB) ~= "number" then
        Base.Log("_CheckTexasOpenTable 带入筹码倍数最大值类型错误")
        nRlt = PubErrCode.OpenTable.MaxTakeInBBTypeErr
        return nRlt
    elseif tConfig.nMaxTabkeInBB <= 0 then
        Base.Log("_CheckTexasOpenTable 带入筹码倍数最大值<=0")
        nRlt = PubErrCode.OpenTable.MaxTakeInBBValueErr
        return nRlt
    end

    if tConfig.nMinTabkeInBB > tConfig.nMaxTabkeInBB then
        Base.Log("_CheckTexasOpenTable 带入筹码倍数最小值>带入筹码倍数最大值")
        nRlt = PubErrCode.OpenTable.MinBBMoreThanMaxBB
        return nRlt
    end

    if type(tConfig.nPoolEntryRate) ~= "number" then
        Base.Log("_CheckTexasOpenTable 入池率类型错误")
        nRlt = PubErrCode.OpenTable.PoolEntryRateTypeErr
        return nRlt
    elseif not (tConfig.nPoolEntryRate >= 0 and tConfig.nPoolEntryRate <= 100) then
        Base.Log("_CheckTexasOpenTable 入池率不在0~100%范围内")
        nRlt = PubErrCode.OpenTable.PoolEntryRateValueErr
        return nRlt
    end

    if type(tConfig.isOnlyPlayByIOS) ~= "boolean" then
        Base.Log("_CheckTexasOpenTable 只能IOS设备玩类型错误")
        nRlt = PubErrCode.OpenTable.IOSTypeErr
        return nRlt
    end

    if type(tConfig.isForceBlind) ~= "boolean" then
        Base.Log("_CheckTexasOpenTable 强制盲注类型错误")
        nRlt = PubErrCode.OpenTable.ForceBlindTypeErr
        return nRlt
    end

    if type(tConfig.isGPSLimit) ~= "boolean" then
        Base.Log("_CheckTexasOpenTable GPS限制类型错误")
        nRlt = PubErrCode.OpenTable.GPSTypeErr
        return nRlt
    end

    if type(tConfig.isIPLimit) ~= "boolean" then
        Base.Log("_CheckTexasOpenTable IP限制类型错误")
        nRlt = PubErrCode.OpenTable.IPTypeErr
        return nRlt
    end

    if type(tConfig.isAOF) ~= "boolean" then
        Base.Log("_CheckTexasOpenTable 全下或弃牌类型错误")
        nRlt = PubErrCode.OpenTable.AOFTypeErr
        return nRlt
    end

    if type(tConfig.isDelayLook) ~= "boolean" then
        Base.Log("_CheckTexasOpenTable 延迟看牌类型错误")
        nRlt = PubErrCode.OpenTable.DelayLookTypeErr
        return nRlt
    end

    if type(tConfig.nInsureMode) ~= "number" then
        Base.Log("_CheckTexasOpenTable 保险模式类型错误")
        nRlt = PubErrCode.OpenTable.InsureModeTypeErr
        return nRlt
    elseif not (tConfig.nInsureMode >= 0 and tConfig.nInsureMode <= 2) then
        Base.Log("_CheckTexasOpenTable 保险模式不是0:无保险,1:传统保险,2:低水保险的任意一个")
        nRlt = PubErrCode.OpenTable.InsureModeValueErr
        return nRlt
    end

    if type(tConfig.tDrawWaterMode) ~= "table" or type(tConfig.tDrawWaterMode.nModeType) ~= "number" then
        Base.Log("_CheckTexasOpenTable 抽水模式类型错误")
        nRlt = PubErrCode.OpenTable.DWModeTypeErr
        return nRlt
    end
    if not (tConfig.tDrawWaterMode.nModeType >= 0 and tConfig.tDrawWaterMode.nModeType <= 3) then
        Base.Log("_CheckTexasOpenTable 抽水类型不是0:不收取,1:按奖池比例收取,2:固定收取的任意一个")
        nRlt = PubErrCode.OpenTable.DWModeValueErr
        return nRlt
    end
    if (tConfig.tDrawWaterMode.nModeType == 1 or tConfig.tDrawWaterMode.nModeType == 2) and type(tConfig.tDrawWaterMode.nComputeMode) ~= "number" then
        Base.Log("_CheckTexasOpenTable 抽取方式类型错误")
        nRlt = PubErrCode.OpenTable.ComputeModeValueErr
        return nRlt
    end
    if tConfig.tDrawWaterMode.nComputeMode and (not (tConfig.tDrawWaterMode.nComputeMode >= 1 and tConfig.tDrawWaterMode.nComputeMode <= 2)) then
        Base.Log("_CheckTexasOpenTable 抽取方式不是1:按净盈利,2:按底池的任意一个")
        nRlt = PubErrCode.OpenTable.ComputeModeValueErr
        return nRlt
    end
    if tConfig.tDrawWaterMode.nModeType == 1 then
        if type(tConfig.tDrawWaterMode.nTaxRate) ~= "number" then
            Base.Log("_CheckTexasOpenTable 抽水比例类型错误")
            nRlt = PubErrCode.OpenTable.TaxRateTypeErr
            return nRlt
        elseif not (tConfig.tDrawWaterMode.nTaxRate >= 0 and tConfig.tDrawWaterMode.nTaxRate <= 100) then
            Base.Log("_CheckTexasOpenTable 抽水比例不在0~100%范围内")
            nRlt = PubErrCode.OpenTable.TaxRateValueErr
            return nRlt
        end

        if type(tConfig.tDrawWaterMode.nTopLimitBB) ~= "number" then
            Base.Log("_CheckTexasOpenTable 封顶类型错误")
            nRlt = PubErrCode.OpenTable.TopLimitBBTypeErr
            return nRlt
        elseif tConfig.tDrawWaterMode.nTopLimitBB < 0 then
            Base.Log("_CheckTexasOpenTable 封顶<0")
            nRlt = PubErrCode.OpenTable.TopLimitBBValueErr
            return nRlt
        end

        if type(tConfig.tDrawWaterMode.isFreeBeforeFlop) ~= "boolean" then
            Base.Log("_CheckTexasOpenTable 翻牌前结束免服务费类型错误")
            nRlt = PubErrCode.OpenTable.FBFTypeErr
            return nRlt
        end

        if type(tConfig.tDrawWaterMode.isHalf) ~= "boolean" then
            Base.Log("_CheckTexasOpenTable 低于3人服务费5折类型错误")
            nRlt = PubErrCode.OpenTable.IsHalfTypeErr
            return nRlt
        end

        if type(tConfig.tDrawWaterMode.tFreeConfig) ~= "table" or type(tConfig.tDrawWaterMode.tFreeConfig.isOpen) ~= "boolean" then
            Base.Log("_CheckTexasOpenTable 盈利过低免服务费类型错误")
            nRlt = PubErrCode.OpenTable.LimitBBTypeErr
            return nRlt
        elseif tConfig.tDrawWaterMode.tFreeConfig.isOpen then
            if type(tConfig.tDrawWaterMode.tFreeConfig.nLimitBB) ~= "number" then
                Base.Log("_CheckTexasOpenTable 盈利过低数值类型错误")
                nRlt = PubErrCode.OpenTable.LimitBBTypeErr
                return nRlt
            elseif tConfig.tDrawWaterMode.tFreeConfig.nLimitBB < 0 then
                Base.Log("_CheckTexasOpenTable 盈利过低数值<0")
                nRlt = PubErrCode.OpenTable.LimitBBValueErr
                return nRlt
            end
        end
    elseif tConfig.tDrawWaterMode.nModeType == 2 then
        if type(tConfig.tDrawWaterMode.nCutoffValue) ~= "number" then
            Base.Log("_CheckTexasOpenTable 分界值类型错误")
            nRlt = PubErrCode.OpenTable.CutoffTypeErr
            return nRlt
        elseif tConfig.tDrawWaterMode.nCutoffValue < 0 then
            Base.Log("_CheckTexasOpenTable 分界值<0")
            nRlt = PubErrCode.OpenTable.CutoffValueErr
            return nRlt
        end

        if type(tConfig.tDrawWaterMode.nLessValue) ~= "number" then
            Base.Log("_CheckTexasOpenTable 当净盈利小于分界值固定收取抽水类型错误")
            nRlt = PubErrCode.OpenTable.LessTypeErr
            return nRlt
        elseif tConfig.tDrawWaterMode.nLessValue < 0 then
            Base.Log("_CheckTexasOpenTable 当净盈利小于分界值固定收取抽水<0")
            nRlt = PubErrCode.OpenTable.LessValueErr
            return nRlt
        end

        if type(tConfig.tDrawWaterMode.nGreaterValue) ~= "number" then
            Base.Log("_CheckTexasOpenTable 当净盈利大于等于分界值固定收取抽水类型错误")
            nRlt = PubErrCode.OpenTable.GreaterTypeErr
            return nRlt
        elseif tConfig.tDrawWaterMode.nGreaterValue < 0 then
            Base.Log("_CheckTexasOpenTable 当净盈利大于等于分界值固定收取抽水<0")
            nRlt = PubErrCode.OpenTable.GreaterValueErr
            return nRlt
        end
    end

    if tConfig.isTabkeOut ~= nil and type(tConfig.isTabkeOut) ~= "boolean" then
        Base.Log("_CheckTexasOpenTable 带出筹码类型错误")
        nRlt = PubErrCode.OpenTable.TakeOutTypeErr
        return nRlt
    end
    if tConfig.nTabkeOutOdd ~= nil then
        if type(tConfig.nTabkeOutOdd) ~= "number" then
            Base.Log("_CheckTexasOpenTable 撤码功能类型错误")
            nRlt = PubErrCode.OpenTable.WithdrawMultipleTypeErr
            return nRlt
        end
    end
    if tConfig.nLoseMaxAmount and type(tConfig.nLoseMaxAmount) ~= "number" then
        Base.Log("_CheckTexasOpenTable 输钱限制类型错误")
        nRlt = PubErrCode.OpenTable.LostLimitValueErr
        return nRlt
    end
    if tConfig.nTableCost then
        if type(tConfig.nTableCost) ~= "table" then
            Base.Log("_CheckTexasOpenTable 牌桌消耗类型错误")
            nRlt = PubErrCode.OpenTable.TableCostTypeErr
            return nRlt
        end
        if #tConfig.nTableCost ~= 3 then
            Base.Log("_CheckTexasOpenTable 牌桌消耗数值错误")
            nRlt = PubErrCode.OpenTable.TableCostValueErr
            return nRlt
        end
    end
    if tConfig.nPoolEntryRateHands and type(tConfig.nPoolEntryRateHands) ~= "number" then
        Base.Log("_CheckTexasOpenTable 入池率多少手不限制类型错误")
        nRlt = PubErrCode.OpenTable.NPoolEntryRateHandsTypeErr
        return nRlt
    end
    if tConfig.nPoolHands and type(tConfig.nPoolHands) ~= "number" then
        Base.Log("_CheckTexasOpenTable 手数限制数值错误")
        nRlt = PubErrCode.OpenTable.NPoolHandsValueErr
        return nRlt
    end
    if tConfig.nIsPerson and type(tConfig.nIsPerson) ~= "number" then
        Base.Log("_CheckTexasOpenTable 是否私人房间类型错误")
        nRlt = PubErrCode.OpenTable.NIsPersonTypeErr
        return nRlt
    end
    if tConfig.nIsShow and type(tConfig.nIsShow) ~= "number" then
        Base.Log("_CheckTexasOpenTable 是否显示房间数值错误")
        nRlt = PubErrCode.OpenTable.NIsShowValueErr
        return nRlt
    end
    if tConfig.sPassWord and type(tConfig.sPassWord) ~= "string" then
        Base.Log("_CheckTexasOpenTable 密码数值类型错误")
        nRlt = PubErrCode.OpenTable.SPassWordTypeErr
        return nRlt
    end
    if type(tConfig.isVideoFee) ~= "boolean" then
        Base.Log("_CheckTexasOpenTable 是否开启语聊收费类型错误")
        nRlt = PubErrCode.OpenTable.MinTakeInBBTypeErr
        return nRlt
    end
    if type(tConfig.nVideoFee) ~= "number" then
        Base.Log("_CheckTexasOpenTable 语聊收费价格类型错误")
        nRlt = PubErrCode.OpenTable.MinTakeInBBTypeErr
        return nRlt
    end
    return nRlt
end

--检查短牌特有参数
function PubClubApi.CheckTexasShortCardOpenTable(tConfig)
    local nRlt = PubErrCode.OpenTable.Success
    if tConfig.isDPreAnte ~= nil and type(tConfig.isDPreAnte) ~= "boolean" then
        Base.Log("CheckTexasShortCardOpenTable 庄家是否要下两倍前注类型错误")
        nRlt = PubErrCode.OpenTable.IsDPreAnteTypeErr
        return nRlt
    end
    if tConfig.isDPreAnte == true then
        if tConfig.nTakeIn < tConfig.nPreAnte then
            Base.Log("CheckTexasShortCardOpenTable 默认带入<大盲+2倍前注")
            nRlt = PubErrCode.OpenTable.TakeInValueErr
            return nRlt
        end
    end
    if tConfig.nPreAnte > 0 then
        if tConfig.nBigBlind and tConfig.nBigBlind > 0 then
            Base.Log("CheckTexasShortCardOpenTable 前注模式 nBigBlind > 0")
            nRlt = PubErrCode.OpenTable.PreAnteValueErr
            return nRlt
        end
        if tConfig.nSmallBlind and tConfig.nSmallBlind > 0 then
            Base.Log("CheckTexasShortCardOpenTable 前注模式 nSmallBlind > 0")
            nRlt = PubErrCode.OpenTable.PreAnteValueErr
            return nRlt
        end
    else
        if type(tConfig.nSmallBlind) ~= "number" then
            Base.Log("_CheckTexasOpenTable 小盲类型错误")
            nRlt = PubErrCode.OpenTable.SBTypeErr
            return nRlt
        elseif tConfig.nSmallBlind <= 0 then
            Base.Log("_CheckTexasOpenTable 1 小盲<=0")
            nRlt = PubErrCode.OpenTable.SBValueErr
            return nRlt
        end
        if type(tConfig.nBigBlind) ~= "number" then
            Base.Log("_CheckTexasOpenTable 大盲类型错误")
            nRlt = PubErrCode.OpenTable.BBTypeErr
            return nRlt
        elseif tConfig.nBigBlind <= 0 then
            Base.Log("_CheckTexasOpenTable 1 大盲<=0")
            nRlt = PubErrCode.OpenTable.BBValueErr
            return nRlt
        end
    end
    return nRlt
end

--检查德州开桌参数
function PubClubApi.CheckTexasOpenTable(tConfig)
    local nRlt = PubErrCode.OpenTable.Success
    --参数校验
    if type(tConfig.nSmallBlind) ~= "number" then
        Base.Log("_CheckTexasOpenTable 小盲类型错误")
        nRlt = PubErrCode.OpenTable.SBTypeErr
        return nRlt
    elseif tConfig.nSmallBlind <= 0 then
        Base.Log("_CheckTexasOpenTable 小盲<=0")
        nRlt = PubErrCode.OpenTable.SBValueErr
        return nRlt
    end

    if type(tConfig.nBigBlind) ~= "number" then
        Base.Log("_CheckTexasOpenTable 大盲类型错误")
        nRlt = PubErrCode.OpenTable.BBTypeErr
        return nRlt
    elseif tConfig.nBigBlind <= 0 then
        Base.Log("_CheckTexasOpenTable 大盲<=0")
        nRlt = PubErrCode.OpenTable.BBValueErr
        return nRlt
    end

    if 2 * tConfig.nSmallBlind > tConfig.nBigBlind then
        Base.Log("_CheckTexasOpenTable 2倍小盲>大盲")
        nRlt = PubErrCode.OpenTable.TwoSBMoreThanBB
        return nRlt
    end

    if tConfig.nTakeIn < tConfig.nBigBlind + tConfig.nPreAnte then
        Base.Log("_CheckTexasOpenTable 默认带入<大盲+前注")
        nRlt = PubErrCode.OpenTable.TakeInValueErr
        return nRlt
    end

    if tConfig.preAnteOdd and type(tConfig.preAnteOdd) ~= "number" then
        Base.Log("_CheckTexasOpenTable 庄家前注倍数类型错误")
        nRlt = PubErrCode.OpenTable.BBTypeErr
        return nRlt
    end

    return nRlt
end

--检查俱乐部抢庄牛开桌参数
function PubClubApi.CheckQZNiuOpenTable(tConfig)
    local nRlt = PubErrCode.OpenTable.Success
    --参数校验
    if type(tConfig.nCapacity)~="number" then
        Base.Log("_CheckQZNiuOpenTable 人数类型错误")
        nRlt = PubErrCode.OpenTable.CapacityTypeErr
        return nRlt
    elseif not (tConfig.nCapacity>=2 and tConfig.nCapacity<=9) then
        Base.Log("_CheckQZNiuOpenTable 人数不在2~5范围内")
        nRlt = PubErrCode.OpenTable.CapacityValueErr
        return nRlt
    end
    
    if type(tConfig.tAutostart)~="table" or type(tConfig.tAutostart.isOpen)~="boolean" then
        Base.Log("_CheckQZNiuOpenTable 自动开始设置类型错误")
        nRlt = PubErrCode.OpenTable.AutostartTypeErr
        return nRlt
    elseif tConfig.tAutostart.isOpen then
        --开启自动开始设置
        if type(tConfig.tAutostart.nPlayerCnt)~="number" then
            Base.Log("_CheckQZNiuOpenTable 自动开始设置-自动开始的人数错误")
            nRlt = PubErrCode.OpenTable.AutostartTypeErr
            return nRlt
        elseif not (tConfig.tAutostart.nPlayerCnt>=2 and tConfig.tAutostart.nPlayerCnt<=tConfig.nCapacity) then
            Base.Log("_CheckQZNiuOpenTable 自动开始设置-自动开始的人数2~%d人的范围内",tConfig.nCapacity)
            nRlt = PubErrCode.OpenTable.AutostartValueErr
            return nRlt
        end
    end

    if type(tConfig.nAnte)~="number" then
        Base.Log("_CheckQZNiuOpenTable 底分类型错误")
        nRlt = PubErrCode.OpenTable.BaseScoreTypeErr
        return nRlt
    elseif tConfig.nAnte<=0 then
        Base.Log("_CheckQZNiuOpenTable 带入底分最小值<0")
        nRlt = PubErrCode.OpenTable.BaseScoreValueErr
        return nRlt
    end

    if type(tConfig.nTax)~="number" then
        Base.Log("_CheckQZNiuOpenTable 抽水比例类型错误")
        nRlt = PubErrCode.OpenTable.TaxRateTypeErr
        return nRlt
    elseif not (tConfig.nTax>=0 and tConfig.nTax<=1000) then
        Base.Log("_CheckQZNiuOpenTable 抽水比例不在0~1000%范围内")
        nRlt = PubErrCode.OpenTable.TaxRateValueErr
        return nRlt
    end

    --[[ 抢庄牛牌型倍数tConfig.HuType = {[1]=1,[2]=2,[3]=3,[4]=4,[5]=5,[6]=8,}
    没牛-牛六       1倍
    牛七-牛九       2倍
    牛牛            3倍
    五花牛          4倍
    四炸            5倍
    五小牛          8倍 ]]
    if not tConfig.HuType or #tConfig.HuType ~= 6 then
        Base.Log("_CheckQZNiuOpenTable 牌型倍率设置错误")
        nRlt = PubErrCode.OpenTable.CardOddsTypeErr
        return nRlt
    else
        for k, v in pairs(tConfig.HuType) do
            if type(v)~="number" then
                Base.Log("_CheckQZNiuOpenTable 牌型倍率类型错误")
                nRlt = PubErrCode.OpenTable.CardOddsTypeErr
                return nRlt
            elseif v < 1 then
                Base.Log("_CheckQZNiuOpenTable 牌型倍率要大于等于1")
                nRlt = PubErrCode.OpenTable.CardOddsValueErr
                return nRlt
            end
        end 
    end
    return nRlt
end

--牌桌是否使用机器人
function PubClubApi.IsUseAndroid(tClub,nGoldType)
    if tClub.IsNeedAndroid then
		if nGoldType == 1 or nGoldType == 2 then
			return true
		end
	end
	return false
end

--检查是否有相同名字的牌桌
--@return true：有 false：无
function PubClubApi.CheckSameTableName(tClub,sTableName)
	for nIndex,tTable in pairs(tClub.arrTable) do
		if tTable.sTableName==sTableName then
			return true
		end
	end
	return false
end

--获取玩家可以创建的俱乐部上限
function PubClubApi.GetUserCreateMaxCnt(nGroupId)
    local tClubConfig = PubClubApi.GetClubWebConfig(nGroupId)
    local nUserCreateClubCnt = tClubConfig.nUserCreateClubCnt
    return nUserCreateClubCnt
end

--获取玩家可以开桌的数量上限
function PubClubApi.GetUserOpenMaxCnt(nGroupId, nClubId)
    local tClubConfig = PubClubApi.GetClubWebConfig(nGroupId)
    local nUserOpenCnt = 0
    if nClubId < Define.nMinClubId then
        nUserOpenCnt = tClubConfig.nUserOpenHallCnt
    else
        nUserOpenCnt = tClubConfig.nUserOpenClubCnt
    end
    return nUserOpenCnt
end

--获取玩家加入俱乐部申请的数量上限
function PubClubApi.GetUserApplyMaxCnt(nGroupId)
    local tClubConfig = PubClubApi.GetClubWebConfig(nGroupId)
    local nUserApplyClubCnt = tClubConfig.nUserApplyClubCnt
    return nUserApplyClubCnt
end

--获取玩家俱乐部币增加退还申请的数量上限
function PubClubApi.GetUserApplyGoldMaxCnt(nGroupId)
    local tClubConfig = PubClubApi.GetClubWebConfig(nGroupId)
    local nUserApplyClubGoldCnt = tClubConfig.nUserApplyClubGoldCnt
    return nUserApplyClubGoldCnt
end


return PubClubApi