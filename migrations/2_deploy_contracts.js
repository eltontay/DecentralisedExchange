const OrderBook = artifacts.require('OrderBook');

module.exports = (deployer, network, accounts) => {
  deployer.deploy(OrderBook, 5);
};
