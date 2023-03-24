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

    event CreatedNewCircle(address);

    constructor(address[] memory admins) {

        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
    }

    function createGivingCircle(Initialization.GivingCircleInitialization memory init) public {
        address clone = Clones.clone(address(implementation));
        IGivingCircle newGivingCircle = IGivingCircle(clone);
        init.circleLeaders = addSelfToArray(init.circleLeaders);
        init.beanPlacementAdmins = addSelfToArray(init.beanPlacementAdmins);
        init.fundsManagers = addSelfToArray(init.fundsManagers);
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

    //Start Circle Interaction Functions

    function createNewProposal(uint256 index, address payable giftRecipient) external {
        require(instances[index].hasRole(instances[index].LEADER_ROLE(), msg.sender), "Must be a leader to do this action!");
        instances[index].createNewProposal(giftRecipient);
    }

    function registerAttendees(uint256 index, address[] memory addrs) external {
        require(instances[index].hasRole(instances[index].LEADER_ROLE(), msg.sender), "Must be a leader to do this action!");
        instances[index].registerAttendees(addrs);
    }

    function registerAttendee(uint256 index, address addr) external {
        require(instances[index].hasRole(instances[index].LEADER_ROLE(), msg.sender), "Must be a leader to do this action!");
        instances[index].registerAttendee(addr);
    }

    function ProgressToBeanPlacementPhase(uint256 index) external {
        require(instances[index].hasRole(instances[index].LEADER_ROLE(), msg.sender), "Must be a leader to do this action!");
        instances[index].ProgressToBeanPlacementPhase();
    }

    function placeMyBeans(uint256 index, uint256 proposalIndex, uint256 beanQuantity) external {
        instances[index].placeBeansForSomeone(msg.sender, proposalIndex, beanQuantity);
    }

    function ProgressToGiftRedeemPhase(uint256 index) external {
        require(instances[index].hasRole(instances[index].LEADER_ROLE(), msg.sender), "Must be a leader to do this action!");
        instances[index].ProgressToGiftRedeemPhase();
    }

    function redeemMyGift(uint256 index) external {
        instances[index].redeemGiftForSomeone(msg.sender);
    }

    function attendeeCount(uint256 index) external view returns(uint256) {
        return instances[index].attendeeCount();
    }

    function getAttendees(uint256 index) external view returns(Attendees.Attendee[] memory) {
        return instances[index].getAttendees();
    }

    function proposalCount(uint256 index) external view returns(uint256) {
        return instances[index].proposalCount();
    }

    function getProposals(uint256 index) external view returns(Proposals.Proposal[] memory proposals) {
        return instances[index].getProposals();
    }

    function getAvailableBeans(uint256 index, address addr) external view returns(uint256) {
        return instances[index].getAvailableBeans(addr);
    }

    function getTotalBeansDispursed(uint256 index) external view returns(uint256) {
        return instances[index].getTotalBeansDispursed();
    }

    function getLeftoverFunds(uint256 index) external view returns(uint256) {
        return instances[index].getLeftoverFunds();
    }

    function getTotalRedeemedFunds(uint256 index) external view returns(uint256) {
        return instances[index].getTotalRedeemedFunds();
    }
    function getTotalUnredeemedFunds(uint256 index) external view returns(uint256) {
        return instances[index].getTotalUnredeemedFunds();
    }
    function getTotalAllocatedFunds(uint256 index) external view returns (uint256) {
        return instances[index].getTotalAllocatedFunds();
    }

    //End Circle Interaction Functions

    // FACTORY HELPER FUNCTIONS
    function addSelfToArray(address[] memory _arr) internal view returns(address[] memory) {
        address[] memory arr = new address[](_arr.length + 1);

        for (uint256 i = 0; i < _arr.length; i++) {
            arr[i] = _arr[i];
        }

        arr[arr.length - 1] = address(this);
        return arr;
    }
}