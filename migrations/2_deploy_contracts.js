'use strict';

// FIXME. Need valid addresses
const FundsAddress = '0x6a0e078ec85d3e786adc2c3473db350d2dccee98';
const PoolAddress = '0x03bA0d658578b014b5fEBdAF6992bFd41bd44483';

const _owners = [
    '0xdad209d09b0fec404Da4204672372771bad3D683',
    '0x0Eed5de3487aEC55bA585212DaEDF35104c27bAF',
    '0x06bA0d658578b014b5fEBdAF6992bFd41bd44483'
];


// FIXME
//const TokenAddress = '0x5c3a228510D246b78a3765C20221Cbf3082b44a4';

const PreICO = artifacts.require("./PreICO.sol");
const ICO = artifacts.require("./ICO.sol");
const Token = artifacts.require("./UMTToken.sol");


module.exports = function(deployer, network) {
    /**
     * Deploy preICO, Then token with PreICO address as param and then
     */
    deployer.deploy(PreICO, _owners, FundsAddress, PoolAddress).then(function () {
        // Token
        deployer.deploy(Token, FundsAddress, PreICO.address).then(function() {
            // ICO
            deployer.deploy(ICO, _owners, FundsAddress, PoolAddress);
        })
    });
};

