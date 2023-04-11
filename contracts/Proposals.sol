// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Proposals {
    struct Proposal {
        address payable proposer;
        string name;
        string contributions;
        uint beansReceived;
        uint256 giftAmount;
        bool hasRedeemed;
    }
}