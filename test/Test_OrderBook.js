const _deploy_contracts = require('../migrations/2_deploy_contracts');
const truffleAssert = require('truffle-assertions');
const { expectEvent, balance } = require('@openzeppelin/test-helpers');
var assert = require('assert');

var OrderBook = artifacts.require('OrderBook');

contract('TestOrderBook', function (accounts) {
  let orderBook;
  const orderBookOwner = accounts[0];
  const person1 = accounts[1];
  const person2 = accounts[2];

  before(async () => {
    orderBook = await OrderBook.deployed();
  });

  it('Place First Bid - 1 ETH', async () => {
    let value = 1;
    let valueWei = value * 1000000000000000000;
    let amount = valueWei * 0.95;

    let bidPlaced = await orderBook.placeBid(1, {
      from: person1,
      value: valueWei,
    });
    assert.equal(await orderBook.getBidValue(1, { from: person1 }), amount);
  });

  it('Place Second Bid - 5 ETH', async () => {
    let value = 5;
    let valueWei = value * 1000000000000000000;
    let amount = valueWei * 0.95;

    let bidPlaced = await orderBook.placeBid(5, {
      from: person1,
      value: valueWei,
    });
    assert.equal(await orderBook.getBidValue(2, { from: person1 }), amount);
  });

  it('Place Third Bid - 4 ETH', async () => {
    let value = 4;
    let valueWei = value * 1000000000000000000;
    let amount = valueWei * 0.95;

    let bidPlaced = await orderBook.placeBid(4, {
      from: person1,
      value: valueWei,
    });
    assert.equal(await orderBook.getBidValue(3, { from: person1 }), amount);
  });

  it('Check Bid Order', async () => {
    let bidOrder = await orderBook.fetchBid({
      from: person1,
    });

    let correctOrder = ' 2 3 1';
    assert.equal(bidOrder, correctOrder);
  });
});
