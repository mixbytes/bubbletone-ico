'use strict';

// testrpc has to be run as testrpc -u 0 -u 1 -u 2 -u 3 -u 4 -u 5

require('babel-register');

// FIXME: use import from solidity library. No Copy-paste. Fix problem with babel
import expectThrow from './helpers/expectThrow';

const PreICO = artifacts.require("./test_helpers/PreICOTestHelper.sol");
const UMTToken = artifacts.require("./test_helpers/UMTTokenTestHelper.sol");

const startTime = 1509840000;
const endTime = startTime + 12*24*60*60;

contract('PreICO', function(accounts) {
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

    /**
     * Init sale and tokens and optionally setup all parameters
     */
    async function instantiate(initFull=true) {
        const crowdsale = await PreICO.new(
            [roles.owner1, roles.owner2, roles.owner3], roles.funds, {from: roles.nobody}
        );

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

    describe('Control tests', function() {
        it("Pause workflow", async function(){
            const [crowdsale, token] = await instantiate();

            // sale works
            await crowdsale.buy({
                from: roles.investor1,
                value: web3.toWei(20, 'finney'),
                gasPrice: 0
            });

            await crowdsale.pause({from: roles.owner1});

            // sale not works
            await expectThrow(crowdsale.buy({
                from: roles.investor1,
                value: web3.toWei(20, 'finney'),
                gasPrice: 0
            }));

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

        it("Can't invest less then minimum allowed payment", async function(){
            const [crowdsale, token] = await instantiate();

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
    });

});


