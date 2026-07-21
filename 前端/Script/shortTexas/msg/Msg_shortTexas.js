let MSG = {
    ShortTexas: {
    },
    //本地相关
    NOTIFY: {

    }
}

let proto = require("proto_shortTexas");
let ShortTexasProto = proto.ClubDeZhouSC_Proto.create();
for (const key in ShortTexasProto) {
    let value = ShortTexasProto[key];
    if(typeof key == 'string' && typeof value == 'number'){
        MSG.ShortTexas[key] = "ShortTexas_" + key.toUpperCase();
    }
}
ShortTexasProto = null;

module.exports = MSG;