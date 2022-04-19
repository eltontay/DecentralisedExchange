# DecentralisedExchange

## Order Book

- Has a bid and ask side of order book
- Allows anyone to fetch an ordered side of the book. For bids these should be ordered descendingly (top bid is the highest) and for asks this should be ascendingly (top ask is the lowest)
- Allows users to post orders to either side of the book. the contract should lock required collateral
- Allows users to cancel their orders

## Truffle Test Cases , using Ganache , in /test

```bash
truffle compile
truffle migrate
truffle test
```
