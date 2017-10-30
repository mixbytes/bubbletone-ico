'use strict';

// testrpc has to be run as testrpc -u 0 -u 1 -u 2 -u 3 -u 4 -u 5

//import expectThrow from './helpers/expectThrow';
//import {l, logEvents} from './helpers/debug';
//import {instantiateCrowdsale} from './helpers/storiqa';

const PreSale = artifacts.require("./test_helpers/PreSaleTestHelper.sol");
const Token = artifacts.require("./Token.sol");


contract('PreSale', function(accounts) {

    const roles = {
        cash: accounts[0],
        owner3: accounts[0],
        owner1: accounts[1],
        owner2: accounts[2],
        investor1: accounts[2],
        investor2: accounts[3],
        investor3: accounts[4],
        nobody: accounts[5]
    };

    async function deployTokenAndPreSale() {
        const token = await Token.new({from: roles.owner1});
        const preSale = await PreSale.new(token.address, roles.cash, {from: roles.owner1});

        return [preSale, token];
    }

//    async function instantiate() {
//        const token = await Token.new(roles.owner1, {from: roles.nobody});
//        const preSale = await PreSale.new(token.address, roles.cash, {from: roles.nobody});
//
//        preSale.transferOwnership(roles.owner1, {from: roles.nobody});
//
//        await token.setController(preSale.address, {from: roles.owner1});
//        await token.setController(preSale.address, {from: roles.owner2});
//
//        return [preSale, token, roles.cash];
//    }
//
//    async function assertBalances(preSale, token, cash, cashInitial, added) {
//        assert.equal(await web3.eth.getBalance(preSale.address), 0);
//        assert.equal(await web3.eth.getBalance(token.address), 0);
//        assert((await web3.eth.getBalance(cash)).sub(cashInitial).eq(added));
//    }
//
//    // converts amount of STQ into STQ-wei
    function STQ(amount) {
        // decimals is the same as in ether, so..
        return web3.toWei(amount, 'ether');
    }
//
//    async function checkNoTransfers(token) {
//
//        await expectThrow(token.transfer(roles.nobody, STQ(2.5), {from: roles.nobody}));
//        await expectThrow(token.transfer(roles.investor3, STQ(2.5), {from: roles.nobody}));
//        await expectThrow(token.transfer(roles.investor3, STQ(2.5), {from: roles.investor2}));
//    }
//
//
//    it("test instantiation", async function() {
//        const cashInitial = await web3.eth.getBalance(roles.cash);
//
//        const [preSale, token, cash] = await instantiate();
//
//        assert.equal(await token.m_controller(), preSale.address);
//
//        await assertBalances(preSale, token, cash, cashInitial, 0);
//    });

    it("Token can setController preSale", async function(){
        const [preSale, token] = await deployTokenAndPreSale();
        await token.setController(preSale.address, {from: roles.owner1});

        assert.equal(await token.m_controller(), preSale.address);
    });

    describe('Token controller tests', function() {
        it("If owner call amIOwner, return true", async function(){
            const [preSale, token] = await deployTokenAndPreSale();
            await assert.ok(await preSale.amIOwner({from: roles.owner1}))
        });
        it("If not owner call amIOwner, preSale raise error", async function(){
            const [preSale, token] = await deployTokenAndPreSale();
            try {
                await preSale.amIOwner({from: roles.owner2})
                assert.ok(false);
            } catch(error) {
                assert.ok(true);
            }
        });
    });

    describe('Token controller tests', function() {
        it("If owner call amIOwner, return true", async function(){
            const [preSale, token] = await deployTokenAndPreSale();
            await assert.ok(await preSale.amIOwner())
        });
        it("If not owner call amIOwner, preSale raise error", async function(){
            const [preSale, token] = await deployTokenAndPreSale();
            try {
                await preSale.amIOwner()
                assert.ok(false);
            } catch(error) {
                assert.ok(true);
            }
        });
    });

    describe('PreSale ownable tests', function() {
        describe('Positive', function() {

            it("If deploy preSale by owner1, preSale owner set to owner1", async function(){
                const [preSale, token] = await deployTokenAndPreSale();
                assert.equal(await preSale.owner(), roles.owner1);
            });

            it("If owner transfer ownable, new owner set", async function(){
                const [preSale, token] = await deployTokenAndPreSale();
                await preSale.transferOwnership(roles.owner2, {from: roles.owner1})
                assert.equal(await preSale.owner(), roles.owner2);
            });

            it("If owner transfer ownable to same owner, owner not changed", async function(){
                const [preSale, token] = await deployTokenAndPreSale();
                await preSale.transferOwnership(roles.owner1, {from: roles.owner1})
                assert.equal(await preSale.owner(), roles.owner1);
            });
        });

        describe('Negative', function() {
            it("If not owner transfer ownable, token raise error and controller not set", async function() {
                const [token, controller] = await deployTokenAndPreSale();
                try {
                    await preSale.transferOwnership(roles.owner3, {from: nobody})
                    assert.ok(false);
                } catch(error) {
                    assert.ok(true);
                }
            });
        });
    });

});
