// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Initialization {
    struct GivingCircleInitialization {
        uint256 beansToDispursePerAttendee;
        uint256 fundingThreshold;
        address[] circleLeaders;
        address[] specialBeanPlacers;
        address[] specialGiftRedeemers;
        address erc20Token;
        address kycController;
    }
}