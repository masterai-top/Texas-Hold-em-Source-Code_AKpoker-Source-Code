--机器人数据
local AndroidData = {
    arrFreeQueue = {}, --各分组各语言的空闲机器人的队列{[GrpId]={[nUserId]=tItem1,...},...}
    arrRestQueue = {}, --各分组各语言的休息机器人的队列{[GrpId]={[nUserId]=tItem2,...},...}
    arrAllAndroid = {}, --本服所有的机器人 {[GrpId]={[nUserId]=tAnItem,...},...}
    AnConfig = {},      --后台机器人配置 
    tCanUseRate = {},   --各分组空闲机器人比列 {[GrpId]=10,...}
    tLendAndroid = {},  --服务器借出的机器人 {[sServerKey]={[nGrpId]={[nUserId]=tAnItem,...},...},...}
    tServerKeyInexistence = {}, --服务器key失效的游戏服 {[ServerKey]=os.time,...}
    tRedisDataToStr = { --redis上的机器人数据字符串类型字段
        ["sAccounts"]=true, 
        ["sNickName"]=true, 
        ["sHeadUrl"]=true, 
        ["sInvite_Code"]=true,
        ["sLocation"]=true, 
        ["sOnlineT"]=true, 
        ["sShopAcc"]=true,
        -- ["nAnCfgId"]=true,
    },
    tWantDelAndroid = {}, --后台想删除的机器人 {[nUserId]=nUserId,...}
    nServerState = 1, --服务器状态(0:未启用 1:正常 2:维护 3:测试 4:进程没开)
}

return AndroidData