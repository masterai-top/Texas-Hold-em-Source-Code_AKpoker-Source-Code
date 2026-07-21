let CMD = require('protocol_shortTexas');
let MSG = require('Msg_shortTexas');
let protobufPack = require("proto");
let baseResponse = require("response");
let Response = baseResponse.getResponse();

let MapGame = new Map;

Response.set(CMD.ShortTexas.value, MapGame);

//proto 协议返回处理
!function () {
    let Handle = function (protoKey, protoObject) {
        if (!protoObject) {
            QYLogs.error("protocol_shortTexas", "解析体不存在" + protoKey);
        }
        MapGame.set(CMD.ShortTexas[protoKey], function (buffer) {
            //空协议体，表示只接受通知，不需要解析
            //空buffer也不需要解析
            let msg = MSG.ShortTexas[protoKey];
            if (!buffer||!protoObject) {
                return { data: {}, msg: msg };
            }
            let data = protoObject.decode(buffer);
            return { data: data, msg: msg };
        })
    }

    //登陆回复
    Handle("ClubDeZhouSCLogOnRsp_CMD", protobufPack.ClubDeZhouSCLogOnRsp);
    //房间设置成功通知
    Handle("ClubDeZhouSCConfigNotify_CMD", protobufPack.ClubDeZhouSCConfigNotify);
    //有玩家坐下通知
    Handle("ClubDeZhouSCUserSitDownNotify_CMD", protobufPack.ClubDeZhouSCUserSitDownNotify);
    //有玩家从座位上站起通知
    Handle("ClubDeZhouSCUserStanpUpNotify_CMD", protobufPack.ClubDeZhouSCUserStanpUpNotify);
    //开局倒计时通知
    Handle("ClubDeZhouSCToStartNotify_CMD", protobufPack.ClubDeZhouSCToStartNotify);
    //游戏开始通知
    Handle("ClubDeZhouSCStartNotify_CMD", protobufPack.ClubDeZhouSCStartNotify);
    //操作权获得通知
    Handle("ClubDeZhouSCOperationNotify_CMD", protobufPack.ClubDeZhouSCOperationNotify);
    //有玩家操作通知
    Handle("ClubDeZhouSCOpNotify_CMD", protobufPack.ClubDeZhouSCOpNotify);
    //公共牌新增通知
    Handle("ClubDeZhouSCDealNotify_CMD", protobufPack.ClubDeZhouSCDealNotify);
    //结算通知
    Handle("ClubDeZhouSCSettleNotify_CMD", protobufPack.ClubDeZhouSCSettleNotify);
    //有玩家亮牌通知
    Handle("ClubDeZhouSCShowCardNotify_CMD", protobufPack.ClubDeZhouSCShowCardNotify);
    //预操作回复
    Handle("ClubDeZhouSCPreOpRsp_CMD", protobufPack.ClubDeZhouSCPreOpRsp);
    //最近牌局记录查询 返回
    Handle("ClubDeZhouSCRecordRsp_CMD", protobufPack.ClubDeZhouSCRecordRsp);
    //牌局记录详情查询 返回
    Handle("ClubDeZhouSCRecordDetailRsp_CMD", protobufPack.ClubDeZhouSCRecordDetailRsp);
    //筹码买入范围查看回复
    Handle("ClubDeZhouSCTakeInRangeRsp_CMD", protobufPack.ClubDeZhouSCTakeInRangeRsp);
    //筹码买入回复
    Handle("ClubDeZhouSCTakeInRsp_CMD", protobufPack.ClubDeZhouSCTakeInRsp);
    //有玩家取消托管通知
    Handle("ClubDeZhouSCCancelAutoNotify_CMD", protobufPack.ClubDeZhouSCCancelAutoNotify);
    //异常提示通知
    Handle("ClubDeZhouSCFailNotify_CMD", protobufPack.ClubDeZhouSCFailNotify);
    //金币变化通知
    Handle("ClubDeZhouSCGoldNotify_CMD", protobufPack.ClubDeZhouSCGoldNotify);
    //有玩家筹码余额发生变化通知 (主播更改配置后可能发生)
    Handle("ClubDeZhouSCBalanceNotify_CMD", protobufPack.ClubDeZhouSCBalanceNotify);
    //表情聊天通知
    Handle("ClubDeZhouSCChatNotify_CMD", protobufPack.ClubDeZhouSCChatNotify);
    //踢人回复
    Handle("ClubDeZhouSCKickUserRsp_CMD", protobufPack.ClubDeZhouSCKickUserRsp);
    //暂停设置 返回
    Handle("ClubDeZhouSCPauseRsp_CMD", protobufPack.ClubDeZhouSCPauseRsp);
    //牌桌总览返回
    Handle("ClubDeZhouSCOverViewRsp_CMD", protobufPack.ClubDeZhouSCOverViewRsp);
    //房主点击了"开始牌局" 通知
    Handle("ClubDeZhouSCTableStartNotify_CMD", protobufPack.ClubDeZhouSCTableStartNotify);
    //房主点击了"开始游戏" 通知
    Handle("ClubDeZhouSCAutoNextNotify_CMD", protobufPack.ClubDeZhouSCAutoNextNotify);
    //进入保险阶段
    Handle("ClubDeZhouSCInsurNotify_CMD", protobufPack.ClubDeZhouSCInsurNotify);
    //保险后发牌通知(同时表示最近保险阶段结束)
    Handle("ClubDeZhouSCInsurDealNotify_CMD", protobufPack.ClubDeZhouSCInsurDealNotify);
    //保险购买回复
    Handle("ClubDeZhouSCInsurBuyRsp_CMD", protobufPack.ClubDeZhouSCInsurBuyRsp);
    //延时回复
    Handle("ClubDeZhouSCDelayRsp_CMD", protobufPack.ClubDeZhouSCDelayRsp);
    //有人延时成功通知
    Handle("ClubDeZhouSCDelayNotify_CMD", protobufPack.ClubDeZhouSCDelayNotify);
    //头像信息回复
    Handle("ClubDeZhouSCHeadInfoRsp_CMD", protobufPack.ClubDeZhouSCHeadInfoRsp);
    //筹码带出范围查看回复
    Handle("ClubDeZhouSCTakeOutRangeRsp_CMD", protobufPack.ClubDeZhouSCTakeOutRangeRsp);
    //筹码带出回复
    Handle("ClubDeZhouSCTakeOutRsp_CMD", protobufPack.ClubDeZhouSCTakeOutRsp);
    //'留座离桌'或'回到座位' 回复
    Handle("ClubDeZhouSCRetainRsp_CMD", protobufPack.ClubDeZhouSCRetainRsp);
    //'留座离桌'或'回到座位' 生效通知
    Handle("ClubDeZhouSCRetainNotify_CMD", protobufPack.ClubDeZhouSCRetainNotify);
    //翻牌回复
    Handle("ClubDeZhouSCCardOpenRsp_CMD", protobufPack.ClubDeZhouSCCardOpenRsp);
    //桌子重置通知
    Handle("ClubDeZhouSCTableResetNotify_CMD", protobufPack.ClubDeZhouSCTableResetNotify);
    //返回大厅回复
    Handle("ClubDeZhouSCBackToLobbyRsp_CMD", protobufPack.ClubDeZhouSCBackToLobbyRsp);
    //桌子计时状态变化
    Handle("SCElapsedStatusNotify_CMD", protobufPack.SCElapsedStatusNotify);
    //桌子剩余时间
    Handle("SCElapWarnNotify_CMD", protobufPack.SCElapWarnNotify);
}();


module.exports = {
    map: Response,

    release: function() {
        delete Response[CMD.ShortTexas];
    },
};