// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../refs/CoreRef.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title abstract contract for putting a rate limit on how fast a contract can perform an action e.g. Minting
/// @author Fei Protocol
abstract contract RateLimited is CoreRef {

    /// @notice maximum rate limit per second governance can set for this contract
    uint256 public immutable MAX_RATE_LIMIT_PER_SECOND;

    /// @notice the rate per second for this contract
    uint256 public rateLimitPerSecond;

    /// @notice the last time the buffer was used by the contract
    uint256 public lastBufferUsedTime;

    /// @notice the cap of the buffer that can be used at once
    uint256 public bufferCap;

    /// @notice a flag for whether to allow partial actions to complete if the buffer is less than amount
    bool public doPartialAction;

    uint256 private _bufferStored;

    event BufferCapUpdate(uint256 oldBufferCap, uint256 newBufferCap);
    event RateLimitPerSecondUpdate(uint256 oldRateLimitPerSecond, uint256 newRateLimitPerSecond);

    constructor(uint256 _maxRateLimitPerSecond, uint256 _rateLimitPerSecond, uint256 _bufferCap, bool _doPartialAction) {
        lastBufferUsedTime = block.timestamp;

        _bufferStored = _bufferCap;
        _setBufferCap(_bufferCap);

        require(_rateLimitPerSecond <= _maxRateLimitPerSecond, "RateLimitedMinter: rateLimitPerSecond too high");
        _setRateLimitPerSecond(_rateLimitPerSecond);
        
        MAX_RATE_LIMIT_PER_SECOND = _maxRateLimitPerSecond;
        doPartialAction = _doPartialAction;
    }

    /// @notice set the rate limit per second
    function setRateLimitPerSecond(uint256 newRateLimitPerSecond) external onlyGovernorOrAdmin {
        require(newRateLimitPerSecond <= MAX_RATE_LIMIT_PER_SECOND, "RateLimitedMinter: rateLimitPerSecond too high");
        _setRateLimitPerSecond(newRateLimitPerSecond);
    }

    /// @notice set the buffer cap
    function setbufferCap(uint256 newBufferCap) external onlyGovernorOrAdmin {
        _setBufferCap(newBufferCap);
    }

    /// @notice the amount of action used before hitting limit
    /// @dev replenishes at rateLimitPerSecond per second up to bufferCap
    function buffer() public view returns(uint256) { 
        uint256 elapsed = block.timestamp - lastBufferUsedTime;
        return Math.min(_bufferStored + (rateLimitPerSecond * elapsed), bufferCap);
    }

    function _depleteBuffer(uint256 amount) internal returns(uint256) {
        uint256 newBuffer = buffer();
        
        uint256 usedAmount = amount;
        if (doPartialAction && usedAmount > newBuffer) {
            usedAmount = newBuffer;
        }

        require(usedAmount <= newBuffer, "RateLimitedMinter: rate limit hit");

        _bufferStored = newBuffer - usedAmount;

        lastBufferUsedTime = block.timestamp;

        return usedAmount;
    }

    function _setRateLimitPerSecond(uint256 newRateLimitPerSecond) internal {

        // Reset the stored buffer and last buffer used time using the prior RateLimitPerSecond
        _bufferStored = buffer();
        lastBufferUsedTime = block.timestamp;

        uint256 oldRateLimitPerSecond = rateLimitPerSecond;
        rateLimitPerSecond = newRateLimitPerSecond;

        emit RateLimitPerSecondUpdate(oldRateLimitPerSecond, newRateLimitPerSecond);
    }

    function _setBufferCap(uint256 newBufferCap) internal {
        uint256 oldBufferCap = bufferCap;
        bufferCap = newBufferCap;

        // Cap the existing stored buffer
        if (_bufferStored > newBufferCap) {
            _bufferStored = newBufferCap;
        }

        emit BufferCapUpdate(oldBufferCap, newBufferCap);
    }
}
