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
*/

contract OrderBook {


    struct order {
        address payable customer;
        uint256 price;
        uint256 timestamp;
    }

    order[] bidBook;
    order[] askBook;

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

    function descendingQuickSort(order[] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        uint256 pivot = arr[uint(left + (right - left) / 2)].timestamp;
        while (i <= j) {
            while (arr[uint(i)].timestamp < pivot) i++;
            while (pivot < arr[uint(j)].timestamp) j--;
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
        uint256 pivot = arr[uint(left + (right - left) / 2)].timestamp;
        while (i <= j) {
            while (arr[uint(i)].timestamp > pivot) i++;
            while (pivot > arr[uint(j)].timestamp) j--;
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

    function placeBid (uint256 price) public {
        order memory newBid = order(payable(msg.sender),price,block.timestamp);
        bidBook.push(newBid);
    }

    function cancelBid (uint256 bidId) public {

    }

    function placeAsk (uint256 price) public {

    }

    function cancelAsk (uint256 price) public {

    }

    // function fetchAllBid() public view returns (order[] memory) {

    // }

    // function fetchYourBid() public view returns (order[] memory) {
    //     return bidSide[msg.sender]; 
    // }

    // function fetchYourAsk() public view returns (order[] memory) {
    //     return askSide[msg.sender];
    // }
}