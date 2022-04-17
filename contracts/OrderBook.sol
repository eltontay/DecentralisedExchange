// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
    Considerations : Order Book can be Huge and Expensive
    - Implementaton for quick sort algo to minimise gas
        - O(n log n)

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

contract OrderBook {

    // if State is pending, can allow for cancellation
    enum State { pending , completed }

    address payable _owner = payable(msg.sender);
    uint256 commission; // Going the extra mile - commmission 0%-100%

    constructor (uint256 _commission) {
        commission = _commission;
    }

    struct order {
        address payable customer;
        uint256 value; // msg.value less commission
        uint256 timestamp; // for ordered list
        State state;
    }

    order[] bidBook;
    order[] askBook;
    uint[] request;

    event bidPlaced(address,uint256,uint256,State);
    event askPlaced(address,uint256,uint256,State);
    event bidCancelled(uint);
    event askCancelled(uint);

/*
    Modifier Functions
*/

    modifier isPending(order memory _order) {
        require(_order.state == State.pending, "Order Pending");
        _;
    }

    modifier isAuthorised(order memory _order, address sender) {
        require(_order.customer == payable(sender), "Not Authorised");
        _;
    }


/*
    Helper Functons
*/

    function sortBid() internal {
       descendingQuickSort(bidBook, int(0), int(bidBook.length - 1));
       return;
    }

    function sortAsk() internal {
       ascendingQuickSort(bidBook, int(0), int(bidBook.length - 1));
       return;
    }

    function deleteArray() internal {
        for (uint i = 0; i < request.length; i ++) {
            delete request[i];
        }
    }

    function descendingQuickSort(order[] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        uint256 pivot = arr[uint(left + (right - left) / 2)].value;
        while (i <= j) {
            while (arr[uint(i)].value < pivot) i++;
            while (pivot < arr[uint(j)].value) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            descendingQuickSort(arr, left, j);
        if (i < right)
            descendingQuickSort(arr, i, right);
    }

    function ascendingQuickSort(order[] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        uint256 pivot = arr[uint(left + (right - left) / 2)].value;
        while (i <= j) {
            while (arr[uint(i)].value > pivot) i++;
            while (pivot > arr[uint(j)].value) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            ascendingQuickSort(arr, left, j);
        if (i < right)
            ascendingQuickSort(arr, i, right);
    }

/*
    Callable Functions
*/

    function placeBid (uint256 price) public payable {
        require(price >= 0, "price value must be more than 0");
        require(msg.value >= price, "Not enough blance to place bid");
        uint256 time = block.timestamp;
        uint256 commissionedPrice = msg.value * (100-commission) / 100;
        order memory newBid = order(payable(msg.sender),commissionedPrice,time,State.pending);
        bidBook.push(newBid);
        _owner.transfer(commissionedPrice);
        emit bidPlaced(msg.sender,commissionedPrice,time,State.pending);
    }

    function cancelBid (uint bidId) public isPending(bidBook[bidId]) isAuthorised(bidBook[bidId], msg.sender) {
        bidBook[bidId].customer.transfer(bidBook[bidId].value);
        delete bidBook[bidId];
        sortBid();
        emit bidCancelled(bidId);
    }

    function placeAsk (uint256 price) public payable {
        require(price >= 0, "price value must be more than 0");
        require(msg.value >= price, "Not enough blance to place ask");
        uint256 time = block.timestamp;
        uint256 commissionedPrice = msg.value * (100-commission) / 100;
        order memory newBid = order(payable(msg.sender),commissionedPrice,time,State.pending);
        askBook.push(newBid);
        _owner.transfer(commissionedPrice);
        emit askPlaced(msg.sender,commissionedPrice,time,State.pending);
    }

    function cancelAsk (uint askId) public isPending(askBook[askId]) isAuthorised(askBook[askId], msg.sender) {
        askBook[askId].customer.transfer(askBook[askId].value);
        delete askBook[askId];
        sortAsk();      
        emit askCancelled(askId);
    }

/*
    Getter Functions
*/

    function fetchAllBid() public view returns (order[] memory) {
        return bidBook;
    }

    function fetchAllAsk() public view returns (order[] memory) {
        return askBook;
    }

    function fetchYourBidIds() public returns (uint[] memory) {
        deleteArray();
        for (uint i = 0; i < bidBook.length; i++) {
            if (bidBook[i].customer == payable(msg.sender)) {
                request.push(i);
            }
        }
        return request;
    }

    function fetchYourAskIds() public returns (uint[] memory) {
        deleteArray();
        for (uint i = 0; i < askBook.length; i++) {
            if (askBook[i].customer == payable(msg.sender)) {
                request.push(i);
            }
        }
        return request;
    }

    function getBidAddress (uint id) public view returns(address payable) {
        return bidBook[id].customer;
    }

    function getAskAddress (uint id) public view returns(address payable) {
        return askBook[id].customer;
    }

    function getBidValue (uint id) public view returns(uint256) {
        return bidBook[id].value;
    }

    function getAskValue (uint id) public view returns(uint256) {
        return askBook[id].value;
    }

    function getBidState (uint id) public view returns(State) {
        return bidBook[id].state;
    }

    function getAskState (uint id) public view returns(State) {
        return askBook[id].state;
    }

}