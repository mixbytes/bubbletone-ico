# bubbletone-ico

bubbletone.io ICO contracts

## Install dependencies

```bash
npm install
```

## Test

```bash
# run ganache-cli if it's not already running
./node_modules/.bin/ganache-cli --gasPrice 2000 -l 10000000 &>/tmp/ganache.log &

./node_modules/.bin/truffle test
```

## Deploy
1. Deploy PreICO
2. Deploy ICO
3. Deploy Token
4. PreICO.setToken
5. PreICO.setNextSale
6. PreICO.setStartTime
7. PreICO.setEndTime
8. ICO.setStartTime
9. ICO.setEndTime

