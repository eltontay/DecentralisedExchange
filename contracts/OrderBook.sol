// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
    Considerations : Order Book can be Huge and Expensive
    - initially went with a simple approach of sorting but failed due to gas price
    - have to go with doubly linked list to maintain a sorted list

    1. Users should be able to retrieve their orders
        - mapping of address -> bids & asks
        - ordered accordingly
    2. Users are able to post orders (lock required collateral, in sc)
    3. Anyone allowed to fetch ordered side of book
        - bid (top bid is the highest , descending)
        - ask (top ask is the lowest , ascending)

    Assumptions
    -   Users can place > 1 order , but this would mean each read call
        would be O(n). For simplicity sake, this function will not be
        optimised.
    -   Since tasks stated only ask for post and cancel orders, and not 
        complete orders, State.completed is not utilised.
    -   Since this is an on-chain decentralised exchange, I thought that
        having a commissionPercentage would be a nice touch.
    -   Locking collateral by sending ether to the contract.

*/

import "./Strings.sol";

contract OrderBook {

    // if State is pending, can allow for cancellation
    enum State { pending , completed }
    
    mapping (uint256 => uint256) bidValues;

    address payable _owner = payable(msg.sender);
    uint256 commission; // Going the extra mile - commmission 0%-100%

    struct order {
        address payable customer;
        uint256 value; // msg.value less commission
        uint256 timestamp; 
        State state;
        uint256 id;   // current id
        uint256 next; // pointing to the next order with higher value
        uint256 prev; // pointing to the prev order with lower value
    }

    mapping (uint256 => order) bidBook;
    uint256 public bidHead;
    uint256 public bidCount; // include all bid orders including soft delete
    mapping (uint256 => order) askBook;
    uint256 public askHead;
    uint256 public askCount; // include all ask orders including soft delete
 
    event orderCreated(address,uint256,uint256,State,uint256,uint256,uint256,bool);   
    event newHead(uint256);
    event newTail(uint256);
    event bidLink(uint256, uint256);
    event askLink(uint256, uint256);

    constructor (uint256 _commission) {
        commission = _commission;
        bidHead = 0;
        bidCount = 0;
        askHead = 0;
        askCount = 0;
    }    
/*
    Modifier Functions
*/

    modifier isPending(order memory _order) {
        require(_order.state == State.pending, "Order Pending");
        _;
    }

    modifier isAuthorised(order memory _order, address sender) {
        require(_order.customer == sender, "Not Authorised");
        _;
    }

/*
    Helper Functons
*/

    function createBid(address customer, uint256 value, uint256 timestamp) internal returns (order memory) {
        bidCount ++;
        order memory newBid = order(
            payable(customer),
            value,
            timestamp,
            State.pending,
            bidCount,
            0,
            0
        );
        bidBook[bidCount] = newBid;
        emit orderCreated(customer,value,timestamp,State.pending,bidCount,0,0,false);   
        return newBid;
    }

    function createAsk(address customer, uint256 value, uint256 timestamp) internal returns (order memory) {
        askCount ++;
        order memory newAsk = order(
            payable(customer),
            value,
            timestamp,
            State.pending,
            askCount,
            0,
            0
        );
        askBook[askCount] = newAsk;
        emit orderCreated(customer,value,timestamp,State.pending,askCount,0,0,false);   
        return newAsk;
    }

    function setBidHead(uint256 id) internal {
        bidHead = id;
        emit newHead(id);
    }

    function setAskHead(uint256 id) internal {
        askHead = id;
        emit newHead(id);
    }

    function linkBid(uint256 prevId, uint256 nextId) internal {
        bidBook[prevId].next = nextId;
        bidBook[nextId].prev = prevId;
        emit bidLink(prevId,nextId);
    }

    function askBid(uint256 prevId, uint256 nextId) internal {
        bidBook[prevId].next = nextId;
        bidBook[nextId].prev = prevId;
        emit askLink(prevId,nextId);
    }

    // insertion sort
    function sortAsk(order memory newOrder) internal {
        uint256 current;
        if (askHead == 0) {
            askHead = newOrder.id;
        }
        else if (askBook[askHead].value >= newOrder.value) {
            newOrder.next = askHead;
            askBook[newOrder.next].prev = newOrder.id;
            askHead = newOrder.id;
        }
        else {
            current = askHead;
            while (askBook[current].next != 0 && askBook[askBook[current].next].value < newOrder.value) {
                current = askBook[current].next;
            }
            newOrder.next = askBook[current].next;
            if (askBook[current].next != 0) {
                askBook[newOrder.next].prev = newOrder.id;
            }
            askBook[current].next = newOrder.id;
            newOrder.prev = current;
        }
    }

    function insertionSortAsk() internal {
        uint256 current = askHead;
        while (current != 0) {
            uint256 next = askBook[current].next;
            askBook[current].prev = askBook[current].next = 0;
            sortAsk(askBook[current]);
            current = next;
        }
    }

    function concatenate(string memory a,string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a,' ',b));
    } 

