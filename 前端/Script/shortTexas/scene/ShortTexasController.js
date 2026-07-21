// Learn cc.Class:
//  - https://docs.cocos.com/creator/manual/en/scripting/class.html
// Learn Attribute:
//  - https://docs.cocos.com/creator/manual/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - https://docs.cocos.com/creator/manual/en/scripting/life-cycle-callbacks.html

let MsgManager = require("MsgManager");
let TexasController = require("TexasController");
let CMD = require("protocol_shortTexas");
let MSG = require("Msg_shortTexas");
const AppBase = require("../../../../../packages/package-frameworks/assets/Script/app/AppBase");

cc.Class({
    extends: TexasController,

    properties: {
        
    },

    // LIFE-CYCLE CALLBACKS:

    onLoad () {
        this._super();
        
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCLogOnRsp_CMD, this._onRepLogin, this);//登陆回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCConfigNotify_CMD, this._onRepRoomSetting, this);//房间设置成功通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCUserSitDownNotify_CMD, this._onRepUserSitDown, this);//有玩家坐下通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCUserStanpUpNotify_CMD, this._onRepUserStandUp, this);//有玩家从座位上站起通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCToStartNotify_CMD, this._onRepStartCountDown, this);//开局倒计时通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCStartNotify_CMD, this._onRepGameStart, this);//游戏开始通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCOperationNotify_CMD, this._onRepOperation, this);//操作权获得通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCOpNotify_CMD, this._onRepUserOperate, this);//有玩家操作通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCDealNotify_CMD, this._onRepDealCard, this);//公共牌新增通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCSettleNotify_CMD, this._onRepSettle, this);//结算通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCShowCardNotify_CMD, this._onRepUserLightCard, this);//有玩家亮牌通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCPreOpRsp_CMD, this._onRepUserNoOperate, this);//预操作回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCTakeInRangeRsp_CMD, this._onRepBuyChipLimits, this);//筹码买入范围查看回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCTakeInRsp_CMD, this._onRepBuyChip, this);//筹码买入回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCCancelAutoNotify_CMD, this._onRepCancelAuto, this);//有玩家取消托管通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCFailNotify_CMD, this._onRepErrorTip, this);//异常提示通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCGoldNotify_CMD, this._onRepGoldNotify, this);//金币变化通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCBalanceNotify_CMD, this._onRepUserGoldNotify, this);//有玩家筹码余额发生变化通知 (主播更改配置后可能发生)
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCChatNotify_CMD, this._onRepMagicFace, this);//表情聊天通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCKickUserRsp_CMD, this._onRepKickOut, this);//踢人回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCPauseRsp_CMD, this._onRepPause, this);//暂停设置 返回
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCOverViewRsp_CMD, this._onRepProcess, this);//牌桌总览返回
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCTableStartNotify_CMD, this._onRepStartGame, this);//房主点击了"开始牌局" 通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCAutoNextNotify_CMD, this._onRepContinueGame, this);//房主点击了"开始游戏" 通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCInsurNotify_CMD, this._onRepEnterInsureState, this);//进入保险阶段通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCInsurDealNotify_CMD, this._onRepInsureFaPai, this);//保险后发牌通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCInsurBuyRsp_CMD, this._onRepInsureBuy, this);//保险购买回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCDelayRsp_CMD, this._onRepDelayed, this);//延时回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCDelayNotify_CMD, this._onRepUserDelayed, this);//有人延时成功通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCHeadInfoRsp_CMD, this._onRepUserInfo, this);//头像信息回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCTakeOutRangeRsp_CMD, this._onRepCarryChipLimits, this);//筹码带出范围查看回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCTakeOutRsp_CMD, this._onRepCarryChip, this);//筹码带出回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCCardOpenRsp_CMD, this._onRepLookCommonCards, this);//翻牌回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCRetainRsp_CMD, this._onRepOccupiedOrBackSeat, this);//'留座离桌'或'回到座位' 回复
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCRetainNotify_CMD, this._onRepOccupiedOrBackSeatNotify, this);//'留座离桌'或'回到座位' 生效通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCTableResetNotify_CMD, this._onRepReset, this);//桌子重置通知
        MsgManager.on(MSG.ShortTexas.ClubDeZhouSCBackToLobbyRsp_CMD, this._onBackToLobbyRsp, this);//返回大厅回复
        MsgManager.on(MSG.ShortTexas.SCElapsedStatusNotify_CMD, this._onElapsedStatusNotify, this);//桌子计时状态变化
        MsgManager.on(MSG.ShortTexas.SCElapWarnNotify_CMD, this._onElapWarnNotify, this);//桌子剩余时间
    },

    onDestroy() {
        this._super();
    },

    start () {
        this._super();
    },

    // update (dt) {},

    //游戏请求
    _onRepGameReq(data) {
        if (!data) return;

        if (App.getIsClubMttMatch()){
            //mtt比赛直接用德州的协议
            this._super(data);
            return;
        }

        let str = data.str;
        let value = data.value;
        let treaty = data.treaty;
        let nData = data.nData;

        cc.warn("-------------------------------------------------------------------------------------" + this._getGameName() + str + ":",nData);
        
        app.net.send(CMD.ShortTexas.value, treaty, nData);
    },

    //获得游戏名
    _getGameName() {
        return "短牌德州";
    },

});
