// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Proposals {
    struct Proposal {
        uint beansReceived;
        uint256 giftAmount;
        bool hasRedeemed;
        address payable proposer;
    }
}