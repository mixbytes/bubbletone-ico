'use strict';

// testrpc has to be run as testrpc -u 0 -u 1

import expectThrow from './helpers/expectThrow';
import skipException from './helpers/skipException';

const UMTToken = artifacts.require("./test_helpers/UMTTokenTestHelper.sol");

const zeroAddress = "0x0000000000000000000000000000000000000000";


contract('UMTToken', function(accounts) {
    const roles = {
        funds: accounts[0],
        owner3: accounts[0],
        owner1: accounts[1],
        owner2: accounts[2],
        sale1: accounts[2],
        sale2: accounts[3],
        investor1: accounts[2],
        investor2: accounts[4],
        investor3: accounts[5],
        nobody: accounts[9]
    };

    // converts amount of UMT into UMT-wei
    function UMT(amount) {
        return web3.toWei(amount, 'finney');
    };

    async function deployToken() {
        const token = await UMTToken.new(roles.cash, roles.sale1, {from: roles.owner1});

        return [token, roles.funds, roles.sale1];
    };

    describe('Token circulation tests', function() {
        it("Circulation enabled at start", async function() {
            const token = await deployToken();
            assert.equal(await token.m_isCirculating(), true);
        });

        it("Funds balance is half of tokens and it can transfer it", async function() {
            const [token, funds, sale] = await deployToken();

            assert.equal(await token.balanceOf(funds, {from: roles.nobody}), 500000000);

            await token.transfer(roles.nobody, 100000000, {from: funds});
            assert.equal(await token.balanceOf(funds, {from: roles.nobody}), 400000000);

            // nobody else has tokens
            assert.equal(await token.balanceOf(roles.owner1, {from: roles.nobody}), 0);
            assert.equal(await token.balanceOf(controller, {from: roles.nobody}), 0);
        });
    });

    describe('Token Burn tests', function(){
        it("Burn self tokens", async function() {
            const [token, funds, sale] = await deployToken();

            await token.burn(1000, {from: funds});

            let balance = await token.balanceOf(funds);

            assert(balance.eq(new web3.BigNumber(499000)));
        });

        it("Burn more then you have", async function() {
            const [token, funds, sale] = await deployToken();

            await expectThrow(token.burn(1000000, {from: roles.funds}));
        });

        it("Burn when you have nothing", async function() {
            const [token, funds, sale] = await deployToken();

            await expectThrow(token.burn(1, {from: roles.nobody}));
            await expectThrow(token.burn(1, {from: roles.owner1}));
        });
    });
});