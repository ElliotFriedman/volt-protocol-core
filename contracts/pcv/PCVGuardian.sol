// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../refs/CoreRef.sol";
import "./IPCVGuardian.sol";
import "./IPCVDeposit.sol";
import "../utils/CoreRefPauseableLib.sol";

contract PCVGuardian is IPCVGuardian, CoreRef {
    using CoreRefPauseableLib for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // If an address is in this set, it's a safe address to withdraw to
    EnumerableSet.AddressSet private safeAddresses;
    
    constructor(
        address _core,
        address[] memory _safeAddresses
    ) CoreRef(_core) {
        _setContractAdminRole(keccak256("PCV_GUARDIAN_ADMIN_ROLE"));

        for(uint256 i=0; i<_safeAddresses.length; i++) {
            _setSafeAddress(_safeAddresses[i]);
        }
    }

    // ---------- Read-Only API ----------

    /// @notice returns true if the the provided address is a valid destination to withdraw funds to
    /// @param pcvDeposit the address to check
    function isSafeAddress(address pcvDeposit) public view override returns (bool) {
        return safeAddresses.contains(pcvDeposit);
    }

    /// @notice returns all safe addresses
    function getSafeAddresses() public view override returns (address[] memory) {
        return safeAddresses.values();
    }

    // ---------- Governor-or-Admin-Only State-Changing API ----------

    /// @notice governor-only method to set an address as "safe" to withdraw funds to
    /// @param pcvDeposit the address to set as safe
    function setSafeAddress(address pcvDeposit) external override onlyGovernorOrAdmin() {
        _setSafeAddress(pcvDeposit);
    }

    /// @notice batch version of setSafeAddress
    /// @param _safeAddresses the addresses to set as safe, as calldata
    function setSafeAddresses(address[] calldata _safeAddresses) external override onlyGovernorOrAdmin() {
        for(uint256 i=0; i<_safeAddresses.length; i++) {
            _setSafeAddress(_safeAddresses[i]);
        }
    }

    // ---------- Governor-or-Admin-Or-Guardian-Only State-Changing API ----------

    /// @notice governor-or-guardian-only method to un-set an address as "safe" to withdraw funds to
    /// @param pcvDeposit the address to un-set as safe
    function unsetSafeAddress(address pcvDeposit) external override isGovernorOrGuardianOrAdmin() {
        _unsetSafeAddress(pcvDeposit);
    }

    /// @notice batch version of unsetSafeAddresses
    /// @param _safeAddresses the addresses to un-set as safe
    function unsetSafeAddresses(address[] calldata _safeAddresses) external override isGovernorOrGuardianOrAdmin() {
        for(uint256 i=0; i<_safeAddresses.length; i++) {
            _unsetSafeAddress(_safeAddresses[i]);
        }
    }

    /// @notice governor-or-guardian-only method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the address of the pcv deposit contract
    /// @param safeAddress the destination address to withdraw to
    /// @param amount the amount to withdraw
    /// @param pauseAfter if true, the pcv contract will be paused after the withdraw
    function withdrawToSafeAddress(address pcvDeposit, address safeAddress, uint256 amount, bool pauseAfter) external override isGovernorOrGuardianOrAdmin() {
        require(isSafeAddress(safeAddress), "Provided address is not a safe address!");

        pcvDeposit._ensureUnpaused();

        IPCVDeposit(pcvDeposit).withdraw(safeAddress, amount);

        if (pauseAfter) {
            pcvDeposit._pause();
        }

        emit PCVGuardianWithdrawal(pcvDeposit, safeAddress, amount);
    }

    /// @notice governor-or-guardian-only method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the address of the pcv deposit contract
    /// @param safeAddress the destination address to withdraw to
    /// @param amount the amount of tokens to withdraw
    /// @param pauseAfter if true, the pcv contract will be paused after the withdraw
    function withdrawETHToSafeAddress(address pcvDeposit, address payable safeAddress, uint256 amount, bool pauseAfter) external override isGovernorOrGuardianOrAdmin() {
        require(isSafeAddress(safeAddress), "Provided address is not a safe address!");

        pcvDeposit._ensureUnpaused();

        IPCVDeposit(pcvDeposit).withdrawETH(safeAddress, amount);

        if (pauseAfter) {
            pcvDeposit._pause();
        }

        emit PCVGuardianETHWithdrawal(pcvDeposit, safeAddress, amount);
    }

    /// @notice governor-or-guardian-only method to withdraw funds from a pcv deposit, by calling the withdraw() method on it
    /// @param pcvDeposit the deposit to pull funds from
    /// @param safeAddress the destination address to withdraw to
    /// @param amount the amount of funds to withdraw
    /// @param pauseAfter whether to pause the pcv after withdrawing
    function withdrawERC20ToSafeAddress(address pcvDeposit, address safeAddress, address token, uint256 amount, bool pauseAfter) external override isGovernorOrGuardianOrAdmin() {
        require(isSafeAddress(safeAddress), "Provided address is not a safe address!");

        pcvDeposit._ensureUnpaused();

        IPCVDeposit(pcvDeposit).withdrawERC20(token, safeAddress, amount);

        if (pauseAfter) {
            pcvDeposit._pause();
        }

        emit PCVGuardianERC20Withdrawal(pcvDeposit, safeAddress, token, amount);
    }

    // ---------- Internal Functions ----------

    function _setSafeAddress(address anAddress) internal {
        safeAddresses.add(anAddress);
        emit SafeAddressAdded(anAddress);
    }

    function _unsetSafeAddress(address anAddress) internal {
        safeAddresses.remove(anAddress);
        emit SafeAddressRemoved(anAddress);
    }
}