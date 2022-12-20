// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./Initialization.sol";
import "./Proposals.sol";
import "./Attendees.sol";

interface IGivingCircle is IAccessControl {

    function LEADER_ROLE() external view returns(bytes32);

    function initialize(Initialization.GivingCircleInitialization memory init) external;

    function registerAttendee(address addr) external;
    function registerAttendees(address[] memory addrs) external;
    function attendeeCount() external view returns(uint256);
    function getAttendees() external view returns(Attendees.Attendee[] memory);

    function createNewProposal(address payable giftRecipient) external;
    function proposalCount() external view returns(uint256);
    function getProposals() external view returns(Proposals.Proposal[] memory);

    function placeBeansForSomeone(address attendee, uint256 proposalIndex, uint256 beanQuantity) external;
    function placeMyBeans(uint256 proposalIndex, uint256 beanQuantity) external;
    function getAvailableBeans(address addr) external view returns(uint256);
    function getTotalBeansDispursed() external view returns(uint256);

    function ProgressToGiftRedeemPhase() external;
    function ProgressToBeanPlacementPhase() external;

    function redeemGiftForSomeone(address addr) external;
    function redeemMyGift() external;

    function getLeftoverFunds() external view returns(uint256);
    function getTotalRedeemedFunds() external view returns(uint256);
    function getTotalUnredeemedFunds() external view returns(uint256);
    function getTotalAllocatedFunds() external view returns (uint256);
}