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
    uint256 public bidCount;
    mapping (uint256 => order) askBook;
    uint256 public askHead;
    uint256 public askCount;
 
    event bidPlaced(address, uint256);
    event askPlaced(address, uint256);
    event bidCancelled(address, uint256);
    event askCancelled(address, uint256);

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
        require(_order.state == State.pending, "Order Not Pending");
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
        return newAsk;
    }

    function deleteAsk(uint256 id) internal {
        if (askHead == 0 || id == 0) {
            return;
        }
        if (askHead == id) {
            askHead = askBook[id].next;
        }
        if (askBook[id].next != 0) {
            askBook[askBook[id].next].prev = askBook[id].prev;
        }
        if (askBook[id].prev != 0) {
            askBook[askBook[id].prev].next = askBook[id].next;
        }
        askCount--;
        return;
    }

    function deleteBid(uint256 id) internal {
        if (bidHead == 0 || id == 0) {
            return;
        }
        if (bidHead == id) {
            bidHead = bidBook[id].next;
        }
        if (bidBook[id].next != 0) {
            bidBook[bidBook[id].next].prev = bidBook[id].prev;
        }
        if (bidBook[id].prev != 0) {
            bidBook[bidBook[id].prev].next = bidBook[id].next;
        }
        bidCount--;
        return;
    }

    // insertion sort
    function sortAsk(order memory newOrder) internal {
        uint256 current;
        if (askHead == 0) {
            askHead = newOrder.id;
        } else if (askBook[askHead].value >= newOrder.value) {
            askBook[newOrder.id].next = askHead;
            askBook[askBook[newOrder.id].next].prev = newOrder.id;
            askHead = newOrder.id;
        } else {
            current = askHead;
            while (askBook[current].next != 0 && askBook[askBook[current].next].value < newOrder.value) {
                current = askBook[current].next;
            }
            askBook[newOrder.id].next = askBook[current].next;
            if (askBook[current].next != 0) {
                askBook[askBook[newOrder.id].next].prev = newOrder.id;
            }
            askBook[current].next = newOrder.id;
            askBook[newOrder.id].prev = current;
        }
    }

    // insertion sort
    function sortBid(order memory newOrder) internal {
        uint256 current;
        if (bidHead == 0) {
            bidHead = newOrder.id;
        } else if (bidBook[bidHead].value <= newOrder.value) {
            bidBook[newOrder.id].next = bidHead;
            bidBook[bidBook[newOrder.id].next].prev = newOrder.id;
            bidHead = newOrder.id;
        } else {
            current = bidHead;
            while (bidBook[current].next != 0 && bidBook[bidBook[current].next].value > newOrder.value) {
                current = bidBook[current].next;
            }
            bidBook[newOrder.id].next = bidBook[current].next;
            if (bidBook[current].next != 0) {
                bidBook[bidBook[newOrder.id].next].prev = newOrder.id;
            }
            bidBook[current].next = newOrder.id;
            bidBook[newOrder.id].prev = current;
        }
    }

    function insertionSortAsk() internal {
        uint256 current = askHead;
        while (current != 0) {
            uint256 next = askBook[current].next;
            sortAsk(askBook[current]);
            current = next;
        }
    }

    function insertionSortBid() internal {
        uint256 current = bidHead;
        while (current != 0) {
            uint256 next = bidBook[current].next;
            sortBid(bidBook[current]);
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
        uint256 time = block.timestamp;
        uint256 commissionedPrice = msg.value * (100-commission) / 100;
        order memory newBid = createBid(msg.sender,commissionedPrice,time);
        sortBid(newBid);
        _owner.transfer(commissionedPrice);
        emit bidPlaced(msg.sender, price);
    }

    function cancelBid (uint256 bidId) public payable isPending(bidBook[bidId]) isAuthorised(bidBook[bidId], msg.sender) {
        uint256 value = bidBook[bidId].value - msg.value;
        deleteAsk(bidId);
        address payable receiver = payable(msg.sender);
        receiver.call{value : value};
        emit bidCancelled(msg.sender, bidId);
    }

    function placeAsk (uint256 price) public payable {
        require(price >= 0, "price value must be more than 0");
        require(msg.value >= price, "Not enough blance to place ask");
        uint256 time = block.timestamp;
        uint256 commissionedPrice = msg.value * (100-commission) / 100;
        order memory newAsk = createAsk(msg.sender,commissionedPrice,time);
        sortAsk(newAsk);
        _owner.transfer(commissionedPrice);
        emit askPlaced(msg.sender, price);
    }

    function cancelAsk (uint256 askId) public payable isPending(askBook[askId]) isAuthorised(askBook[askId], msg.sender) {
        uint256 value = askBook[askId].value - msg.value;
        deleteAsk(askId);
        address payable receiver = payable(msg.sender);
        receiver.call{value:value};
        emit askCancelled(msg.sender, askId);
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

    function fetchBid() public view returns (string memory) {
        uint256 current = bidHead;
        string memory output = "";
        while (current != 0) {
            uint256 next = bidBook[current].next;
            string memory currString = Strings.toString(current);
            output = concatenate(output,currString);
            current = next;
        }
        return output;
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

    function getBidNext (uint256 id) public view returns(uint256) {
        return bidBook[id].next;
    }

    function getAskNext (uint256 id) public view returns(uint256) {
        return askBook[id].next;
    }

    function getBidPrev (uint256 id) public view returns(uint256) {
        return bidBook[id].prev;
    }

    function getAskPrev (uint256 id) public view returns(uint256) {
        return askBook[id].prev;
    }

}