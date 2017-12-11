'use strict';

// testrpc has to be run as testrpc -u 0 -u 1 -u 2 -u 3 -u 4 -u 5

require('babel-register');

// FIXME: use import from solidity library. No Copy-paste. Fix problem with babel
import expectThrow from './helpers/expectThrow';

const PreICO = artifacts.require("./test_helpers/PreICOTestHelper.sol");
const ICO = artifacts.require("./test_helpers/ICOTestHelper.sol");
const UMTToken = artifacts.require("./test_helpers/UMTTokenTestHelper.sol");

const startTime = 1509840000;
const endTime = startTime + 12*24*60*60;

contract('SalesUnit', function(accounts) {
    const roles = {
        funds: accounts[0],
        pool: accounts[0],
        owner3: accounts[0],
        owner1: accounts[1],
        owner2: accounts[2],
        investor1: accounts[2],
        investor2: accounts[3],
        investor3: accounts[4],
        nobody: accounts[5]
    };

    /**
     * Init sale and tokens and optionally setup all parameters
     */
    async function instantiate(saleClass, initFull=true) {
        const crowdsale = await saleClass.new(
            [roles.owner1, roles.owner2, roles.owner3], roles.funds, roles.pool, {from: roles.nobody}
        );

        const nextSale = roles.owner2;

        const token = await UMTToken.new(roles.funds, crowdsale.address, {from: roles.owner1});

        if (initFull) {
            for (const _from of [roles.owner1, roles.owner2]) {
                await crowdsale.setStartTime(startTime, {from: _from});
                await crowdsale.setEndTime(endTime, {from: _from});
                await crowdsale.setToken(token.address, {from: _from});
                await crowdsale.setNextSale(crowdsale.address, {from: _from});
            }

            // Start sale
            await crowdsale.setTime(startTime+1, {from: roles.owner3});
        }

        return [crowdsale, token];
    }

    for (const [name, _saleClass] of [['PreICO', PreICO], ['ICO', ICO]]){
        describe('Control tests for ' + name, function() {
            it("Pause workflow", async function(){
                const [crowdsale, token] = await instantiate(_saleClass);

                // sale works
                await crowdsale.buy({
                    from: roles.investor1,
                    value: web3.toWei(20, 'finney'),
                    gasPrice: 0
                });

                await crowdsale.pause({from: roles.owner1});

                console.log(3);
                // sale not works
                await expectThrow(crowdsale.buy({
                    from: roles.investor1,
                    value: web3.toWei(20, 'finney'),
                    gasPrice: 0
                }));

                // Let's disable oraclize ETH price update before. Because now we don't have ether on contract address
                await crowdsale.turnOffETHPriceUpdate({from: roles.owner1});

                // Ok. let's unpause now
                for (const _from of [roles.owner1, roles.owner2]) {
                    await crowdsale.unpause({from: _from});
                }

                // sale works now
                await crowdsale.buy({
                    from: roles.investor1,
                    value: web3.toWei(20, 'finney'),
                    gasPrice: 0
                });
            });
        });

        describe('Buy tests for ' + name, function() {
            it("Can't invest less then minimum allowed payment", async function(){
                const [crowdsale, token] = await instantiate(_saleClass);

                // sale works
                await crowdsale.buy({
                    from: roles.investor1,
                    value: web3.toWei(20, 'finney'),
                    gasPrice: 0
                });

                // sale not works
                await expectThrow(crowdsale.buy({
                    from: roles.investor1,
                    value: web3.toWei(9, 'finney'),
                    gasPrice: 0
                }));
            });

            it("Test hard cap for" + name, async function(){
                const [crowdsale, token] = await instantiate(_saleClass);

                // sale works
                await crowdsale.buy({
                    from: roles.investor2,
                    value: web3.toWei(20, 'finney'),
                    gasPrice: 0
                });

                await crowdsale.buy({
                    from: roles.investor3,
                    value: web3.toWei(10, 'ether'),
                    gasPrice: 0
                });

                let UMTBalanceBefore = await token.balanceOf(roles.investor2, {from: roles.nobody});
                let balanceBefore = await web3.eth.getBalance(roles.investor2);
                // ok. Last investor comes and fails.

                // Everything after should fail
                await expectThrow(crowdsale.buy({
                    from: roles.investor2,
                    value: web3.toWei(20, 'finney'),
                    gasPrice: 0
                }));

                let balanceAfter = await web3.eth.getBalance(roles.investor2);
                let UMTBalanceAfter = await token.balanceOf(roles.investor2, {from: roles.nobody});

                assert.equal(balanceBefore - balanceAfter, 0);
                assert.equal(UMTBalanceAfter.sub(UMTBalanceBefore), 0);
            });

            it("Test buy too match and change returned", async function(){
                const [crowdsale, token] = await instantiate(_saleClass);

                let UMTBalanceBefore = await token.balanceOf(roles.investor3, {from: roles.nobody});
                let balanceBefore = await web3.eth.getBalance(roles.investor3);

                await crowdsale.buy({
                    from: roles.investor3,
                    value: web3.toWei(5, 'ether'),
                    gasPrice: 0
                });

                let balanceAfter = new web3.BigNumber(await web3.eth.getBalance(roles.investor3));
                let UMTBalanceAfter = new web3.BigNumber(await token.balanceOf(roles.investor3, {from: roles.nobody}));

                let change = new web3.BigNumber(web3.toWei(5, 'ether')).sub(balanceBefore.sub(balanceAfter));

                assert(change > 0);

                let tokensShouldBeAcquired = new web3.BigNumber(await crowdsale.calculateTokensPublic(
                    roles.investor3,
                    web3.toWei(5, 'ether')
                ));

                let tokensReallyAcquired = UMTBalanceAfter.sub(UMTBalanceBefore);

                assert(
                    tokensShouldBeAcquired.sub(tokensReallyAcquired).sub(
                        new web3.BigNumber(
                            await crowdsale.calculateTokensPublic(
                                roles.investor3,
                                change
                            )
                        )
                    ) < 1,
                    "should be proper change in tokens"
                );
            });
        });

        describe('Time tests for ' + name, function() {
            it("Set time tests. End less then start", async function(){
                const [crowdsale, token] = await instantiate(_saleClass, false);

                // sale works
                for (const _from of [roles.owner1, roles.owner2]) {
                    await crowdsale.setStartTime(endTime, {from: _from});
                }

                await crowdsale.setEndTime(startTime, {from: roles.owner1});

                await expectThrow(
                    crowdsale.setEndTime(startTime, {from: roles.owner2})
                );
            });
        });
    }
});


