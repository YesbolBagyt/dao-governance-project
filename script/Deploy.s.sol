// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import "../src/GovernanceToken.sol";
import "../src/MyGovernor.sol";
import "../src/Box.sol";

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        uint256 MIN_DELAY = 2 days;

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0); 

        TimelockController timelock = new TimelockController(
            MIN_DELAY,
            proposers,
            executors,
            msg.sender
        );

        GovernanceToken token = new GovernanceToken(address(timelock));

        MyGovernor governor = new MyGovernor(token, timelock);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), msg.sender);

        Box box = new Box(address(timelock));

        vm.stopBroadcast();

        console.log("========== DEPLOY SUCCESS ==========");
        console.log("Token:", address(token));
        console.log("Governor:", address(governor));
        console.log("Timelock:", address(timelock));
        console.log("Box:", address(box));
    }
}