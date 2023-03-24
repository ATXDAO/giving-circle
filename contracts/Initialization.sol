// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Initialization {
    struct GivingCircleInitialization {
        uint256 beansToDispursePerAttendee;
        uint256 fundingThreshold;
        address[] circleLeaders;
        address[] beanPlacementAdmins;
        address[] fundsManagers;
        address erc20Token;
        address kycController;
    }
}