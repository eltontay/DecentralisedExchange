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

  it('Place Bid', async () => {
    let value = 1;
    let amount = value * 0.95 * 1000000000000000000;

    let bidPlaced = await orderBook.placeBid(1, {
      from: person1,
      value: 1000000000000000000,
    });
    assert.equal(await orderBook.getBidValue(1, { from: person1 }), amount);
  });
});
