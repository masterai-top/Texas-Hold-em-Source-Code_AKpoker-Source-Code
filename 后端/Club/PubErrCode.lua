--错误码定义
local PubErrCode = {}

--登录
PubErrCode.Login = {
    Success = 0,    --成功
    UserIdErr = 1,  --玩家id不正确
    NoClub = 2,     --没有找到俱乐部(大厅)
    GroupErr = 3,   --玩家分组与俱乐部分组不一致
    InOtherClub = 4,--在其它俱乐部中
    NoClubUser = 5, --不是该俱乐部成员
    IsMaintenance=6,--游戏服维护中
    UserInBlackList=7,--玩家id在登录黑名单中，禁止登录
    IPInBlackList=8,--IP在登录黑名单中，禁止登录
    GPSInBlackList=9,--GPS在登录黑名单中，禁止登录
    WaitDBReturn=10, --请求过于频繁，等待上一个请求结束
    InviteCodeError=12, --输入的邀请码出错
}

--切换俱乐部
PubErrCode.Swicth = {
    Success = 0,        --成功
    NotFindUser = 1,    --没有找到玩家
    LeaveFail = 2,      --离开俱乐部失败
    WaitDBReturn=3, --请求过于频繁，等待上一个请求结束
}

--创建俱乐部 
PubErrCode.CreateClub = {
    Success = 0,        --成功
    ParamsErr = 1,      --参数错误
    PassWordErr = 2,    --库存密码不符合要求
    ClubExits = 3,      --俱乐部已存在
    NameTooLong=4,      --名字超长
    HasSpecailwords=5,  --含有特殊字符
    HasSensitivewords=6,  --含有敏感词
    LimtMax = 7,        --创建俱乐部达到上限
    WaitDBReturn=8,     --请求过于频繁，等待上一个请求结束
    DBERR = 99,         --数据库操作失败
}

--申请加入俱乐部
PubErrCode.ApplyJoin = {
    Success = 0,        --成功
    ParamsErr = 1,      --参数错误
    NoClub = 2,         --没有找到俱乐部
    HadApply = 3,       --已申请
    CanNotApply = 4,    --俱乐部设置不能申请
    IsInClub = 5,       --已在俱乐部中
    GroupErr = 6,       --玩家与俱乐部不是同一个分组
    InBlackList = 7,    --在黑名单中
    LimtMax = 8,        --申请达到上限
    DBERR = 99,         --数据库操作失败
}

--修改俱乐部信息
PubErrCode.ChangeClubInfo = {
    Success = 0,        --成功
    NoPower = 1,        --没有权限
    ClubExits = 2,      --俱乐部名字已存在
    ParamsErr = 3,      --参数错误
    PassWordErr = 4,    --旧的库存密码不正确
    SameVal = 5,        --新旧值相同
    NoClub = 6,         --俱乐部不存在
    NameTooLong=7,      --名字超长
    HasSpecailwords=8,  --含有特殊字符
    HasSensitivewords=9,--含有敏感词
    WaitDBReturn=10,    --请求过于频繁，等待上一个请求结束
    DBERR = 99,         --数据库操作失败
}

--管理员操作
PubErrCode.AdminOprate = {
    Success = 0, --成功
    NoLogin = 1, --没有登录俱乐部
    NoClubUser = 2, --被操作的玩家不是俱乐部成员
    NoPower = 3, --权限不足
    ParamsErr = 4, --参数错误
    NoFinish = 5, --上一个操作未完成
    ClubGoldLess = 6, --俱乐部账户的俱乐部币不足
    InGame = 7, --被操作的玩家在游戏中,稍后为你处理
    PassWordErr = 8, --库存密码不正确
    NoClub = 9, --俱乐部不存在
    NotAdmin = 10, --不是管理员
    UserClubGoldLess = 11, --玩家俱乐部币不足
    ChangeUserClubGoldFail = 12, --修改俱乐部币失败
    TargetIsOtherAdmin = 13, --被操作者是其它管理员
    TargetIsMaser = 14, --被操作者是主席
    DBERR = 15, --数据库操作失败
    KickOutYourself = 16, --不能踢出自己
    WaitDBReturn=17,    --请求过于频繁，等待上一个请求结束
}

--个人俱乐部币增加退还
PubErrCode.ApplyGold = {
    Success = 0, --成功
    ParamsErr = 1, --参数错误
    NoClub = 2, --俱乐部不存在
    IsHall = 3, --不是俱乐部,是大厅
    UserClubGoldLess = 4, --玩家俱乐部币不足
    NoClubUser = 5, --不是俱乐部成员
    LimtMax = 6,        --申请达到上限
    NoCheckSPW=7,--没有进行安全密码校验
    CheckSPWErr=8,--安全密码校验失败
}

