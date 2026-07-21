
let CMD = require('protocol_shortTexas');
let protobufPack = require("proto");

let baseRequest = require("request");
let Request = baseRequest.getRequest();

let MapGame = new Map;

Request.set(CMD.ShortTexas.value, MapGame);

//proto 协议请求处理
!function () {
    let Handle = function (protoKey, protoObject) {
        MapGame.set(CMD.ShortTexas[protoKey], function (data) {
            let message = protoObject.create(data);
            let buffer = protoObject.encode(message).finish();

            return buffer;
        })
    }
    
    //登陆请求
    Handle("ClubDeZhouSCLogOnReq_CMD", protobufPack.ClubDeZhouSCLogOnReq);
    //房间设置请求
    Handle("ClubDeZhouSCCofingReq_CMD", protobufPack.ClubDeZhouSCCofingReq);
    //操作请求
    Handle("ClubDeZhouSCOpReq_CMD", protobufPack.ClubDeZhouSCOpReq);
    //返回大厅请求
    Handle("ClubDeZhouSCBackToLobbyReq_CMD", protobufPack.ClubDeZhouSCBackToLobbyReq);
    //预操作请求
    Handle("ClubDeZhouSCPreOpReq_CMD", protobufPack.ClubDeZhouSCPreOpReq);
    //站起请求
    Handle("ClubDeZhouSCStanpUpReq_CMD", protobufPack.ClubDeZhouSCStanpUpReq);
    //坐下请求
    Handle("ClubDeZhouSCSitDownReq_CMD", protobufPack.ClubDeZhouSCSitDownReq);
    //筹码买入范围查看请求
    Handle("ClubDeZhouSCTakeInRangeReq_CMD", protobufPack.ClubDeZhouSCTakeInRangeReq);
    //筹码买入请求
    Handle("ClubDeZhouSCTakeInReq_CMD", protobufPack.ClubDeZhouSCTakeInReq);
    //取消托管请求
    Handle("ClubDeZhouSCCancelAutoReq_CMD", protobufPack.ClubDeZhouSCCancelAutoReq);
    //最近牌局记录查询 请求
    Handle("ClubDeZhouSCRecordReq_CMD", protobufPack.ClubDeZhouSCRecordReq);
    //牌局记录详情查询 请求
    Handle("ClubDeZhouSCRecordDetailReq_CMD", protobufPack.ClubDeZhouSCRecordDetailReq);
    //表情聊天请求
    Handle("ClubDeZhouSCChatReq_CMD", protobufPack.ClubDeZhouSCChatReq);
    //Gm命令请求
    Handle("ClubDeZhouSCGmReq_CMD", protobufPack.ClubDeZhouSCGmReq);
    //踢人请求 (给主播踢人用)
    Handle("ClubDeZhouSCKickUserReq_CMD", protobufPack.ClubDeZhouSCKickUserReq);
    //牌桌总览请求
    Handle("ClubDeZhouSCOverViewReq_CMD", protobufPack.ClubDeZhouSCOverViewReq);
    //暂停设置 请求
    Handle("ClubDeZhouSCPauseReq_CMD", protobufPack.ClubDeZhouSCPauseReq);
    //"开始牌局"请求 (房主使用)
    Handle("ClubDeZhouSCTableStartReq_CMD", protobufPack.ClubDeZhouSCTableStartReq);
    //"开始游戏" 请求 (房主使用)
    Handle("ClubDeZhouSCAutoNextReq_CMD", protobufPack.ClubDeZhouSCAutoNextReq);
    //保险购买请求
    Handle("ClubDeZhouSCInsurBuyReq_CMD", protobufPack.ClubDeZhouSCInsurBuyReq);
    //延时请求
    Handle("ClubDeZhouSCDelayReq_CMD", protobufPack.ClubDeZhouSCDelayReq);
    //筹码带出范围查看请求
    Handle("ClubDeZhouSCTakeOutRangeReq_CMD", protobufPack.ClubDeZhouSCTakeOutRangeReq);
    //筹码带出请求
    Handle("ClubDeZhouSCTakeOutReq_CMD", protobufPack.ClubDeZhouSCTakeOutReq);
    //头像信息请求
    Handle("ClubDeZhouSCHeadInfoReq_CMD", protobufPack.ClubDeZhouSCHeadInfoReq);
    //'留座离桌'或'回到座位' 请求
    Handle("ClubDeZhouSCRetainReq_CMD", protobufPack.ClubDeZhouSCRetainReq);
    //翻牌请求
    Handle("ClubDeZhouSCCardOpenReq_CMD", protobufPack.ClubDeZhouSCCardOpenReq);
    
}();

module.exports = {
    map: Request,

    release: function() {
        delete Request[CMD.ShortTexas];
    }
};