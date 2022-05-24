pragma solidity >=0.7.0 <0.9.0;

contract Auction {

    address owner;

    uint256 startDate;

    uint256 endDate;

    mapping(address => uint256) public bids;

    uint bidIncrement;

    bool isCancelled = false;

    address highestBidder;

    uint highestBindingBid;

    bool ownerHasWithdrawn = false;

    constructor(uint _start, uint _end, uint _increment){
        require(_start < _end, "Start time should be less than end time");
        owner = msg.sender;
        startDate = _start;
        //endDate = _end;
        endDate = block.timestamp + 200;
        bidIncrement = _increment;
    }

    function getHighestBid() public view returns (uint){
        return bids[highestBidder];
    }

    function getHighestPayableBid() public view returns (uint){
        return highestBindingBid;
    }

    function getHighestBidder() public view returns (address){
        return highestBidder;
    }

    function getBlockTimestamp() public view returns (uint){
        return block.timestamp;
    }

    function placeBids() public payable {
        //check if sender is not owner
        require (owner != msg.sender , "Owner cannot place bids");
        //check if auction has not been cancelled
        require (isCancelled == false, "Sorry, can't place bid, auction is cancelled");
        // check if auction has started
        require (block.timestamp > startDate, "Auction has not been started");
        //check if auction has not ended
        require (block.timestamp <= endDate, "Auction has been ended" );
        //check if ether sent is greater than 0
        require (msg.value > 0, "Please send ether greater than 0");

        //check what user's new bid is
        uint newBid = bids[msg.sender] + msg.value;

        //check if newBid is greater than highestBindingBid
        require(newBid > highestBindingBid, "Your bid is lower than the highest binding bid");

        bids[msg.sender] = newBid;

        uint highestBid = bids[highestBidder];

        if(newBid > highestBid){
            if(msg.sender != highestBidder){
                highestBidder = msg.sender;
                if(newBid < highestBid + bidIncrement){
                    highestBindingBid = newBid;
                }else{
                    highestBindingBid = highestBid + bidIncrement;
                }
            }
        } else{
            if(newBid + bidIncrement < highestBid){
                highestBindingBid = newBid + bidIncrement;
            }else{
                highestBindingBid = highestBid;
            }
        }
    }

    function cancelAuction() public returns (bool){
        require (!isCancelled , "Auction is already cancelled");
        isCancelled = true;
        return true;
    }

    function withdraw() public payable returns (bool){
        // if auction is cancelled everyone can withdraw their amount
        if(isCancelled){
            uint bid = bids[msg.sender];
            payable(msg.sender).transfer(bid);
        } else{
            require (block.timestamp > endDate, "Auction is still going on. You can't withdraw funds");
            if(msg.sender == owner){
                // owner can withdraw the amount of highest binding bid
                require(!ownerHasWithdrawn, "Owner has already withdrawn the amount");

                payable(msg.sender).transfer(highestBindingBid);
                ownerHasWithdrawn = true;
                
            }else if(msg.sender == highestBidder){
                // highest bidder can withdraw its difference amount
                uint amount = bids[highestBidder] - highestBindingBid;
                payable(msg.sender).transfer(amount);
            } else{
                // all other bidders can withdraw their amount
                uint bid = bids[msg.sender];
                payable(msg.sender).transfer(bid);
            }
        }
        bids[msg.sender] = 0;
        return true;
    }


} 
