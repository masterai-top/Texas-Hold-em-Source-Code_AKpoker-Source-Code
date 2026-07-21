
-- 离线在线，登录退出
PublicLine = {}

-- 创建一个对象
function PublicLine:New()
    local t = {}
	setmetatable(t, self)
    self.__index = self
    t.tClientIDArr = {} -- 存放连接,用户ID map
    t.tUserIDArr = {} -- 存放用户ID， 连接 map （两个数据结构方便遍历,空间换时间）
    return  t

end 

-- 用户登录
function PublicLine:OnLogin(sClientID, nUserID)
    self.tClientIDArr[sClientID] = nUserID
    self.tUserIDArr[nUserID] = sClientID
end

-- 切换链接 (用户ID)
function PublicLine:ChangeConnect(sNewClientID, nUserID)
    for sClientID, nTempUserID in pairs(self.tClientIDArr) do
        if nTempUserID == nUserID then
            self.tClientIDArr[sClientID] = nil  -- 删除旧的连接
            self.tClientIDArr[sNewClientID] = nUserID -- 新的连接赋值

            self.tUserIDArr[nUserID] = sNewClientID

            return  true
        end
    end

    return false
end

-- 切换链接 (旧连接)
function PublicLine:ChangeConnect2(sNewClientID, sOldClienID)
    local nTempUserID = self.tClientIDArr[sOldClienID]
    if nTempUserID == nil then
        return false
    end
    self.tClientIDArr[sOldClienID] = nil  -- 删除旧的连接
    self.tClientIDArr[sNewClientID] = nTempUserID -- 新的连接赋值
    self.tUserIDArr[nTempUserID] = sNewClientID
    return true
end

-- 获取用户ID（通过连接）
function PublicLine:GetUserIDByClientID(sClientID)
    return self.tClientIDArr[sClientID]
end

-- 获取连接ID（通过用户）
function PublicLine:GetClientIDByUserID(nUserID)
    return self.tUserIDArr[nUserID]
end

-- 用户退出登录
function PublicLine:OnLogout(sClientID)
    local nTempUserID =  self.tClientIDArr[sClientID]
    self.tClientIDArr[sClientID] = nil
    self.tUserIDArr[nTempUserID] = nil
end

return  PublicLine