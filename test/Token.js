'use strict';

// testrpc has to be run as testrpc -u 0 -u 1
const Token = artifacts.require("./Token.sol");

const name = 'Universal Mobile Token';
const symbol = 'UMT';
const decimals = 18;

const zeroAddress = "0x0000000000000000000000000000000000000000";


contract('Token', function(accounts) {

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

    // converts amount of UMT into UMT-wei
    function UMT(amount) {
        return web3.toWei(amount, 'ether');
    }

    async function deployToken() {
        const token = await Token.new({from: roles.owner1});
        return token;
    };

    async function deployTokenWithController() {
        const token = await Token.new({from: roles.owner1});

        await token.setController(roles.owner2, {from: roles.owner1});

        return [token, roles.owner2];
    };

    describe('Token ownable tests', function() {
        describe('Positive', function() {

            it("If owner transfer ownable, new owner set", async function(){
                const token = await deployToken();
                await token.transferOwnership(roles.owner3, {from: roles.owner1})
                assert.equal(await token.owner(), roles.owner3);
            });

            it("If owner transfer ownable to same owner, owner not changed", async function(){
                const token = await deployToken();
                await token.transferOwnership(roles.owner1, {from: roles.owner1})
                assert.equal(await token.owner(), roles.owner1);
            });
        });

        describe('Negative', function() {
            it("If not owner transfer ownable, token raise error and controller not set", async function() {
                const [token, controller] = await deployTokenWithController();
                try {
                    await token.transferOwnership(roles.owner3, {from: nobody})
                    assert.ok(false);
                } catch(error) {
                    assert.ok(true);
                }
            });

            it("If controller transfer ownable, token raise error and controller not set", async function() {
                const [token, controller] = await deployTokenWithController();
                try {
                    await token.transferOwnership(roles.owner3, {from: controller})
                    assert.ok(false);
                } catch(error) {
                    assert.ok(true);
                }
            });
        });
    });

    describe('Token controller tests', function() {
        describe('Positive', function() {

            it("If nobody setController, token controller is 0x0.....", async function(){
                const token = await deployToken();
                assert.equal(await token.m_controller(), zeroAddress);
            });

            it("If owner setController, controller set", async function(){
                const token = await deployToken();
                await token.setController(roles.owner2, {from: roles.owner1})
                assert.equal(await token.m_controller(), roles.owner2);
            });

            it("If owner Disable controller, setController is disabled forever", async function() {
                const [token, controller] = await deployTokenWithController();

                await token.detachControllerForever({from: roles.owner1});

                try {
                    await token.setController(roles.owner3, {from: roles.owner1});
                    assert.ok(false);
                } catch(error) {
                    assert.ok(true);
                }
            });

        });

        describe('Negative', function() {
            it("If not owner setController, token raise error and controller not set", async function(){
                const token = await deployToken();
                try {
                    await token.setController(roles.investor2, {from: roles.investor2})
                    assert.ok(false);
                } catch(error) {
                    assert.ok(true);
                }
                assert.equal(await token.m_controller(), zeroAddress);
            });

            it("If controller setController, token raise error and controller not set", async function(){
                const [token, controller] = await deployTokenWithController();
                try {
                    await token.setController(roles.investor2, {from: controller})
                    assert.ok(false);
                } catch(error) {
                    assert.ok(true);
                }
                console.log(roles.investor2)
                assert.equal(await token.m_controller(), controller);
            });

            it("If not owner disable controller, token raise error and controller not set", async function() {
                const [token, controller] = await deployTokenWithController();
                try {
                    await token.detachControllerForever({from: roles.nobody});
                    assert.ok(false);
                } catch(error) {
                    assert.ok(true);
                }
            });

            it("If controller disable controller, token raise error and controller not set", async function() {
                const [token, controller] = await deployTokenWithController();
                try {
                    await token.detachControllerForever({from: controller});
                    assert.ok(false);
                } catch(error) {
                    assert.ok(true);
                }
            });

        });
    })

    describe('Token information tests', function() {
        it("Token name is correct", async function() {
            const token = await deployToken();
            const tokenName = await token.name({from: roles.nobody})
            assert.equal(tokenName, name);
        });

        it("Token symbol is correct", async function() {
            const token = await deployToken();
            const tokenSymbol = await token.symbol({from: roles.nobody})
            assert.equal(tokenSymbol, symbol);
        });
    });

    // Mint tests
    describe('Minting tests', function() {
        describe('Positive', function() {
            it("Controller can mint 1 token", async function() {
                const [token, controller] = await deployTokenWithController();

                await token.mint(roles.investor1, UMT(1), {from: controller});
                assert.equal(
                    await token.balanceOf(roles.investor1, {from: roles.nobody}),
                    UMT(1)
                );
            });

            it("Controller can mint 0 token, but it doesn't increase balance", async function() {
                const [token, controller] = await deployTokenWithController();

                await token.mint(roles.investor1, UMT(0), {from: controller});
                assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}), UMT(0));
            });


        });

        describe('Negative', function() {
            it("Not controller can't mint", async function() {
                const [token, controller] = await deployTokenWithController();

                var result;

                try {
                    await token.mint(roles.investor1, UMT(1), {from: roles.nobody});
                    result = false;
                } catch(error) {
                    result = true;
                }

                assert.ok(result);
                assert.equal(
                    await token.balanceOf(roles.investor1, {from: roles.nobody}),
                    UMT(0)
                );
            });

            it("Controller can mint -1 token, but it doesn't increase balance", async function() {
                const [token, controller] = await deployTokenWithController();

                await token.mint(roles.investor1, UMT(-1), {from: controller});
                assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}), UMT(0));
            });
        });
    });

    describe('Token transfer tests', function() {
        describe('Positive', function(){
            it("Token can be transferred after start", async function() {
                const [token, controller] = await deployTokenWithController();
                await token.startCirculation({from: controller})
                await token.mint(roles.investor1, UMT(3), {from: controller});
                await token.transfer(roles.investor2, UMT(1), {from: roles.investor1});

                assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}), UMT(2));
                assert.equal(await token.balanceOf(roles.investor2, {from: roles.nobody}), UMT(1));
            });
        });

        describe('Negative', function(){
            it("Token can not be transferred at start", async function() {
                const [token, controller] = await deployTokenWithController();

                await token.mint(roles.investor1, UMT(1), {from: controller});

                var result;
                try {
                    await token.transfer(roles.investor2, UMT(1), {from: roles.investor1});
                    result = false;
                } catch(error) {
                    result = true;
                }

                assert.ok(result);
            });

        });
    });

    describe('Token circulation tests', function() {
        describe('Positive', function() {
            it("Circulation disable at start", async function() {
                const [token, controller] = await deployTokenWithController();
                assert.equal(await token.m_isSetControllerDisabled(), false)
            });
        });

        describe('Negative', function() {

        });
    });



    it("test ERC20 is supported", async function() {
        const [token, controller] = await deployTokenWithController();

        await token.name({from: roles.nobody});
        await token.symbol({from: roles.nobody});
        await token.decimals({from: roles.nobody});

        assert((await token.totalSupply({from: roles.nobody})).eq(UMT(22)));

        assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}), UMT(10));

        await token.transfer(roles.investor2, UMT(2), {from: roles.investor1});
        assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}), UMT(8));
        assert.equal(await token.balanceOf(roles.investor2, {from: roles.nobody}), UMT(14));

        await token.approve(roles.investor2, UMT(3), {from: roles.investor1});
        assert.equal(await token.allowance(roles.investor1, roles.investor2, {from: roles.nobody}), UMT(3));
        await token.transferFrom(roles.investor1, roles.investor3, UMT(2), {from: roles.investor2});
        assert.equal(await token.allowance(roles.investor1, roles.investor2, {from: roles.nobody}), UMT(1));
        assert.equal(await token.balanceOf(roles.investor1, {from: roles.nobody}), UMT(6));
        assert.equal(await token.balanceOf(roles.investor2, {from: roles.nobody}), UMT(14));
        assert.equal(await token.balanceOf(roles.investor3, {from: roles.nobody}), UMT(2));
    });



    it("Controller can burn valid number of tokens", async function() {
        const [token, controller] = await deployTokenWithController();

        await token.mint(roles.investor1, UMT(10), {from: controller});
        await token.burn(roles.investor1, UMT(3), {from: controller});

        assert.equal(
            await token.balanceOf(roles.investor1, {from: roles.nobody}),
            UMT(7)
        );
    });

    it("Controller can't burn invalid number of tokens", async function() {
        const [token, controller] = await deployTokenWithController();
        await token.mint(roles.investor1, UMT(10), {from: controller});

        let result = false;
        try {
            await token.burn(roles.investor1, UMT(11), {from: controller});
        } catch(error) {
            result = true;
        }

        assert.ok(result);
    });
});