--黑名单管理操作
PubErrCode.BlackListOp = {
    Success = 0, --成功
    IsHall = 1, --不是俱乐部,是大厅
    ParamsErr = 2, --参数错误
    NoClub = 3, --俱乐部不存在
    NoPower = 4, --权限不足
    InBlackList = 5, --已在黑名单中
    NoClubUser = 6, --你不是俱乐部成员
    WaitDBReturn=7,    --请求过于频繁，等待上一个请求结束
}

--俱乐部玩家信息
PubErrCode.MemberInfo = {
    Success = 0, --成功
    IsHall = 1, --不是俱乐部,是大厅
    NoClubUser = 2, --玩家不存在
}

--俱乐部增加删除管理员
PubErrCode.AdminMgr = {
    Success = 0, --成功
    IsHall = 1, --不是俱乐部,是大厅
    ParamsErr = 2, --参数错误
    NoClub = 3, --俱乐部不存在
    NotMaster = 4, --不是主席
    NoClubUser = 5, --玩家不存在
    isAdmin = 6, --已是管理员
    isMaster = 7, --修改的玩家是主席
    LimtMax = 8, --管理员数目达到上限
    isNotAdmin = 9, --玩家不是管理员
    WaitDBReturn= 10,    --请求过于频繁，等待上一个请求结束
}

--修改管理员权限
PubErrCode.ChangeAdminPower = {
    Success = 0, --成功
    IsHall = 1, --不是俱乐部,是大厅
    ParamsErr = 2, --参数错误
    NoClub = 3, --俱乐部不存在
    NotMaster = 4, --不是主席
    NoClubUser = 5, --玩家不存在
    isMaster = 7, --修改的玩家是主席
    WaitDBReturn= 8,    --请求过于频繁，等待上一个请求结束
}

--管理员处理申请
PubErrCode.ApplyDeal = {
    Success = 0, --成功
    IsHall = 1, --大厅,不是俱乐部
    NoPower = 2, --权限不足
    NoClub = 3, --俱乐部不存在
    ParamsErr = 4, --参数错误
    IsDeal = 5, --已被处理
    ClubGoldLess = 6, --俱乐部的俱乐部币不足
    UserClubGoldLess = 7, --俱乐部的俱乐部币不足
    NotAdmin = 8, --操作者不是俱乐部成员
    NoApply = 9, --申请不存在
    NoClubUser = 10, --被操作的玩家不是俱乐部成员
    PassWordErr = 11, --库存密码不正确
    IsInDealing = 12, --正在被其它管理员处理
    ChangeUserClubGoldFail=13, --修改俱乐部币失败
    InGame = 14, --被操作的玩家在游戏中,稍后为你处理
    DBERR = 15, --数据库操作失败
    ClubIsFull=16, --俱乐部已满人
    WaitDBReturn= 17,    --请求过于频繁，等待上一个请求结束
}

--邀请用户
PubErrCode.InviteUser = {
    Success = 0, --成功
    IsHall = 1, --不是俱乐部,是大厅
    NoPower = 2, --权限不足
    NoUser = 3, --邀请玩家不存在
    HadInvite = 4, --已邀请
    IsInClub = 5, --已经是俱乐部成员
    NoClub = 6, --俱乐部不存在
    NoClubUser = 7, --你不是俱乐部成员
}

