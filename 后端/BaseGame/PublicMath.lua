--[[
	游戏算法
]]
PublicMath = {

}

-- 创建牌的对象
function PublicMath:New()
	local t = {}
	setmetatable(t, self)
    self.__index = self
	t.BaseNumber = 0x10
	t.tCard = {
	0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1a,0x1b,0x1c,0x1d,	--方块
	0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2a,0x2b,0x2c,0x2d,	--梅花
	0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3a,0x3b,0x3c,0x3d,	--红桃
	0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4a,0x4b,0x4c,0x4d,   --黑桃
	-- A,   2,   3,   4,   5,   6,   7,   8,   9,   10,  J,   Q,    K
			}
	return t
end

-- 初始化牌
-- tCard 牌类型
-- nCount 几副牌
function PublicMath:InitGameCard(tCard,nCount)
	tCard = tCard or self.tCard
	local tempCard = {}
	for i = 1, nCount do
		for j = 1, #tCard do
			table.insert(tempCard, tCard[j])
		end
	end
	self.tCard = tempCard
end

-- 随机牌
-- return 牌堆
function PublicMath:RandCard()
	 local tRandCard = self:Random(self.tCard, #self.tCard)
	 return tRandCard
end

-- 随机从数组抽不重复的数
-- tNumber -- 数字数组[1,2,4]
-- number -- 抽的个数
function PublicMath:Random(tNumber,number)
	local  tList = {}
    if (number > #tNumber) then
        return tNumber;
    end

    local nLen = #tNumber;

    for i = 1, number do
        local nkey = math.random(nLen)
        local temp = tNumber[nkey]
        tNumber[nkey] = tNumber[nLen]
        tNumber[nLen] = temp;
        nLen = nLen - 1
    end

    for i = 1, number do
        tList[i] = tNumber[#tNumber - i + 1]
    end

    return tList
end

-- 查找数组索引
-- tNumberArr 数组
-- nVal -- 值
-- return  -1 找不到； 其它 索引值
function PublicMath:FindArrIndex(tNumberArr,nVal)
	for i = 1, #tNumberArr do
        if (tNumberArr[i] == nVal) then
            return i
        end
	end
	return -1
end


return PublicMath

