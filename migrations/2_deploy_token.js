'use strict';

const Token = artifacts.require("./Token.sol");

module.exports = function(deployer, network) {
    deployer.deploy(Token);
};
