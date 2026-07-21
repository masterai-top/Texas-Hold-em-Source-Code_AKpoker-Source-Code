// Learn cc.Class:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/class.html
//  - [English] http://docs.cocos2d-x.org/creator/manual/en/scripting/class.html
// Learn Attribute:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/reference/attributes.html
//  - [English] http://docs.cocos2d-x.org/creator/manual/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - [Chinese] https://docs.cocos.com/creator/manual/zh/scripting/life-cycle-callbacks.html
//  - [English] https://www.cocos2d-x.org/docs/creator/manual/en/scripting/life-cycle-callbacks.html

let my = require("my");
let SubGameBase = require("SubGameBase")
class WrapperShortTexas extends SubGameBase {
    bundleName = "live-shortTexas";
    key = "shortTexas";
    constructor(options) {
        super(options);
    }
    _initLanguage(options){
        // super._initLanguage(options);
    }
    load(bundle){
        super.load(bundle);
    }
    start(options){
        // super.start(options);

        if (app.config.SKIN != "c"){
            super.start(options);
            return;
        }

        let self = this;

        let dependents = {
            "live-shortTexas": [
                {
                    bundleName: "live-Texas",
                    gameid: 125,
                }
            ]
        }

        let list = dependents[this.bundleName] || [];
        let count_loaded = 0;
        let callback = function (params) {
            if(count_loaded==list.length){
                app.texas._initLanguage({sGamePath:"Texas"})
                self.initGame(options);
                self.checkInOtherGame(self._gameid, self._roomid);
            }   
        }

        // if (app.config.IS_CLUB_ONLY){
        //     count_loaded = list.length;
        //     callback();
        //     return;
        // }

        let loadSubBundle = function (item) {
            console.log("loadSubBundle:",item);
            let key = item.bundleName;
            let temp = app.game.getGameItem(item.gameid) || {};

            let config = {
                md5: temp.sMD5FilePath,
                langs: temp.langs || {},
            };
            if(!app.config.ENABLE_SERVER_VERSION){
                config = {};
            }
            config.autoStart = false;
            config.sGamePath = "Texas",
            
            app.res.loadBundleWrapper(key, config, function onComplete(){  
                count_loaded++;        
                callback();
            })
        }

        if(list.length>0){
            for (let index = 0; index < list.length; index++) {
                const item = list[index];
                loadSubBundle(item);
            }
        }
        else{
            callback();
        }
    }

    hasRoomView(){
        if (app.config.SKIN == "b"){
            return true;
        }else{
            return false;
        }
    }

    //是否横屏游戏(子游戏重写)
    isLandscape(){
        return app.config.SKIN == 'a';
    }
}

let instance = new WrapperShortTexas(null);
my.wrapper.register(instance.bundleName, instance);