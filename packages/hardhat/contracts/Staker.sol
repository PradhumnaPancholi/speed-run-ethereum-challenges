// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  //to keep track of users' balance //
  mapping(address => uint256) public balances;

  //threshold of staked ETH required //
  uint public constant threshold = 1 ether;

  //deadline for staking//
  uint public deadline = block.timestamp + 30 seconds;
  
  bool public openForWithdraw = false;
  
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  event Stake(address staker, uint256 amount);

  event Withdraw(address staker, uint256 amount);

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    // ToDo: Need to add deadline verification//
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public {
    // require is used to show meaningful error message//
    require(block.timestamp > deadline, "Deadline is not completed yet");
    // if is used instead of require becasu we have a counter action//
    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      // If the `threshold` was not met, allow everyone to call a `withdraw()` function
      openForWithdraw = true;
    }
  }

  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw()  external {
    require(openForWithdraw, "Threshold was met, you can not withdraw");
    // ToDo: update balances mapping //
    uint withdrawAmount = balances[msg.sender];
    balances[msg.sender] -= withdrawAmount; 
    (bool success, ) = (msg.sender).call{value: withdrawAmount}("");
    require(success, "Withdrawal Failed");
    emit Withdraw(msg.sender, withdrawAmount); 
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    }else {
      return (deadline - block.timestamp);
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    //ToDo: deadline verification //
    stake(); 
  }


}
