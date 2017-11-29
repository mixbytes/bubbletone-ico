'use strict';

const Token = artifacts.require("./UMTToken.sol");

// FIXME. Need correct address
const FundsAddress = '0x5c3a228510D246b78a3765C20221Cbf3082b44a4';

module.exports = function(deployer, network) {
    deployer.deploy(Token, FundsAddress);
};
