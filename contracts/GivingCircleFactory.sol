// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IGivingCircle.sol";
import "./partialIERC20.sol";
import "./Initialization.sol";
import "./Proposals.sol";
import "./Attendees.sol";

contract GivingCircleFactory is AccessControl {

    uint256 public instancesCount;
    mapping (uint256 => IGivingCircle) public instances;

    address public implementation;

    bytes32 public constant CIRCLE_CREATOR_ROLE = keccak256("CIRCLE_CREATOR_ROLE");


    event CreatedNewCircle(address);

    constructor(address[] memory admins) {

        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
    }

    function createGivingCircle(Initialization.GivingCircleInitialization memory init) external onlyRole(CIRCLE_CREATOR_ROLE) {
        address clone = Clones.clone(address(implementation));
        IGivingCircle newGivingCircle = IGivingCircle(clone);

        newGivingCircle.initialize(init);

        instances[instancesCount] = newGivingCircle;
        instancesCount++;
        emit CreatedNewCircle(clone);
    }

    function setImplementation(address _implementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setImplementation(_implementation);
    }

    function _setImplementation(address _implementation) internal {
        require(_implementation != address(0), "Address cannot be zero address!");
        implementation = _implementation;
    }

    //End Circle Interaction Functions
}