// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleAuction {
    address public auctionOwner;
    uint256 public auctionEndTime;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public pendingReturns;

    enum AuctionState { Ongoing, Ended }
    AuctionState public state;

    event AuctionStarted(uint256 endTime);
    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 _auctionDuration) {
        auctionOwner = msg.sender;
        auctionEndTime = block.timestamp + _auctionDuration;
        state = AuctionState.Ongoing;
        emit AuctionStarted(auctionEndTime);
    }

    function bid() public payable {
        require(state == AuctionState.Ongoing, "Auction has ended.");
        require(block.timestamp <= auctionEndTime, "Auction has expired.");
        require(msg.value > highestBid, "Bid must be higher than current highest bid.");

        // Refund the previous highest bidder
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit NewBid(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            (bool success, ) = msg.sender.call{value: amount}("");
            if (!success) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function endAuction() public {
        require(msg.sender == auctionOwner, "Only the auction owner can end the auction.");
        require(state == AuctionState.Ongoing, "Auction already ended.");
        require(block.timestamp > auctionEndTime, "Auction has not yet ended.");

        state = AuctionState.Ended;
        emit AuctionEnded(highestBidder, highestBid);

        // Transfer the highest bid to the auction owner
        payable(auctionOwner).transfer(highestBid);
    }
}
