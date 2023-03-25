// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./partialIERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract KYCController is AccessControl {

    mapping (address => bool) isKYCed; // must be set to true in order for redemptions

    constructor(address[] memory kycManagers) {
        for (uint256 i = 0; i < kycManagers.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, kycManagers[i]);
        }
    }

    function isUserKyced(address addr) external view returns (bool) {
        return isKYCed[addr];
    }

    function kycUser(address kycAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isKYCed[kycAddress] = true;
    }
}