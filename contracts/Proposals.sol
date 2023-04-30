// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Proposals {
    struct Proposal {
        Contributor contributor;
        uint beansReceived;
    }

    struct Contributor {
        address payable addr;
        string name;
        string contributions;
        uint256 fundsAllocated;
        bool hasRedeemed;
    }
}