// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FeeSettings is Ownable {
    uint256 public feePercentage;

    constructor(address initialOwner) Ownable(initialOwner) {
        feePercentage = 1;
    }

    function setFeePercentage(uint256 newFee) external onlyOwner {
        require(newFee <= 100, "Fee too high");
        feePercentage = newFee;
    }
}