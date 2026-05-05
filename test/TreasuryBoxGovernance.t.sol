// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/GovernanceToken.sol";
import "../src/MyGovernor.sol";
import "../src/Box.sol";

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TreasuryBoxGovernanceTest is Test {
    GovernanceToken token;
    TimelockController timelock;
    MyGovernor governor;
    Box box;

    address voter = address(1);

    uint256 constant MIN_DELAY = 2 days;

    function setUp() public {
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);

        timelock = new TimelockController(
            MIN_DELAY,
            proposers,
            executors,
            address(this)
        );

        token = new GovernanceToken(address(timelock));

        governor = new MyGovernor(token, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, address(this));

        box = new Box(address(timelock));

        token.delegate(address(this));

        token.transfer(voter, 50_000 ether);
        vm.prank(voter);
        token.delegate(voter);

        vm.roll(block.number + 1);
    }

    function testGovernanceUpdatesBoxValue() public {
        // encode function call: store(42)
        bytes memory encodedCall = abi.encodeWithSignature(
            "store(uint256)",
            42
        );

        address[] memory targets = new address[](1);
        targets[0] = address(box);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = encodedCall;

        string memory description = "Store 42 in Box";

        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            description
        );

        vm.roll(block.number + governor.votingDelay() + 1);

        governor.castVote(proposalId, 1);

        vm.roll(block.number + governor.votingPeriod() + 1);

        bytes32 descriptionHash = keccak256(bytes(description));

        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MIN_DELAY + 1);

        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(box.retrieve(), 42);
    }
}