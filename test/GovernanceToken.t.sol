// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/GovernanceToken.sol";
import "../src/TokenVesting.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GovernanceTokenTest is Test {
    using SafeERC20 for IERC20;

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

        IERC20(address(token)).safeTransfer(address(vesting), 400_000 * 1e18);
    }

    function testInitialSupply() public view {
        assertEq(token.totalSupply(), 1_000_000 * 1e18);
    }

    function testTreasuryBalance() public view {
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

        IERC20(address(token)).safeTransfer(user, 1000);

        uint256 votes = token.getVotes(address(this));

        assertLt(votes, token.totalSupply());
    }

    function testVestingBeforeTime() public view {
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

    function testPermitSignature() public {
        uint256 privateKey = 0xA11CE;
        address owner = vm.addr(privateKey);
        address spender = address(3);

        IERC20(address(token)).safeTransfer(owner, 1000 ether);

        uint256 value = 100 ether;
        uint256 deadline = block.timestamp + 1 days;

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                owner,
                spender,
                value,
                token.nonces(owner),
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        token.permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), value);
    }
}