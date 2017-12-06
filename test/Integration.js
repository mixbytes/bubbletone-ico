'use strict';

// testrpc has to be run as testrpc -u 0 -u 1 -u 2 -u 3 -u 4 -u 5

require('babel-register');


import expectThrow from './helpers/expectThrow';

const UMTToken = artifacts.require("./test_helpers/UMTTokenTestHelper.sol");
const PreICO = artifacts.require("./test_helpers/PreICOTestHelper.sol");
const ICO = artifacts.require("./test_helpers/ICOTestHelper.sol");

const preICOStartTime = 1509840000;
const preICOEndTime = preICOStartTime + 12*24*60*60;

const ICOStartTime = preICOEndTime + 60*60*24;
const ICOEndTime = ICOStartTime + 12*24*60*60;



contract('IntegrationTest', function(accounts) {
    const roles = {
        funds: accounts[0],
        owner3: accounts[0],
        owner1: accounts[1],
        owner2: accounts[2],
        investor1: accounts[2],
        investor2: accounts[3],
        investor3: accounts[4],
        nobody: accounts[5]
    };

    describe('Whole test', function() {
        /**
         * Scenario:
         * Creating token and sales with all the sequence of steps described in Readme
         * Starting preICO buying some tokens.
         * Finish preICO and start ICO.  No hard caps reached
         */
        it("Integration. No hard caps", async function(){
            //console.log('1');
            const preico = await PreICO.new(
                [roles.owner1, roles.owner2, roles.owner3], roles.funds, {from: roles.nobody}
            );
            //console.log('2');
            // Checking that buying tokens doesn't work
            await expectThrow(preico.buy({
                from: roles.investor1,
                value: web3.toWei(20, 'finney'),
                gasPrice: 0
            }));
            //console.log('3');
            // Owners setup start and end date of preICO
            for (const _from of [roles.owner1, roles.owner2]) {
                await preico.setStartTime(preICOStartTime, {from: _from});
                await preico.setEndTime(preICOEndTime, {from: _from});
            }
            //console.log('4');
            // Still buying doesn't work because we didn't set token and next sale
            await expectThrow(preico.buy({
                from: roles.investor1,
                value: web3.toWei(20, 'finney'),
                gasPrice: 0
            }));
            //console.log('5');
            // So, let's deploy ico contract and token
            const ico = await ICO.new(
                [roles.owner1, roles.owner2, roles.owner3], roles.funds, {from: roles.nobody}
            );
            //console.log('6');
            const token = await UMTToken.new(roles.funds, preico.address, {from: roles.owner1});
            //console.log('7');
            // Checking that balances of token are distributed between sale and funds specified by owner
            // and nobody else has tokens
            assert.equal(await token.balanceOf(roles.funds, {from: roles.nobody}), 500000000 * 1e18);
            assert.equal(await token.balanceOf(preico.address, {from: roles.nobody}), 500000000 * 1e18);
            assert.equal(await token.balanceOf(roles.owner1, {from: roles.nobody}), 0);
            assert.equal(await token.balanceOf(roles.investor3, {from: roles.nobody}), 0);
            //console.log('8');
            // Now let's get back to our preICO
            for (const _from of [roles.owner2, roles.owner3]) {
                 await preico.setToken(token.address, {from: _from});
                 await preico.setNextSale(ico.address, {from: _from});
            }
            //console.log('9');
            // Checking that still we can't buy anything. Not a time yet
            let balanceBefore = await web3.eth.getBalance(roles.investor1);
            await expectThrow(preico.buy({
                from: roles.investor1,
                value: web3.toWei(15, 'finney'),
                gasPrice: 0
            }));
            let balanceAfter = await web3.eth.getBalance(roles.investor1);
            //console.log('10');
            // Let's check that during our tries our investor didn't get and spend anything
            assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}), 0);
            //console.log('10.1');
            assert.equal(balanceBefore - balanceAfter, 0);
            //console.log('11');
            // Now, let's setup proper time and try to buy tokens
            await preico.setTime(preICOStartTime+1, {from: roles.owner3});
            //console.log('12');
            balanceBefore = await web3.eth.getBalance(roles.investor1);

            let saleTokensBefore = await token.balanceOf(preico.address, {from: roles.nobody});
            let fundsBalanceBefore = await web3.eth.getBalance(roles.funds);
            //console.log('13');
            await preico.buy({
                from: roles.investor1,
                value: web3.toWei(20, 'finney'),
                gasPrice: 0
            });

            //console.log('13');
            balanceAfter = await web3.eth.getBalance(roles.investor1);
            let tokensLeft = await token.balanceOf(preico.address, {from: roles.nobody});

            //console.log('14');

            // Checking that funds go properly and tokens transferred too

            let tokensDiff = new web3.BigNumber(saleTokensBefore).sub(new web3.BigNumber(tokensLeft));
            assert(tokensDiff > 0);

            //console.log('14', tokensDiff);

            assert(
                new web3.BigNumber(await token.balanceOf(roles.investor1, {from: roles.nobody})).eq(tokensDiff)
            );

            let spentMoney = balanceBefore - balanceAfter;
            assert.equal(spentMoney, web3.toWei(20, 'finney'));
            //console.log('15');
            let fundsBalanceAfter = await web3.eth.getBalance(roles.funds);
            assert.equal(fundsBalanceAfter - fundsBalanceBefore, spentMoney);
            //console.log('16');
            // Now let's finish preico
            await preico.setTime(preICOEndTime+1, {from: roles.owner3});
            //console.log('17');

            // First buy after finish changes state but doesn't change tokens balance
            let investorTokensBefore = await token.balanceOf(roles.investor1, {from: roles.nobody});
            preico.buy({
                from: roles.investor1,
                value: web3.toWei(20, 'finney'),
                gasPrice: 0
            });
            let investorTokensAfter = await token.balanceOf(roles.investor1, {from: roles.nobody});
            assert.equal(investorTokensBefore - investorTokensAfter, 0);

            // Now Check that buy is disabled for ico and buy for preico does nothing
            for (const _investor of [roles.investor1, roles.investor2]) {
                await expectThrow(preico.buy({
                    from: _investor,
                    value: web3.toWei(20, 'finney'),
                    gasPrice: 0
                }));
                await expectThrow(ico.buy({
                    from: _investor,
                    value: web3.toWei(20, 'finney'),
                    gasPrice: 0
                }));
            }
            //console.log('18');
            // Let's check that all tokens that were owned by preICO moved to ICO
            assert.equal(await token.balanceOf(preico.address, {from: roles.nobody}), 0);
            //console.log('18.1');
            let icoTokens = await token.balanceOf(ico.address);
            assert(icoTokens.eq(tokensLeft));
            //console.log('19');
            // Let's start ICO. But before prepare it
            for (const _from of [roles.owner2, roles.owner3]) {
                 await ico.setToken(token.address, {from: _from});
                 //console.log('19.1');
                 await ico.setStartTime(ICOStartTime, {from: _from});
                 //console.log('19.2');
                 await ico.setEndTime(ICOEndTime, {from: _from});
                 //console.log('19.3');
            }
            //console.log('20');
            await ico.setTime(ICOStartTime+1, {from: roles.owner1});
            //console.log('21');
            // Let's but some tokens. First try with too small amount of investment
            balanceBefore = await web3.eth.getBalance(roles.investor1);
            fundsBalanceBefore = await web3.eth.getBalance(roles.funds);
            await expectThrow(ico.buy({
                from: roles.investor1,
                value: web3.toWei(5, 'finney'),
                gasPrice: 0
            }));
            //console.log('22');
            // Now more money should work
            saleTokensBefore = await token.balanceOf(ico.address, {from: roles.nobody});
            investorTokensBefore = await token.balanceOf(roles.investor1, {from: roles.nobody});
            await ico.buy({
                from: roles.investor1,
                value: web3.toWei(100, 'finney'),
                gasPrice: 0
            });
            //console.log('23');
            balanceAfter = await web3.eth.getBalance(roles.investor1);
            //console.log('24');
            // Checking that funds go properly and tokens transferred too
            tokensLeft = await token.balanceOf(ico.address, {from: roles.nobody});


            tokensDiff = new web3.BigNumber(saleTokensBefore).sub(new web3.BigNumber(tokensLeft));
            assert(tokensDiff > 0);

            assert(
                new web3.BigNumber(await token.balanceOf(roles.investor1, {from: roles.nobody})).eq(
                    new web3.BigNumber(investorTokensBefore).plus(tokensDiff)
                )
            );

            spentMoney = balanceBefore - balanceAfter;
            assert.equal(spentMoney, web3.toWei(100, 'finney'));
            //console.log('25');
            // Finish ICO
            await ico.setTime(ICOEndTime+1, {from: roles.owner1});
            //console.log('26');
            // Last nothing changed buy to change state
            ico.buy({
                from: roles.investor2,
                value: web3.toWei(20, 'finney'),
                gasPrice: 0
            });
            // And others should fails
            await expectThrow(ico.buy({
                from: roles.investor2,
                value: web3.toWei(20, 'finney'),
                gasPrice: 0
            }));
            //console.log('27');
            // Check that it burn all it's tokens
            tokensLeft = await token.balanceOf(ico.address, {from: roles.nobody});
            assert.equal(tokensLeft, 0);
        });
    });

});

