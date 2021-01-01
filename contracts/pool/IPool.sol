pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A fluid pool for earning a reward token with staked tokens
/// @author Fei Protocol
interface IPool {

	// ----------- Events -----------

    event Claim(address indexed _account, uint _amountReward);

    event Deposit(address indexed _account, uint _amountStaked);

    event Withdraw(address indexed _account, uint _amountStaked, uint _amountReward);

    // ----------- State changing API -----------

    /// @notice collect redeemable rewards without unstaking
    /// @param account the account to claim for
    /// @return the amount of reward claimed
    /// @dev redeeming on behalf of another account requires ERC-20 approval of the pool tokens
    function claim(address account) external returns(uint);
    
    /// @notice deposit staked tokens
    /// @param amount the amount of staked to deposit
    /// @dev requires ERC-20 approval of stakedToken for the Pool contract
    function deposit(uint amount) external;

    /// @notice claim all rewards and withdraw stakedToken
    /// @return amountStaked the amount of stakedToken withdrawn
    /// @return amountReward the amount of rewardToken received
    function withdraw() external returns(uint amountStaked, uint amountReward);
    
    /// @notice initializes the pool start time. Only callable once
    function init() external;

    // ----------- Getters -----------

    /// @notice the ERC20 reward token
    /// @return the IERC20 implementation address
    function rewardToken() external view returns(IERC20);

    /// @notice the total amount of rewards distributed by the contract over entire period
    /// @return the total, including currently held and previously claimed rewards
    function totalReward() external view returns (uint);
    
    /// @notice the amount of rewards currently redeemable by an account
    /// @param account the potentially redeeming account
    /// @return reward amount
    function redeemableReward(address account) external view returns(uint);
 
    /// @notice the total amount of rewards owned by contract and unlocked for release
    /// @return the total
    function releasedReward() external view returns (uint);
    
    /// @notice the total amount of rewards owned by contract and locked
    /// @return the total
    function unreleasedReward() external view returns (uint);

    /// @notice the total balance of rewards owned by contract, locked or unlocked
    /// @return the total
    function rewardBalance() external view returns (uint);

    /// @notice the total amount of rewards previously claimed
    /// @return the total
    function claimedRewards() external view returns(uint128);

    /// @notice the ERC20 staked token
    /// @return the IERC20 implementation address
    function stakedToken() external view returns(IERC20);

    /// @notice the total amount of staked tokens in the contract
    /// @return the total
    function totalStaked() external view returns(uint128);

    /// @notice the staked balance of a given account
    /// @param account the user account
    /// @return the total staked
    function stakedBalance(address account) external view returns(uint);    
}
