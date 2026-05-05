// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/GovernanceToken.sol";
import "../src/MyGovernor.sol";
import "../src/FeeSettings.sol";

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MyGovernorTest is Test {
    using SafeERC20 for IERC20;
    GovernanceToken token;
    TimelockController timelock;
    MyGovernor governor;
    FeeSettings feeSettings;

    address proposer = address(this);
    address voter = address(1);
    address recipient = address(2);

    uint256 constant MIN_DELAY = 2 days;
    uint256 constant TRANSFER_AMOUNT = 1_000 ether;

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

        feeSettings = new FeeSettings(address(timelock));

        token.delegate(proposer);

        IERC20(address(token)).safeTransfer(voter, 50_000 ether);
        vm.prank(voter);
        token.delegate(voter);

        vm.roll(block.number + 1);
    }

    function testGovernorConfiguration() public view {
        assertEq(governor.votingDelay(), 7200);
        assertEq(governor.votingPeriod(), 50400);
        assertEq(governor.proposalThreshold(), 10_000 ether);
    }

    function testTimelockDelay() public view {
        assertEq(timelock.getMinDelay(), MIN_DELAY);
    }

    function testGovernorIsProposer() public view {
        assertTrue(
            timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor))
        );
    }

    function testOpenExecutorRole() public view {
        assertTrue(
            timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0))
        );
    }

    function testTreasuryHoldsTokens() public view {
        assertEq(token.balanceOf(address(timelock)), 300_000 ether);
    }

    function testFullProposalLifecycleTransferTokens() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "transfer(address,uint256)",
            recipient,
            TRANSFER_AMOUNT
        );

        string memory description = "Transfer treasury tokens";

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

        assertEq(token.balanceOf(recipient), TRANSFER_AMOUNT);
    }

    function testProposalChangesFeeParameter() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(feeSettings);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "setFeePercentage(uint256)",
            5
        );

        string memory description = "Change fee";

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

        assertEq(feeSettings.feePercentage(), 5);
    }

    function testDelegateeVotesOnBehalfOfDelegator() public {
        address delegator = address(10);
        address delegatee = address(11);

        IERC20(address(token)).safeTransfer(delegator, 20_000 ether);

        vm.prank(delegator);
        token.delegate(delegatee);

        vm.roll(block.number + 1);

        assertEq(token.getVotes(delegatee), 20_000 ether);
    }

    function testProposalDefeated() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(feeSettings);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "setFeePercentage(uint256)",
            9
        );

        string memory description = "Fail proposal";

        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            description
        );

        vm.roll(block.number + governor.votingDelay() + 1);

        governor.castVote(proposalId, 0);

        vm.roll(block.number + governor.votingPeriod() + 1);

        assertEq(
            uint8(governor.state(proposalId)),
            uint8(IGovernor.ProposalState.Defeated)
        );
    }

   function testQuorumCalculation() public {
    vm.roll(block.number + 1);

    uint256 quorum = governor.quorum(block.number - 1);

    assertEq(quorum, 40_000 ether);
}

    function testProposalThreshold() public view {
        assertEq(governor.proposalThreshold(), 10_000 ether);
    }

    function testProposalCreation() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(feeSettings);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature(
            "setFeePercentage(uint256)",
            3
        );

        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Test proposal"
        );

        assertGt(proposalId, 0);
    }
}