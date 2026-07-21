local Define = {}

-------------------中心服start -----------------------------
------------------------------------------------------------
Define.sCenterName     = Typename.ClubCenter     --中心服名称
Define.sCenterLogDir   = "Center"         --日志目录名称
Define.nGameId         = 230                  -- 游戏类型

Define.tPower = {}
Define.tPower.Member = 1 --成员管理权限
Define.tPower.ClubGold = 2 --俱乐部币管理权限
Define.tPower.OpenTable = 3 --开桌管理权限

Define.nMinClubId = 1000000 --最小的俱乐部id(小于这个就是大厅)
Define.nMaxUserCnt     = 999                    --俱乐部人数上限
Define.nClubTax        = 950                    --服务费分成，千分比
Define.nInsuranceTax   = 1000                   --保险分成，千分比
Define.IsNeedAndroidInHall = false              --大厅桌是否加载机器人
Define.IsNeedAndroidInClub = false              --俱乐部桌是否加载机器人
Define.IsUseGold =  true --是否使用金币
Define.IsUserClubGold = true --是否使用俱乐部币
Define.IsOpenHall = true --是否开启大厅
Define.IsOpenClub = false --是否开启俱乐部
Define.IsCanCreateHallTable = false --玩家是否能创建大厅桌

--接入俱乐部的游戏  
--德州类型的游戏记得在  publicApi.IsTexasClassGame  函数里面也加上
Define.GameList = {
    nTexas = {nGameId=125,sGameCenter=typename.clubdezhoucenter},  --德州
    nTexasOmaha = {nGameId=126,sGameCenter=typename.clubdezhoucenter},  --德州奥马哈
    nTexasShortCard = {nGameId=175,sGameCenter=typename.TexasShortCardCenter},  --德州短牌
    nClubQiangZhuangNiu = {nGameId=178,sGameCenter=typename.ClubQiangZhuangNiu},  --德州短牌
}

Define.nAutoCloseTime = 30*60 --失联游戏服牌桌自动关闭的时间
Define.nLimitCnt = 30 --每次请求多少条俱乐部数据
Define.nReqClubDelay = 0.5 --请求俱乐部数据的时间间隔(秒)
Define.nDelectServIdTime = 15*60 --失联中心服删除的时间
Define.nCheckTableCnt = 20 --每次检查牌桌的数量

Define.nTime_LoadGroup = 1000*30 --1000*60*5  --定时加载分组

Define.nSplitClubCnt = 500 --俱乐部分批操作数量

-------------------从服start -----------------------------
------------------------------------------------------------

Define.sSlaveName = Typename.ClubSlave    --游戏名称
Define.sSlaveLogDir  =  "Slave"            --日志目录名称

-- 服务器定时器
Define.UpdataFile1 = 65102     -- 热更新
Define.UpdataFile2 = 65103     -- 热更新

-- //俱乐部成员身份 1:主席  10:管理员  20:普通成员  （中间留空一些数字，方便以后增加其它身份）
Define.nMaster = 1
Define.nAdmin = 10
Define.nMember = 20 

Define.Len_PassWord = 32 --库存密码长度

Define.MsgType = {
    KickOut = "KickOut", --踢出俱乐部
    Recycling = "Recycling",--回收俱乐部币
    DelApply = "DelApply",--玩家退还俱乐部币申请
    OpenTable = "OpenTable",--开桌
    CloseTable = "CloseTable",--关桌
}

--10000 + nGameId*100 + 1 游戏抽水分成
Define.SourceType = { --俱乐部币变化类型
    KickOut = 10000 + 230* 100 + 1, --被踢出俱乐部
    Quit = 10000 + 230* 100 + 2, --主动退出俱乐部
    AdminAddGold = 10000 + 230* 100 + 3, --管理员增加玩家俱乐部币
    AdminDelGold = 10000 + 230* 100 + 4, --管理员回收玩家俱乐部币
    ApplyAddGold = 10000 + 230* 100 + 5, --玩家申请俱乐部币
    ApplyDelGold = 10000 + 230* 100 + 6, --玩家主动退还俱乐部币
    ChangeName = 10000 + 230* 100 + 7, --修改昵称
    OpenTable = 10000 + 230* 100 + 8, --开桌
    LookCards = 10000 + 230* 100 + 9, --看公牌
    LookHands = 10000 + 230* 100 + 10, --看手牌
}

Define.nOpenCloseTableCnt = 0 --请求开桌次数统计

Define.nUserOpenHallCnt = 20 --一个玩家可以在大厅开多少张桌子
Define.nUserOpenClubCnt = 20 --一个玩家可以在一个俱乐部开多少张桌子
Define.nUserCreateClubCnt = 3 --一个玩家可以创建的俱乐部上限
Define.nUserApplyClubCnt = 5 --玩家加入俱乐部申请的数量上限
Define.nUserApplyClubGoldCnt = 5 --玩家俱乐部币增加退还申请的数量上限

Define.MaxAdminCnt = 30 --管理员最大数目

Define.nNameLen = 100 --base64加密后名字的长度
Define.nPersonalityLen = 1024 --base64加密后个性签名的长度

Define.nOverTime = 5 --5秒超时
Define.nSendCodeOverTime = 60 --玩家已发送短信状态失效时间

Define.tChangeName = {nItemId=1,nCount=10000} --改昵称消耗
Define.tOpenTableConsume = {nGoldType=1,nCount=0} --开桌消耗
Define.nFreeCnt = 1 --改昵称免费次数
Define.arrLevel = {{0,10},{1,100}} --等级经验配置

Define.DomainName = { --充值相关的域名的key
    Pay = "Stor_Pay", --充值
}

return Define