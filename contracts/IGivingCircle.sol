// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGivingCircle {
    function initialize(address _circleLeader, address _circleAdmin, uint256 _beansToDispursePerAttendee, address _kycController, address _erc20Token) external;
    function createNewProposal(address payable giftRecipient) external;
    function registerAttendee(address addr) external;
    function registerAttendees(address[] memory addrs) external;

    function attendeeCount() external view returns(uint256);
}