// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./partialIERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./KYCController.sol";

contract GivingCircle is AccessControl {

    struct Proposal {
        uint beansReceived;
        address payable giftAddress;
    }

    uint256 step;
    
    uint256 proposalCount;
    mapping (uint256 => Proposal) proposals;
    
    // uint256 erc20Allocated;
    uint256 totalAllocated;
    uint256 difference;
    uint erc20TokenPerBean;
    bool isFunded;

    uint256 beansToDispursePerAttendee;
    uint256 numOfBeans;
    mapping (address => uint256) attendeeBeanCount;
    
    uint256 attendeeCount;
    mapping (uint256 => address) attendees;

    bytes32 public constant CIRCLE_LEADER_ROLE = keccak256("CIRCLE_LEADER_ROLE");
    bytes32 public constant CIRCLE_ADMIN_ROLE = keccak256("CIRCLE_ADMIN_ROLE");

    partialIERC20 public erc20Token;
    KYCController public kycController;

    uint public totalUSDCgifted; // decimals = 0

    mapping (address => uint) public USDCgiftPending;
    mapping (address => uint) public USDCgiftsReceived; // tracks total gifts withdrawn by proposers, decimals = 0

    event ProposalCreated(uint indexed propNumb, address indexed giftrecipient);
    event BeansPlaced(uint indexed propNumb, uint indexed beansplaced, address indexed beanplacer); // emitted in placeBeans
    event GiftsAllocated();
    event VotingClosed();
    event GiftRedeemed(uint indexed giftwithdrawn, address indexed withdrawee);  // emitted in redeemGift
    event FundedCircle(uint256 amount); // emitted by proposeGift

    function initialize(address _circleLeader, address _circleAdmin, uint256 _beansToDispursePerAttendee, address _kycController) public {
        _grantRole(CIRCLE_LEADER_ROLE, _circleLeader);
        _grantRole(CIRCLE_ADMIN_ROLE, _circleAdmin);
        erc20Token = partialIERC20(erc20Token);
        kycController = KYCController(_kycController);

        erc20TokenPerBean = 0;
        step = 1;
        isFunded = false;
        proposalCount = 0;
        // erc20Allocated = erc20Amount;
        beansToDispursePerAttendee = _beansToDispursePerAttendee;
    }

    //Start Phase 1 Core Functions

    function createNewProposal(address payable giftRecipient) public onlyRole(CIRCLE_LEADER_ROLE) {
        require(step == 1, "circle needs to be in proposal creation phase.");

        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].giftAddress == giftRecipient) {
                revert("Recipient already present in proposal!");
            }
        }

        uint256 proposalIndex = proposalCount;
        Proposal storage newProposal = proposals[proposalIndex];
        newProposal.beansReceived = 0;
        newProposal.giftAddress = giftRecipient;

        proposalCount++;

        emit ProposalCreated(proposalIndex, giftRecipient);
    }

    //In current setup, allows for Megan or circle leader to mass add a list of arrays if they chose to gather them all beforehand
    //or at the event.
    function registerAttendeesToCircle(address[] memory addrs) public onlyRole(CIRCLE_LEADER_ROLE) {
        for (uint256 i = 0; i < addrs.length; i++) {
            registerAttendeeToCircle(addrs[i]);
        }
    }

    //In current setup, allows for an iPad to reach a server from a QR code scanned by a wallet. - More offhands approach
    function registerAttendeeToCircle(address addr) public onlyRole(CIRCLE_LEADER_ROLE) {
        require (
            step == 1 ||
            step == 2,
            "circle needs to be in the proposal creation or bean placement phases."
        );

        bool isPresent = false;
        for (uint256 i = 0; i < attendeeCount; i++) {
            if (addr == attendees[i]) {
                revert("Supplied address is already present in the number of attendees.");
            }
        }

        if (!isPresent) {
            numOfBeans += beansToDispursePerAttendee;
            attendeeBeanCount[addr] = beansToDispursePerAttendee;
            attendees[attendeeCount] = addr;
            attendeeCount++;
        }
    }

    function closeProposalWindowAndAttendeeRegistration() public onlyRole(CIRCLE_LEADER_ROLE) {
        require(step == 1, "circle needs to be in proposal creation phase.");
        step = 2;
    }

    //End Phase 1 Core Functions

    //Start Phase 2 Core Functions
    function placeBeans(uint256 proposalIndex, uint256 beanQuantity) external {
        require (
            step == 2, "circle needs to be in bean placement phase."
        );

        require(attendeeBeanCount[msg.sender] >= beanQuantity, "not enough beans held to place bean quantity.");

        attendeeBeanCount[msg.sender] -= beanQuantity;
        proposals[proposalIndex].beansReceived += beanQuantity;
        emit BeansPlaced(proposalIndex, beanQuantity, msg.sender);
    }

    function closeCircleVoting() public onlyRole(CIRCLE_LEADER_ROLE) {
        require(step == 2, "circle needs to be in bean placement phase");
        require(isFunded == true, "Circle needs to be funded first!");

        step = 3;

        _calcErc20TokenPerBean();
        _allocateGifts();
        emit VotingClosed();
    }

    //Start Phase 2 Internal Functions

    function _calcErc20TokenPerBean () internal virtual returns (uint) {
        uint256 availableUSDC = erc20Token.balanceOf(address(this));
        uint256 newerc20TokenPerBean = (availableUSDC) / numOfBeans;
        
        erc20TokenPerBean = newerc20TokenPerBean;
        return newerc20TokenPerBean;
    }

    function _allocateGifts () internal { 

        for (uint i = 0; i < proposalCount; i++) {
            uint256 allocate = proposals[i].beansReceived * erc20TokenPerBean; // beans received is decimal 0, erc20TokenPerBean is decimal 10**18, thus allocate is 10**18

            USDCgiftPending[proposals[i].giftAddress] += allocate; // utilizes 10**18
            totalAllocated += allocate;
            difference = erc20Token.balanceOf(address(this)) - totalAllocated;
        }

        emit GiftsAllocated();
    }

    //End Phase 2 Internal Functions

    //Start Phase 3 Core Functions

    function fundGiftForCircle(uint256 amount) public payable onlyRole(CIRCLE_ADMIN_ROLE) {
            require(
                isFunded == false, "Circle has already been funded!"
            );

            require (
                erc20Token.balanceOf(msg.sender) >= amount, "not enough USDC to fund circle" // checks if circle leader has at least USDCperCircle 
            );

            erc20Token.transferFrom(msg.sender, address(this), amount); // transfer USDC to the contract

            //determine whether admin can fund in chunks
            // IF (USDC.balanceOf(adress(this) => ))
            isFunded = true;

            // uint256 amount = 
            emit FundedCircle(erc20Token.balanceOf(address(this)));
    }

    
    function redeemGift(uint256 proposalIndex) external {
        require(
            step == 3, "circle needs to be in gift redeem phase"
        );
        require(
            proposals[proposalIndex].giftAddress == msg.sender, "This is not your gift!"
        );
        require(
            kycController.isUserKyced(msg.sender), "You need to be KYCed first!"
        );

        //not tested to work
        uint256 redemptionqty = USDCgiftPending[msg.sender]; // will be 10**18
        USDCgiftPending[msg.sender] = 0;
        address payable giftee = proposals[proposalIndex].giftAddress;
        //I think this line can get deleted. would like your confirmation.
        // totalUSDCpending -= redemptionqty / weiMultiplier; // reduce pending gifts by redeemed amount
        
        totalUSDCgifted += redemptionqty;
        // totalUSDCgifted += redemptionqty / weiMultiplier; // divide by weiMultiplier to give whole number totalUSDCgifted metric
        USDCgiftsReceived[msg.sender] += redemptionqty;
        // USDCgiftsReceived[msg.sender] += redemptionqty / weiMultiplier; // updates mapping to track total gifts withdrawn from contract

        erc20Token.approve(address(this), redemptionqty);
        erc20Token.transferFrom(address(this), giftee, redemptionqty); // USDCgiftPending mapping is 10**18, thus so is redemptionqty
        emit GiftRedeemed(redemptionqty, giftee);
    }

    //End Phase 3 Core Functions
}