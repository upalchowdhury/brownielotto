
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    // 0
    // 1
    // 2

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        // $50 minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // uint256(
        //     keccack256(
        //         abi.encodePacked(
        //             nonce, // nonce is preditable (aka, transaction number)
        //             msg.sender, // msg.sender is predictable
        //             block.difficulty, // can actually be manipulated by the miners!
        //             block.timestamp // timestamp is predictable
        //         )
        //     )
        // ) % players.length;
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}

// pragma solidity ^0.6.6;

// // import "../interfaces/AggregatorV3Interface.sol";

// // import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";


// contract Lottery is VRFConsumerBase, Ownable {

//     address  payable [] public players;
//     uint256  public usdEntryFee;
//     AggregatorV3Interface internal ethUsdPriceFeed;
//     address payable public recentWinner;
//     uint256 public randomness;
//     bytes32 public keyhash;
    
//     enum LOTTERY_STATE {
//         OPEN,
//         CLOSED,
//         CALCULATING_WINNER
//     }

//     LOTTERY_STATE public lottery_state;
//     uint256 public fee;


//     //0
//     //1
//     //2

//     // address payable public firstar;
//     constructor (
//         address _priceFeedAddress,
//         address _vrfCoordinator, 
//         address _link,
//         uint256 _fee,
//         bytes32 _keyhash) 
//         public 
//         VRFConsumerBase(_vrfCoordinator,_link) 
        
//         {
//         usdEntryFee = 50 * (10**18);
//         ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
//         lottery_state = LOTTERY_STATE.CLOSED;
//         fee = _fee;
//         keyhash = _keyhash;
    
//     }

//     function enter() public payable {
//         require(lottery_state == LOTTERY_STATE.OPEN);
//         require(msg.value >= getEntranceFee(), "Not enough money");
//         players.push(payable(msg.sender));
//     }

//     function viewar(uint ind) 
//     public 
//     view 
//     returns(address firstar)
    
//     {
//         firstar = players[ind];
//         return firstar;
//     }

//     function getEntranceFee() 
//     public 
//     view 
//     returns(uint256)
//     {

//         // usdEntryFee = 50 * (10**18);
//         // AggregatorV3Interface  ethUsdPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
//      (,
//       int256 answer,
//       ,
//       ,
//      ) = ethUsdPriceFeed.latestRoundData();
//         uint256 adjustedPrice = uint256(answer) * 10 ** 10; // 18 decimals
//         uint256 costToEnter = (usdEntryFee * 10 ** 18) / adjustedPrice;
//         return costToEnter;
//         // uint256 price = 5;
//         // return price;
   
//    }

//     function startLottery() public onlyOwner {
//         require (lottery_state == LOTTERY_STATE.CLOSED,"not open yet");
//         lottery_state = LOTTERY_STATE.OPEN;
//     }

//     function endLottery() public onlyOwner{
//         lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
//         bytes32 requestId = requestRandomness(keyhash, fee);


//     }

//     function fullfillRandomness(bytes32 _requestId, uint256 _randomness) 
//     internal 
//    {
//         require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't the winner");
    
//         require (_randomness > 0, "random-not-found");
//         uint256 indexOfWinner = _randomness % players.length;
//         // [1,2,3,4,]
//         recentWinner = players[indexOfWinner];
//         recentWinner.transfer(address(this).balance);
//         players = new address payable[](0);
//         lottery_state = LOTTERY_STATE.CLOSED;
//         randomness = _randomness;

    
//     }

// }