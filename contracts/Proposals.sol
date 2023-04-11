// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Proposals {
    struct Proposal {
        address payable contributor;
        string contributorName;
        string contributions;
        uint beansReceived;
        uint256 giftAmount;
        bool hasRedeemed;
    }
}