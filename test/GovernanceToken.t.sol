// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GovernanceToken.sol";
import "../src/TokenVesting.sol";

contract GovernanceTokenTest is Test {
    GovernanceToken token;
    TokenVesting vesting;

    address treasury = address(1);
    address user = address(2);

    function setUp() public {
        token = new GovernanceToken(treasury);

        vesting = new TokenVesting(
            address(token),
            user,
            400_000 * 1e18,
            365 days
        );

        token.transfer(address(vesting), 400_000 * 1e18);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1_000_000 * 1e18);
    }

    function testTreasuryBalance() public {
        assertEq(token.balanceOf(treasury), 300_000 * 1e18);
    }

    function testDelegation() public {
        token.delegate(address(this));
        assertEq(token.getVotes(address(this)), token.balanceOf(address(this)));
    }

    function testVotingPowerSnapshot() public {
        token.delegate(address(this));

        uint256 votes = token.getVotes(address(this));
        assertGt(votes, 0);
    }

    function testTransferAffectsVotes() public {
        token.delegate(address(this));

        token.transfer(user, 1000);

        uint256 votes = token.getVotes(address(this));
        assertLt(votes, token.totalSupply());
    }

    function testVestingBeforeTime() public {
        uint256 releasable = vesting.releasable();
        assertEq(releasable, 0);
    }

    function testVestingHalfTime() public {
        vm.warp(block.timestamp + 180 days);

        uint256 releasable = vesting.releasable();
        assertGt(releasable, 0);
    }

    function testVestingFullTime() public {
        vm.warp(block.timestamp + 365 days);

        uint256 releasable = vesting.releasable();
        assertEq(releasable, 400_000 * 1e18);
    }
}