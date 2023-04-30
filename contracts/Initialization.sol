// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Initialization {
    struct GivingCircleInitialization {
        string name;
        uint256 beansToDispursePerAttendee;
        uint256 fundingThreshold;
        address[] admins;
        address[] circleLeaders;
        address[] beanPlacementAdmins;
        address[] fundsManagers;
        address erc20Token;
        address kycController;
    }
}