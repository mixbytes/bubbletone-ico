'use strict';

// testrpc has to be run as testrpc -u 0 -u 1

import expectThrow from './helpers/expectThrow';
import skipException from './helpers/skipException';

const UMTToken = artifacts.require("./test_helpers/UMTTokenTestHelper.sol");

const zeroAddress = "0x0000000000000000000000000000000000000000";


contract('UMTToken', function(accounts) {
    const roles = {
        cash: accounts[0],
        owner3: accounts[0],
        owner1: accounts[1],
        owner2: accounts[2],
        controller1: accounts[2],
        controller2: accounts[3],
        controller3: accounts[4],
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
        const token = await UMTToken.new(roles.cash, {from: roles.owner1});

        return token;
    };

    async function deployTokenWithController() {
        const token = await UMTToken.new(roles.cash, {from: roles.owner1});

        await token.addController(roles.controller1, {from: roles.owner1});

        return [token, roles.controller1];
    };

    describe('Token circulation tests', function() {
        it("Circulation enabled at start", async function() {
            const token = await deployToken();
            assert.equal(await token.m_isCirculating(), true);
        });

        it("Cash balance is half of tokens and it can transfer it", async function() {
            const [token, controller] = await deployTokenWithController();

            assert.equal(await token.balanceOf(roles.cash, {from: roles.nobody}), 500000);

            await token.transfer(roles.nobody, 100000, {from: roles.cash});
            assert.equal(await token.balanceOf(roles.cash, {from: roles.nobody}), 400000);

            // nobody else has tokens
            assert.equal(await token.balanceOf(roles.owner1, {from: roles.nobody}), 0);
            assert.equal(await token.balanceOf(controller, {from: roles.nobody}), 0);
        });
    });

    describe('Token Mint tests', function() {
        describe('Positive', function() {
            it("If mint from controller, token doesn't raise error", async function() {
                const [token, controller] = await deployTokenWithController();
                await token.mint(roles.investor1, 1000, {from: controller});

                let tokenBalance = await token.balanceOf(token.address, {from: roles.nobody});
                assert(tokenBalance.eq(499000));

                let investor1Balance = await token.balanceOf(roles.investor1, {from: roles.nobody});
                assert(investor1Balance.eq(1000));
            });

            it("If mint from controller, amount>0, balance _to increase on _amount", async function() {
                const [token, controller] = await deployTokenWithController();
                const startBalance = await token.balanceOf(roles.investor1, {from: controller});
                await token.mint(roles.investor1, 500, {from: controller});
                assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}) - startBalance, 500);
            });

            it("If mint from controller, amount>0, totalSupply is not increased", async function() {
                const [token, controller] = await deployTokenWithController();
                const startTotalSupply = await token.totalSupply();
                await token.mint(roles.investor1, 500, {from: controller});
                assert.equal(await token.totalSupply() - startTotalSupply, 0);
            });
            it("If mint from controller, amount=0, balance _to doesn't increase", async function() {
                const [token, controller] = await deployTokenWithController();
                const startBalance = await token.balanceOf(roles.investor1, {from: controller});
                await token.mint(roles.investor1, 0, {from: controller});
                assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}) - startBalance, 0);
            });
            it("If mint from controller, amount=0, totalSuply doesn't increase", async function() {
                const [token, controller] = await deployTokenWithController();
                const startTotalSupply = await token.totalSupply();
                await token.mint(roles.investor1, 0, {from: controller});
                assert.equal(await token.totalSupply() - startTotalSupply, 0);
            });
        });

        describe('Negative', function() {
            it("If mint from owner, token raise error", async function() {
                const [token, controller] = await deployTokenWithController();
                await expectThrow(token.mint(roles.investor1, 1, {from: roles.owner1}));
            });
            it("If mint from owner, _to balance not changed", async function() {
                const [token, controller] = await deployTokenWithController();
                const startBalance = await token.balanceOf(roles.investor1, {from: controller});
                await skipException(token.mint(roles.investor1, 1, {from: roles.owner1}));
                assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}) - startBalance, 0);
            });
            it("If mint from owner, totalSuply not changed", async function() {
                const [token, controller] = await deployTokenWithController();
                const startTotalSupply = await token.totalSupply();
                await skipException(token.mint(roles.investor1, 1, {from: roles.owner1}));
                assert.equal(await token.totalSupply() - startTotalSupply, 0);
            });

            it("If mint from nobody, token raise error", async function() {
                const [token, controller] = await deployTokenWithController();
                await expectThrow(token.mint(roles.investor1, 1, {from: roles.nobody}));
            });
            it("If mint from nobody, _to balance not changed", async function() {
                const [token, controller] = await deployTokenWithController();
                const startBalance = await token.balanceOf(roles.investor1, {from: controller});
                await skipException(token.mint(roles.investor1, 1, {from: roles.nobody}));
                assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}) - startBalance, 0);
            });
            it("If mint from nobody, totalSuply not changed", async function() {
                const [token, controller] = await deployTokenWithController();
                const startTotalSupply = await token.totalSupply();
                await skipException(token.mint(roles.investor1, 1, {from: roles.nobody}));
                assert.equal(await token.totalSupply() - startTotalSupply, 0);
            });
        });


    });


    describe('Token Burn tests', function(){
        it("Burn self tokens", async function() {
            const [token, controller] = await deployTokenWithController();

            await token.burn(1000, {from: roles.cash});

            let balance = await token.balanceOf(roles.cash);
            assert(balance.eq(new web3.BigNumber(499000)));
        });

        it("Burn more then you have", async function() {
            const [token, controller] = await deployTokenWithController();

            await expectThrow(token.burn(1000000, {from: roles.cash}));
        });

        it("Burn when you have nothing", async function() {
            const [token, controller] = await deployTokenWithController();
            await expectThrow(token.burn(1, {from: roles.nobody}));
            await expectThrow(token.burn(1, {from: controller}));
        });
    });
});
