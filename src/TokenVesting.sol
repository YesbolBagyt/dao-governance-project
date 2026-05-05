// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenVesting is Ownable {
    IERC20 public immutable token;
    address public immutable beneficiary;

    uint256 public immutable startTime;
    uint256 public immutable duration;
    uint256 public immutable totalAmount;

    uint256 public released;

    constructor(
        address _token,
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _duration
    ) Ownable(msg.sender) {
        require(_token != address(0), "Invalid token");
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_duration > 0, "Invalid duration");

        token = IERC20(_token);
        beneficiary = _beneficiary;
        totalAmount = _totalAmount;
        duration = _duration;
        startTime = block.timestamp;
    }

    function releasable() public view returns (uint256) {
        uint256 elapsed = block.timestamp - startTime;

        if (elapsed >= duration) {
            return totalAmount - released;
        }

        uint256 vestedAmount = (totalAmount * elapsed) / duration;
        return vestedAmount - released;
    }

    using SafeERC20 for IERC20;

    function release() external {
        uint256 amount = releasable();
        require(amount > 0, "Nothing to release");

        released += amount;
        token.safeTransfer(beneficiary, amount);
    }
}