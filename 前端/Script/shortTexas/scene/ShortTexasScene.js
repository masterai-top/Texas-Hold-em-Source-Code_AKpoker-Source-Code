// Learn cc.Class:
//  - https://docs.cocos.com/creator/manual/en/scripting/class.html
// Learn Attribute:
//  - https://docs.cocos.com/creator/manual/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - https://docs.cocos.com/creator/manual/en/scripting/life-cycle-callbacks.html

let TexasScene = require("TexasScene");

cc.Class({
    extends: TexasScene,

    properties: {

    },

    // LIFE-CYCLE CALLBACKS:

    onLoad () {
        this._super();
    },

    onDestroy(){
        this._super();
    },

    start () {
        this._super();
    }, 

    onEnable(){
        this._super();
    },

    onDisable(){
        this._super();
    },

    // update (dt) {},
});
