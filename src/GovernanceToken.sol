// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract GovernanceToken is ERC20, ERC20Permit, ERC20Votes {
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10 ** 18;

    constructor(address treasury)
        ERC20("GovernanceToken", "GTK")
        ERC20Permit("GovernanceToken")
    {
        uint256 team = (MAX_SUPPLY * 40) / 100;
        uint256 treasuryAmount = (MAX_SUPPLY * 30) / 100;
        uint256 community = (MAX_SUPPLY * 20) / 100;
        uint256 liquidity = (MAX_SUPPLY * 10) / 100;

        _mint(msg.sender, team);
        _mint(treasury, treasuryAmount);
        _mint(msg.sender, community);
        _mint(msg.sender, liquidity);
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}