--开桌
PubErrCode.OpenTable = {
    Success = 0, --成功
    ParamsErr = 1, --参数错误
    NoClub = 2, --俱乐部不存在
    NoPower = 3, --权限不足
    NoServer = 4, --游戏服没有启动
    OpenFail = 5, --开桌失败
    NotAdmin = 6, --操作者不是俱乐部成员
    SameName = 7,--有相同名字的牌桌了
    LimtMax = 8, --开桌数目达到上限
    OverTime =9, --开桌超时
    isOpening=10, --上一次的开桌还没处理完，请稍后
    NameTooLong=11,--名字超长
    GoldSwitchClose=12,--后台没开金币桌开关
    ClubGoldSwitchClose=13,--后台没开俱乐部币桌开关
    GoldTypeErr=14,--货币类型不正确
    SBTypeErr=15,--小盲类型不正确
    SBValueErr=16,--小盲数值不正确
    BBTypeErr=17,--大盲类型不正确
    BBValueErr=18,--大盲数值不正确
    TwoSBMoreThanBB=19,--大盲<2倍小盲
    PreAnteTypeErr=20,--前注类型错误
    PreAnteValueErr=21,--前注数值不正确
    TakeInTypeErr=22,--默认带入类型错误
    TakeInValueErr=23,--默认带入数值不正确
    CapacityTypeErr=24,--人数类型错误
    CapacityValueErr=25,--人数不在2~9范围内
    AutostartTypeErr=26,--自动开始人数类型错误
    AutostartValueErr=27,--自动开始不在2~开桌人数范围内
    MinTakeInBBTypeErr=28,--带入筹码倍数最小值类型错误
    MinTakeInBBValueErr=29,--带入筹码倍数最小值数值不正确
    MaxTakeInBBTypeErr=30,--带入筹码倍数最大值类型错误
    MaxTakeInBBValueErr=31,--带入筹码倍数最大值数值不正确
    MinBBMoreThanMaxBB=32,--带入筹码倍数最小值>带入筹码倍数最大值
    PoolEntryRateTypeErr=33,--入池率类型错误
    PoolEntryRateValueErr=34,--入池率不在0~100%范围内
    IOSTypeErr=35,--只能IOS设备玩类型错误
    ForceBlindTypeErr=36,--强制盲注类型错误
    GPSTypeErr=37,--GPS限制类型错误
    IPTypeErr=38,--IP限制类型错误
    AOFTypeErr=39,--全下或弃牌类型错误
    DelayLookTypeErr=40,--延迟看牌类型错误
    InsureModeTypeErr=41,--保险模式类型错误
    InsureModeValueErr=42,--保险模式不是0:无保险,1:传统保险,2:低水保险的任意一个
    DWModeTypeErr=43,--抽水模式类型错误
    DWModeValueErr=44,--抽水类型不是0:不收取,1:按奖池比例收取,2:固定收取的任意一个
    ComputeModeValueErr=45,--抽取方式不是1:按净盈利,2:按底池的任意一个
    TaxRateTypeErr=46,--抽水比例类型错误
    TaxRateValueErr=47,--抽水比例不在0~100%范围内
    TopLimitBBTypeErr=48,--封顶类型错误
    TopLimitBBValueErr=49,--封顶<0
    FBFTypeErr=50,--翻牌前结束免服务费类型错误
    IsHalfTypeErr=51,--低于3人服务费5折类型错误
    LimitBBTypeErr=52,--盈利过低免服务费类型错误
    LimitBBValueErr=53,--盈利过低免服务费数值<0
    CutoffTypeErr=54,--分界值类型错误
    CutoffValueErr=55,--分界值<0
    LessTypeErr=56,--当净盈利小于分界值固定收取抽水类型错误
    LessValueErr=57,--当净盈利小于分界值固定收取抽水<0
    GreaterTypeErr=58,--当净盈利大于等于分界值固定收取抽水类型错误
    GreaterValueErr=59,--当净盈利大于等于分界值固定收取抽水<0
    GoldLess=60,--金币不足
    ComputeModeTypeErr=61,--抽取方式类型错误
    TakeOutTypeErr=62,--带出筹码类型错误
    IsDPreAnteTypeErr=63,--庄家是否要下两倍前注类型错误
    BaseScoreTypeErr=64,--底分类型错误
    BaseScoreValueErr=65,--底分<0
    CardOddsTypeErr=66,--牌型倍率类型错误
    CardOddsValueErr=67,--牌型倍率值 <1
    NoKeepTime=68,--牌桌时间不不存在
    WithdrawEnabledTypeErr=69,--撤码功能类型错误
    WithdrawMultipleTypeErr=70,--撤码阈值倍数类型错误
    WithdrawMultipleValueErr=71,--撤码阈值倍数<0
    WithdrawMaxAmountTypeErr=72,--玩家允许在牌桌上保留的筹码上限类型错误
    WithdrawMaxAmountValueErr=73,--玩家允许在牌桌上保留的筹码上限<0
    LostLimitValueErr=74,--输钱限制数值错误
    TableCostTypeErr=75,--牌桌消耗类型错误
    TableCostValueErr=76,--牌桌消耗数值错误
    NPoolEntryRateHandsTypeErr=77,--入池率多少手不限制类型错误
    NPoolHandsValueErr=78,--手数限制数值错误
    NIsPersonTypeErr=79,--是否私人房间类型错误
    NIsShowValueErr=80,--是否显示房间数值错误
    SPassWordTypeErr=81, --密码数值类型错误
}

