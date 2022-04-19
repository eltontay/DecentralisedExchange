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

    await orderBook.placeBid(1, {
      from: person1,
      value: valueWei,
    });
    assert.equal(await orderBook.getBidValue(1, { from: person1 }), amount);
  });

  it('Place Second Bid - 5 ETH', async () => {
    let value = 5;
    let valueWei = value * 1000000000000000000;
    let amount = valueWei * 0.95;

    await orderBook.placeBid(5, {
      from: person1,
      value: valueWei,
    });
    assert.equal(await orderBook.getBidValue(2, { from: person1 }), amount);
  });

  it('Place Third Bid - 4 ETH', async () => {
    let value = 4;
    let valueWei = value * 1000000000000000000;
    let amount = valueWei * 0.95;

    await orderBook.placeBid(4, {
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

  it('Place First Ask - 1 ETH', async () => {
    let value = 1;
    let valueWei = value * 1000000000000000000;
    let amount = valueWei * 0.95;

    await orderBook.placeAsk(1, {
      from: person2,
      value: valueWei,
    });
    assert.equal(await orderBook.getAskValue(1, { from: person1 }), amount);
  });

  it('Place Second Ask - 5 ETH', async () => {
    let value = 5;
    let valueWei = value * 1000000000000000000;
    let amount = valueWei * 0.95;

    await orderBook.placeAsk(5, {
      from: person2,
      value: valueWei,
    });
    assert.equal(await orderBook.getAskValue(2, { from: person1 }), amount);
  });

  it('Place Third Ask - 4 ETH', async () => {
    let value = 4;
    let valueWei = value * 1000000000000000000;
    let amount = valueWei * 0.95;

    await orderBook.placeAsk(4, {
      from: person2,
      value: valueWei,
    });
    assert.equal(await orderBook.getAskValue(3, { from: person1 }), amount);
  });

  it('Check Ask Order', async () => {
    let askOrder = await orderBook.fetchAsk({
      from: person2,
    });

    let correctOrder = ' 1 3 2';
    assert.equal(askOrder, correctOrder);
  });

  it('Cancel Bid #3 ', async () => {
    await orderBook.cancelBid(3, {
      from: person1,
    });

    let bidOrder = await orderBook.fetchBid({
      from: person1,
    });
    let correctOrder = ' 2 1';

    assert.equal(bidOrder, correctOrder);
  });

  it('Cancel Ask #3 ', async () => {
    await orderBook.cancelAsk(3, {
      from: person2,
    });

    let askOrder = await orderBook.fetchAsk({
      from: person2,
    });
    let correctOrder = ' 1 2';

    assert.equal(askOrder, correctOrder);
  });
});
