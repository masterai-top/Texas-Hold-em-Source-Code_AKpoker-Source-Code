let Protocol = {
    ShortTexas: {
        ["value"]: 232,
    },
};

let proto = require("proto_shortTexas");
let ShortTexasProto = proto.ClubDeZhouSC_Proto.create();
for (const key in ShortTexasProto) {
    let value = ShortTexasProto[key];
    if(typeof key == 'string' && typeof value == 'number'){
        Protocol.ShortTexas[key] = value;
    }
}
ShortTexasProto = null;

module.exports = Protocol;