--关桌
PubErrCode.CloseTable = {
    Success = 0, --成功
    ParamsErr = 1, --参数错误
    NoClub = 2, --俱乐部不存在
    NoPower = 3, --权限不足
    NoTable = 4, --牌桌不存在
    NoServer = 5, --游戏服没有启动
    NotYouTable = 6, --不是你开的桌子,不能关闭
    OverTime =7, --关桌超时
    isCloseing=8, --上一次的关桌还没处理完，请稍后
    isPlaying=9,  --关桌失败, 游戏已开始
}

--牌谱操作
PubErrCode.PaiPuOprate = {
    Success = 0, --成功
    NoPaiJu = 1, --牌局不存在
    ParamsErr = 2, --参数错误
    NotUserPaiju = 3, --不是你的牌局
    HadCollect = 4, --已收藏
    WaitDBReturn= 5,    --请求过于频繁，等待上一个请求结束
}

--处理个人通知
PubErrCode.UserNoticeOprate = {
    Success = 0, --成功
    ParamsErr = 1, --参数错误
    NotNeedOp = 2, --无需处理
    HadHandle = 3, --已处理
    NoClub = 4, --俱乐部不存在
    ClubIsFull = 5, --俱乐部已满人
    Invalid = 6, --已失效
    NotUserNotice=7, --不是你的通知
    NoNotice = 8, --没有这条通知
    InfoErr=9, --玩家通知的额外信息错误
    InClub=10,--已经是俱乐部成员
    WaitDBReturn= 11,--请求过于频繁，等待上一个请求结束
}

--撤回个人申请
PubErrCode.UserApplyOprate = {
    Success = 0, --成功
    NoApply = 1, --申请不存在
    NotYourApply = 2,--不是你的申请
    NotNeedDeal = 3, --已被处理或者已失效
    ParamsErr = 4, --参数错误
    WaitDBReturn= 5,--请求过于频繁，等待上一个请求结束
}

--获取玩家个人信息
PubErrCode.GetUserInfo = {
    Success = 0, --成功
    ParamsErr = 1, --参数错误
    NoUser = 2,--玩家不存在
}

--修改个人资料
PubErrCode.ChangeUserInfo = {
    Success = 0, --成功
    ParamsErr = 1, --参数错误
    BeUsed = 2, --被占用
    NotSuit=3, --不符合要求
    IsSame=4, --新旧值相同
    NameTooLong=5,--名字超长
    HasSpecailwords=6,  --含有特殊字符
    HasSensitivewords=7,--含有敏感词
    PersonalityTooLong=8,--个性签名超长
    GoldLess=9,--金币不足
    SafePassWardErr=10,--安全密码不符合要求
    NoCheckSPW=11,--没有进行安全密码校验
    CheckSPWErr=12,--安全密码校验失败 
    WaitDBReturn=13,--请求过于频繁，等待上一个请求结束
    PassWordErr=14,--密码错误
    CodeErr=15,--验证码错误
    EmailErr=16,--未绑定邮箱
    OldPassErr=17,--密码错误
    NoFreeChangeNameCnt=18,--免费修改名字次数已用完
}

--修改登录密码
PubErrCode.ChangePassWard = {
    Success = 0, --成功
    ParamsErr = 1, --参数错误
    OldPassWardErr = 2, --旧密码不对
    IsSame=3, --密码新旧值相同
    NotSuit=4, --密码格式不正确
    DBErr = 5, --数据库操作异常
    NoCheckSPW=6,--没有进行安全密码校验
    CheckSPWErr=7,--安全密码校验失败
    WaitDBReturn=8,--请求过于频繁，等待上一个请求结束
}

--获取回放数据
PubErrCode.Playback = {
    Success = 0, --成功
    NoPaiJu = 1, --牌局不存在
}

--发送验证码
PubErrCode.SendCode = {
    Success = 0, --成功
    PhoneErr = 1, --手机号错误
    OverTime = 2, --超时
    TooFrequently = 3, --发送过于频繁
}

--发送验证码
PubErrCode.CodeCheck = {
    Success = 0, --成功
    CodeErr = 1, --验证码错误
}

--购买商品
PubErrCode.BuyGoods = {
    Success = 0, --成功
    CreateOrderFail = 1, --订单创建失败
    OrderInfoLack= 2, --订单信息不完整
    WebErr= 3, --web返回结果异常
    ThirdOrderFail = 4, --第三方订单创建失败
}

--输入兑换码
PubErrCode.InputRedeemCode = {
    Success = 0, --成功
    NotSuit = 1, --兑换码格式不正确
    WaitDBReturn = 2, --请求过于频繁，等待上一个请求结束
}

return PubErrCode