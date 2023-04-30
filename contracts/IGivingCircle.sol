// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./Initialization.sol";
import "./Proposals.sol";
import "./Attendees.sol";

interface IGivingCircle is IAccessControl {

    function LEADER_ROLE() external view returns(bytes32);
    function FUNDS_MANAGER_ROLE() external view returns(bytes32);
    function BEAN_PLACEMENT_ADMIN_ROLE() external view returns(bytes32);
    
    enum Phase
    {
        UNINITIALIZED, //Contract is not initialized. Cannot begin circle until no longer uninitalized.
        PROPOSAL_CREATION, //Register attendees, fund gifts, create new proposals, and progress phase to bean placement.
        BEAN_PLACEMENT, //Register attendees, fund gifts, place beans, and progress phase to gift redeem.
        GIFT_REDEEM //Redeem gifts. Rollover leftover funds to a different circle.
    }
    
    function initialize(Initialization.GivingCircleInitialization memory init) external;

    function registerAttendee(address addr) external;
    function registerAttendees(address[] memory addrs) external;
    function attendeeCount() external view returns(uint256);
    function getAttendees() external view returns(Attendees.Attendee[] memory);

    function batchCreateNewProposals(Proposals.Contributor[] memory newContributors) external;
    function createNewProposal(Proposals.Contributor memory newContributor) external;
    function createNewProposalForMe(Proposals.Contributor memory newContributor) external;
    
    function proposalCount() external view returns(uint256);
    function getProposals() external view returns(Proposals.Proposal[] memory);

    function placeBeansForSomeone(address attendee, uint256 proposalIndex, uint256 beanQuantity) external;
    function placeMyBeans(uint256 proposalIndex, uint256 beanQuantity) external;
    function getAvailableBeans(address addr) external view returns(uint256);
    function getTotalBeansDispursed() external view returns(uint256);

    function ProgressToBeanPlacementPhase() external;
    function ProgressToFundsRedemptionPhase() external;

    function redeemFundsForSomeone(address addr) external;
    function redeemMyFunds() external;

    function getLeftoverFunds() external view returns(uint256);
    function getTotalRedeemedFunds() external view returns(uint256);
    function getTotalUnredeemedFunds() external view returns(uint256);
    function getTotalAllocatedFunds() external view returns (uint256);
}