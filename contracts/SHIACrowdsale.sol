// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SHIACrowdsale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // The token being sold
    IERC20 private _token;

    // owner of contract
    address private _owner;

    // The token being sold
    IERC20 private _usdt;

    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per USDT
    uint256 private _rate;

    // Amount of USDT raised
    uint256 private _usdtRaised;

    // Maximum investment per investor (in USDT)
    uint256 private _maxInvestment;

    // Minimum investment per investor (in USDT)
    uint256 private _minInvestment;

    // Crowdsale opening time
    uint256 private _openingTime;

    // Crowdsale closing time
    uint256 private _closingTime;

    // Crowdsale status
    bool private _isOpen;

    // Mapping of purchaser addresses and the amount of USDT they have invested
    mapping(address => uint256) private _investments;

    // Event for token purchase logging
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token,
        IERC20 usdt,
        uint256 maxInvestment,
        uint256 minInvestment,
        uint256 openingTime,
        uint256 closingTime
    ) {
        require(rate > 0, "SHIACrowdsale: rate is 0");
        require(wallet != address(0), "SHIACrowdsale: wallet is the zero address");
        require(address(token) != address(0), "SHIACrowdsale: token is the zero address");
        require(maxInvestment > 0, "SHIACrowdsale: max investment is 0");
        require(minInvestment > 0, "SHIACrowdsale: min investment is 0");
        require(openingTime >= block.timestamp, "SHIACrowdsale: opening time is before current time");
        require(closingTime > openingTime, "SHIACrowdsale: closing time is before opening time");

        _rate = rate;
        _wallet = wallet;
        _token = token;
        _usdt = usdt;
        _maxInvestment = maxInvestment;
        _minInvestment = minInvestment;
        _openingTime = openingTime;
        _closingTime = closingTime;
        _isOpen = false;
    }

    /**
     * @dev Returns the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @dev Returns the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @dev Returns the crowdsale rate.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @dev Returns the amount of USDT raised.
     */
    function usdtRaised() public view returns (uint256) {
        return _usdtRaised;
    }

    /**
     * @dev Returns the crowdsale status.
     */
    function isOpen() public view returns (bool) {
        return _isOpen;
    }

    /**
     * @dev Returns the minimum investment amount per investor.
     */
    function minInvestment() public view returns (uint256) {
        return _minInvestment;
    }

    /**
     * @dev Returns the address of the wallet where funds are collected.
     */
    function wallet() public view returns (address) {
        return _wallet;
    }

    /**
     * @dev Returns the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @dev Returns the amount of USDT invested by a purchaser.
     */
    function investedAmountOf(address purchaser) public view returns (uint256) {
        return _investments[purchaser];
    }

    /**
     * @dev Opens the crowdsale for investment.
     */
    function open() public onlyOwner {
        require(!_isOpen, "SHIACrowdsale: already open");
        _isOpen = true;
    }

    /**
     * @dev Closes the crowdsale for investment.
     */
    function close() public onlyOwner {
        require(_isOpen, "SHIACrowdsale: not open");
        _isOpen = false;
    }

    /**
     * @dev Allows an investor to purchase tokens.
     * @param beneficiary Recipient of the token purchase.
     */
    function buyTokens(address beneficiary, uint256 amount) public nonReentrant payable {
        require(beneficiary != address(0), "SHIACrowdsale: beneficiary is the zero address");
        require(_isOpen, "SHIACrowdsale: not open");
        require(block.timestamp >= _openingTime, "SHIACrowdsale: not yet open");
        require(block.timestamp <= _closingTime, "SHIACrowdsale: already closed");
        require(amount >= _minInvestment, "SHIACrowdsale: investment amount is less than minimum");
        require(amount <= _maxInvestment, "SHIACrowdsale: investment amount is greater than maximum");

        uint256 usdtAmount = amount;
        uint256 tokens = usdtAmount.mul(_rate);

        require(_token.balanceOf(address(this)) >= tokens, "SHIACrowdsale: insufficient token balance");

        _investments[msg.sender] = _investments[msg.sender].add(usdtAmount);
        _usdtRaised = _usdtRaised.add(usdtAmount);

        _token.transfer(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, usdtAmount, tokens);

        _forwardFunds(amount);
    }

    /**
     * @dev Determines how USDT is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 amount) internal {
        require(_wallet != address(0), "SHIACrowdsale: wallet is the zero address");
        require(_usdt.balanceOf(msg.sender) >= amount, "SHIACrowdsale: insufficient USDT balance");
        require(_usdt.transferFrom(msg.sender, _wallet, amount), "SHIACrowdsale: failed to transfer USDT");
    }
}