// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./Initialization.sol";
import "./Proposals.sol";
import "./Attendees.sol";

interface IGivingCircle is IAccessControl {
    function initialize(Initialization.GivingCircleInitialization memory init) external;

    function createNewProposal(address payable giftRecipient) external;
    function registerAttendee(address addr) external;
    function registerAttendees(address[] memory addrs) external;

    function attendeeCount() external view returns(uint256);
    function getAttendees() external view returns(Attendees.Attendee[] memory);

    function LEADER_ROLE() external view returns(bytes32);

    function ProgressToBeanPlacementPhase() external;

    function proposalCount() external view returns(uint256);
    function getProposals() external view returns(Proposals.Proposal[] memory);

    function getAvailableBeans(address addr) external view returns(uint256);

    function placeBeansForSomeone(address attendee, uint256 proposalIndex, uint256 beanQuantity) external;
    function placeMyBeans(uint256 proposalIndex, uint256 beanQuantity) external;

    function ProgressToGiftRedeemPhase() external;

    function redeemGiftForSomeone(address addr) external;
    function redeemMyGift() external;

    function getLeftoverFunds() external view returns(uint256);

}