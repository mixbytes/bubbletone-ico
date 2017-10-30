'use strict';

// FIXME
const FundsAddress = '0x05bA0d658578b014b5fEBdAF6992bFd41bd44483'

// FIXME
const TokenAddress = '0x5c3a228510D246b78a3765C20221Cbf3082b44a4';

const PreSale = artifacts.require("./PreSale.sol");


module.exports = function(deployer, network) {
    deployer.deploy(PreSale, TokenAddress, FundsAddress);

    // owners have to manually perform
    // Token.setController(address of PreSale);
};

