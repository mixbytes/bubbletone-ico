# bubbletone-ico

![](https://travis-ci.org/mixbytes/bubbletone-ico.svg?branch=master)

bubbletone.io ICO contracts

## Install dependencies

```bash
npm install
```

## Test
1. This contract collaborates with Oraclize (http://www.oraclize.it).
To use it with test private blockchains like testrpc install ethereum-bridge: https://github.com/oraclize/ethereum-bridge

2. Run private blockchain.
```bash
# run ganache-cli if it's not already running
./node_modules/.bin/ganache-cli --gasPrice 2000 -l 10000000 &>/tmp/ganache.log &
```

3. Run tests
```
./node_modules/.bin/truffle test
```

## Deploy into production

0. Check migrations/2_deploy_contracts.sol. Fix addresses

1. Run migrations
```
truffle migrate --network=mainnet
```

2. 2 of 3 owners should process next steps:
For PreICO:
- PreICO.setToken
- PreICO.setNextSale
- PreICO.setStartTime
- PreICO.setEndTime

3. Put some ether into you sale contracts And start update ETH price machine by calling:
```
PreICO.updateETHPriceInCents()
ICO.updateETHPriceInCents()
```
We recommend to start it a little bit before sale but not to early to safe ether.

For ICO (*Setup in only after PreICO is finished*):
- ICO.setToken
- ICO.setStartTime
- ICO.setEndTime

