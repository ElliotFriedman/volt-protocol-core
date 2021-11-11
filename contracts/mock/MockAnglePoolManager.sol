// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

contract MockAnglePoolManager {
    address public token;

	constructor(address _token) {
		token = _token;
	}
}