// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SHIA is ERC20, Ownable {
    uint256 public maxHoldingAmount;
    uint256 public maxTxAmount;
    mapping(address => bool) public blacklists;

    constructor() ERC20("SHIA", "SHIA") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
        maxTxAmount = 1000000 * 10 ** decimals();
        maxHoldingAmount = 50000000 * 10 ** decimals();
    }

    function setRule(
        uint256 _maxHoldingAmount,
        uint256 _maxTxAmount
    ) external onlyOwner {
        maxHoldingAmount = _maxHoldingAmount;
        maxTxAmount = _maxTxAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (from != owner() && to != owner()) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }

        if (maxTxAmount > 0 && from != owner() && to != owner()) {
            require(amount <= maxTxAmount, "Exceeds max transaction amount");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}
