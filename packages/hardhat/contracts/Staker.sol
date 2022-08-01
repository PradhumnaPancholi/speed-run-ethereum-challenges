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
  uint public deadline = block.timestamp + 50 seconds;
  
  bool public openForWithdraw = false;
  
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  event Stake(address staker, uint256 amount);

  event Withdraw(address staker, uint256 amount);

  // this modifier will check if staked funds are already moved to the extern contract//
  // this will protect "execute" and "withdraw" at higher level along side other guards //
  modifier notCompleted {
    require(exampleExternalContract.completed() == false, "Your staking threshold is complete");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    require(deadline > block.timestamp, "Deadline has been passed, you can not stake anymore !");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public notCompleted {
    //if excuted was performed succesfully before, show an error to reflect this//
    require(!openForWithdraw, "Actions has been already performed!");
    // if deadline is not passed, show error to refelct it//
    require(block.timestamp > deadline, "Deadline is not completed yet!");
    // if is used instead of require becasu we have a counter action to set "openForWithdraw" to true//
    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      // If the `threshold` was not met, allow everyone to call a `withdraw()` function
      openForWithdraw = true;
    }
  }

  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw()  external notCompleted{
    require(openForWithdraw, "Contract is not open for Withdrawals!");
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