/*
    Callable Functions
*/



    function placeBid (uint256 price) public payable {
        require(price >= 0, "price value must be more than 0");
        require(msg.value >= price, "Not enough blance to place bid");
        // uint256 time = block.timestamp;
        // uint256 commissionedPrice = msg.value * (100-commission) / 100;
        // // order memory newBid = order(payable(msg.sender),commissionedPrice,time,State.pending);
        // // bidBook.push(newBid);
        // _owner.transfer(commissionedPrice);
        // emit bidPlaced(msg.sender,commissionedPrice,time,State.pending);
    }

    function cancelBid (uint256 bidId) public isPending(bidBook[bidId]) isAuthorised(bidBook[bidId], msg.sender) {
        // bidBook[bidId].customer.transfer(bidBook[bidId].value);
        // delete bidBook[bidId];
        // // emit bidCancelled(bidId);
    }

    function placeAsk (uint256 price) public payable {
        require(price >= 0, "price value must be more than 0");
        require(msg.value >= price, "Not enough blance to place ask");
        uint256 time = block.timestamp;
        uint256 commissionedPrice = msg.value * (100-commission) / 100;
        order memory newAsk = createAsk(msg.sender,commissionedPrice,time);
        sortAsk(newAsk);
    }

    function cancelAsk (uint256 askId) public isPending(askBook[askId]) isAuthorised(askBook[askId], msg.sender) {
        // askBook[askId].customer.transfer(askBook[askId].value);
        // delete askBook[askId];
        // // sortAsk(askBook);      
        // emit askCancelled(askId);
    }

/*
    Getter Functions
*/

    function fetchAsk() public view returns (string memory) {
        uint256 current = askHead;
        string memory output = "";
        while (current != 0) {
            uint256 next = askBook[current].next;
            string memory currString = Strings.toString(current);
            output = concatenate(output,currString);
            current = next;
        }
        return output;
    }

    function fetchAllBid() public returns (order[] memory) {
    }


    function fetchYourBidIds() public returns (uint256[] memory) {
    }

    function fetchYourAskIds() public returns (uint256[] memory) {
    }

    function getOrder(uint256 id) public view returns(address payable,uint256,uint256,State,uint256,uint256,uint256,bool) {
        // order memory currOrder = bidBook[id];
        // return (currOrder.customer,currOrder.value,currOrder.timestamp,currOrder.state,currOrder.id,currOrder.next,currOrder.prev,currOrder.delb);
    }

    function getBidAddress (uint256 id) public view returns(address payable) {
        return bidBook[id].customer;
    }

    function getAskAddress (uint256 id) public view returns(address payable) {
        return askBook[id].customer;
    }

    function getBidValue (uint256 id) public view returns(uint256) {
        return bidBook[id].value;
    }

    function getAskValue (uint256 id) public view returns(uint256) {
        return askBook[id].value;
    }

    function getBidState (uint256 id) public view returns(State) {
        return bidBook[id].state;
    }

    function getAskState (uint256 id) public view returns(State) {
        return askBook[id].state;
    }

}