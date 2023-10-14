// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./implementations/FullVesting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VestingPoolFactory is Ownable {
    using SafeMath for uint256;

    address[] public vestingPools;

    function createPool(
        string memory _name,
        address _token,
        uint256 _startTime,
        uint256 _vestingDuration
    ) external onlyOwner {
        VestingBase pool = new VestingBase(
            _name,
            _token,
            _startTime,
            _vestingDuration,
            msg.sender
        );
        vestingPools.push(address(pool));
    }

    function createFullPool(
        string memory _name,
        address _token,
        uint256 _startTime,
        uint256 _vestingDuration
    ) external onlyOwner {
        FullVesting pool = new FullVesting(
            _name,
            _token,
            _startTime,
            _vestingDuration,
            msg.sender
        );
        vestingPools.push(address(pool));
    }

    function getPools() external view returns (address[] memory _pools) {
        _pools = vestingPools;
    }
}
