// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./partialIERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract KYCController is AccessControl {

    mapping (address => bool) isKYCed; // must be set to true in order for redemptions

    bytes32 public constant KYC_MANAGER_ROLE = keccak256("KYC_MANAGER_ROLE");

    constructor(address kycManager) {
        _grantRole(KYC_MANAGER_ROLE, kycManager);
    }

    function isUserKyced(address addr) external view returns (bool) {
        return isKYCed[addr];
    }

    function kycUser(address kycAddress) external onlyRole(KYC_MANAGER_ROLE) {
        isKYCed[kycAddress] = true;
    }
}