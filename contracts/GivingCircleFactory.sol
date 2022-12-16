// ATXDAO Giving Circle by tlogs.eth via Crypto Learn Lab
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./partialIERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./KYCController.sol";

//README README README README README README 
//From my current understanding...the current implementation works all the way through perfectly or near perfectly.
//I am able to go through the entire process with expected behaviour all the way to proposal's gift recipient ending up
//with an amount of ERC20 by the end! The main concern is the weiMultiplier. I removed it from the implementation as
//I was funding through the javascript, 1000 USDC. However, when dealing in the smart contract (the weiMultiplier),
//the numbers weren't adding up correctly. Hoping we can go over this. The code using weiMultiplier should still be there
//but is currently commented out.

//functions callable during phase 0:
//createNewCircleAndOpenProposalWindow() -- leader
//functions callable during phase 1:
//closeProposalWindowAndAttendeeRegistration() -- leader
//createNewProposal() -- leader
//registerAttendeeToCircle() -- leader
//functions callable during phase 2:
//closeCircleVoting() -- leader
//placeBeans() -- attendee

//can only redeem USDC if approved by an admin (aka Megan or multisig)

contract GivingCircleFactory is AccessControl {

    KYCController kycToReference;

    function setImplementation(address addr) public onlyRole(CIRCLE_ADMIN_ROLE) {
        kycToReference = KYCController(addr);
    }

    function initialize() public {
        // new GivingCircle(0,0,0,0,0, kycToReference);
    }


    struct GivingCircle {
        uint256 step;
        
        uint256 proposalCount;
        mapping (uint256 => Proposal) proposals;
        
        uint256 erc20Allocated;
        uint256 totalAllocated;
        uint256 difference;
        uint USDCperBean;
        bool isFunded;

        uint256 beansToDispursePerAttendee;
        uint256 numOfBeans;
        mapping (address => uint256) attendeeBeanCount;
        
        uint256 attendeeCount;
        mapping (uint256 => address) attendees;
    }

    struct Proposal {
        uint beansReceived;
        address payable giftAddress;
        // bool kyced;
    }

    uint256 public circleCount;
    mapping (uint256 => GivingCircle) givingCircles;

    mapping (address => bool) isKYCed; // must be set to true in order for redemptions

    partialIERC20 public USDC; // implement USDC ERC20 interface with USDC contract address in constructor

    //I am certain this won't get removed but may be required for some currencies. Currently works without using it using
    //a token with 18 decimal places

    // uint public weiMultiplier; // utilized in various calcs to convert to ERC20 decimals

    uint public totalUSDCgifted; // decimals = 0

    // uint public totalUSDCpending; // decimals = 0

    //I think this can get removed. would like your confirmation first.
    // uint public USDCperCircle; // initially 1000 USDC per circle. decmials = 0 (multiplied by weiMultiplier in all calcs)

    mapping (address => uint) public USDCgiftPending; // beanBalances have decimals of 10**18, always mirror changes in totalUSDCpending when changing mapping.
    mapping (address => uint) public USDCgiftsReceived; // tracks total gifts withdrawn by proposers, decimals = 0

    // bean events
    event BeansPlaced(uint indexed propNumb, uint indexed beansplaced, address indexed beanplacer); // emitted in placeBeans

    // circle events
    event CircleCreated(uint indexed circleNumb); // emitted in newCircle
    event VotingClosed(uint indexed circleNumb); // emitted in closeCircleVoting

    // proposal events
    event ProposalCreated(uint indexed propNumb, uint indexed circleNumb, address indexed giftrecipient); // emitted by proposeGift

    event FundedCircle(uint indexed circleNumb, uint256 amount); // emitted by proposeGift
    // gift events
    event GiftsAllocated(uint indexed circleNumb);  // emitted in _allocateGifts
    // event GiftsAllocated(uint indexed circleNumb, address[] indexed giftrecipients, uint[] indexed giftamounts);  // emitted in _allocateGifts
    event GiftRedeemed(uint indexed giftwithdrawn, address indexed withdrawee);  // emitted in redeemGift

    bytes32 public constant CIRCLE_LEADER_ROLE = keccak256("CIRCLE_LEADER_ROLE");
    bytes32 public constant CIRCLE_ADMIN_ROLE = keccak256("CIRCLE_ADMIN_ROLE");

    constructor(address _usdc, address _circleLeader, address _circleAdmin) {
        _grantRole(CIRCLE_LEADER_ROLE, _circleLeader);
        _grantRole(CIRCLE_ADMIN_ROLE, _circleAdmin);

        USDC = partialIERC20(_usdc); // set usdc contract address
        // weiMultiplier = 10**18;  // set weiMultiplier to convert between ERC-20 decimal = 10**18 and decimal 0
        
        //i think this can get removed. would like your confirmation first.
        // USDCperCircle = 1000; // set initial USDCperCircle. to be multiplied by weiMultiplier in all ERC20 calls
    }
    
    //Start Phase 0 Core Functions
    function createNewCircleAndOpenProposalWindowAndAttendeeRegistration(uint256 erc20Amount, uint256 _beansToDispursePerAttendee) public onlyRole(CIRCLE_LEADER_ROLE) {

        GivingCircle storage _theGivingCircle = givingCircles[circleCount];
        circleCount++;

        _theGivingCircle.USDCperBean = 0;
        _theGivingCircle.step = 1;
        _theGivingCircle.isFunded = false;
        _theGivingCircle.proposalCount = 0;
        _theGivingCircle.erc20Allocated = erc20Amount;
        _theGivingCircle.beansToDispursePerAttendee = _beansToDispursePerAttendee;
        emit CircleCreated(circleCount);
    }
    //End Phase 0 Core Functions

    //Start Phase 1 Core Functions
    function createNewProposal(uint256 circleIndex, address payable giftRecipient) public onlyRole(CIRCLE_LEADER_ROLE) {
        require(givingCircles[circleIndex].step == 1, "circle needs to be in proposal creation phase.");

        for (uint256 i = 0; i < givingCircles[circleIndex].proposalCount; i++) {
            if (givingCircles[circleIndex].proposals[i].giftAddress == giftRecipient) {
                revert("Recipient already present in proposal!");
            }
        }

        uint256 proposalIndex = givingCircles[circleIndex].proposalCount;
        Proposal storage newProposal = givingCircles[circleIndex].proposals[proposalIndex];
        newProposal.beansReceived = 0;
        newProposal.giftAddress = giftRecipient;

        givingCircles[circleIndex].proposalCount++;

        emit ProposalCreated(proposalIndex, circleIndex, giftRecipient);
    }

    //In current setup, allows for Megan or circle leader to mass add a list of arrays if they chose to gather them all beforehand
    //or at the event.
    function registerAttendeesToCircle(uint256 circleIndex, address[] memory addrs) public onlyRole(CIRCLE_LEADER_ROLE) {
        for (uint256 i = 0; i < addrs.length; i++) {
            registerAttendeeToCircle(circleIndex, addrs[i]);
        }
    }

    //In current setup, allows for an iPad to reach a server from a QR code scanned by a wallet. - More offhands approach
    function registerAttendeeToCircle(uint256 circleIndex, address addr) public onlyRole(CIRCLE_LEADER_ROLE) {
        require (
            givingCircles[circleIndex].step == 1 ||
            givingCircles[circleIndex].step == 2,
            "circle needs to be in the proposal creation or bean placement phases."
        );

        bool isPresent = false;
        for (uint256 i = 0; i < givingCircles[circleIndex].attendeeCount; i++) {
            if (addr == givingCircles[circleIndex].attendees[i]) {
                revert("Supplied address is already present in the number of attendees.");
            }
        }

        if (!isPresent) {
            givingCircles[circleIndex].numOfBeans += givingCircles[circleIndex].beansToDispursePerAttendee;
            givingCircles[circleIndex].attendeeBeanCount[addr] = givingCircles[circleIndex].beansToDispursePerAttendee;
            givingCircles[circleIndex].attendees[givingCircles[circleIndex].attendeeCount] = addr;
            givingCircles[circleIndex].attendeeCount++;
        }
    }

    function closeProposalWindowAndAttendeeRegistration(uint256 _circleIndex) public onlyRole(CIRCLE_LEADER_ROLE) {
        require(givingCircles[_circleIndex].step == 1, "circle needs to be in proposal creation phase.");
        givingCircles[_circleIndex].step = 2;
    }

    //End Phase 1 Core Functions

    //Start Phase 2 Core Functions

    function placeBeans(uint256 circleIndex, uint256 proposalIndex, uint256 beanQuantity) external {
        require (
            givingCircles[circleIndex].step == 2, "circle needs to be in bean placement phase."
        );

        require(givingCircles[circleIndex].attendeeBeanCount[msg.sender] >= beanQuantity, "not enough beans held to place bean quantity.");

        givingCircles[circleIndex].attendeeBeanCount[msg.sender] -= beanQuantity;
        givingCircles[circleIndex].proposals[proposalIndex].beansReceived += beanQuantity;
        emit BeansPlaced(proposalIndex, beanQuantity, msg.sender);
    }

    function closeCircleVoting(uint256 _circleIndex) public onlyRole(CIRCLE_LEADER_ROLE) {
        require(givingCircles[_circleIndex].step == 2, "circle needs to be in bean placement phase");
        require(
            givingCircles[_circleIndex].isFunded == true, "Circle needs to be funded first!"
        );

        givingCircles[_circleIndex].step = 3;

        _calcUSDCperBean(_circleIndex);
        _allocateGifts(_circleIndex);
        emit VotingClosed(_circleIndex);
    }

    //Start Phase 2 Internal Functions

    function _calcUSDCperBean (uint256 circle_) internal virtual returns (uint) {
        // uint256 availableUSDC = givingCircles[circle_].erc20Allocated; // availableUSDC is 10**18
        uint256 availableUSDC = givingCircles[circle_].erc20Allocated; // availableUSDC is 10**18
        uint256 newusdcperbean = (availableUSDC) / givingCircles[circle_].numOfBeans; // numberator is large due to weiMultipler, total beans is decimal = 0.
        
        // if (availableUSDC > 1000) {
        //     revert("more than 1k");
        // }

        
        givingCircles[circle_].USDCperBean = newusdcperbean;
        return newusdcperbean; // availableUSDC is 10**18, thus minimizing rounding with small totalBeans uint (not 10**18).
    }

    function _allocateGifts (uint circleIndex) internal virtual returns (bool) { 
            uint256 useUSDCperBean = givingCircles[circleIndex].USDCperBean;


            uint256 propCount = givingCircles[circleIndex].proposalCount;

            // address[] memory giftees = new address[](propCount);
            // uint[] memory allocations = new uint[](propCount);

        for (uint i = 0; i < propCount; i++) {
            uint256 allocate = givingCircles[circleIndex].proposals[i].beansReceived * useUSDCperBean; // beans received is decimal 0, USDCperBean is decimal 10**18, thus allocate is 10**18

            USDCgiftPending[givingCircles[circleIndex].proposals[i].giftAddress] += allocate; // utilizes 10**18
            //I think this line can get deleted. would like your confirmation.
            // totalUSDCpending += allocate / weiMultiplier; // ensure proper decimal usage here, desired is decimals = 0 

            // giftees[i] = givingCircles[circleIndex].proposals[i].giftAddress;
            // allocations[i] = allocate;

            givingCircles[circleIndex].totalAllocated += allocate;
            // givingCircles[circleIndex].totalAllocated += allocate / weiMultiplier;
            givingCircles[circleIndex].difference = givingCircles[circleIndex].erc20Allocated - givingCircles[circleIndex].totalAllocated;
        }

            emit GiftsAllocated(circleIndex);
            // emit GiftsAllocated(circleIndex, giftees, allocations);
            return true;
    }

    //End Phase 2 Internal Functions
    //End Phase 2 Core Functions

    //Start Phase 3 Core Functions

    //I think we still need to determine when this happens right and which steps are required for this to be completed?
    function fundGiftForCircle(uint circleIndex) public payable onlyRole(CIRCLE_ADMIN_ROLE) {
            require(
                givingCircles[circleIndex].isFunded == false, "Circle has already been funded!"
            );

            require (
                USDC.balanceOf(msg.sender) >= (givingCircles[circleIndex].erc20Allocated), "not enough USDC to fund circle" // checks if circle leader has at least USDCperCircle 
                // USDC.balanceOf(msg.sender) >= (givingCircles[circleIndex].erc20Allocated * weiMultiplier), "not enough USDC to fund circle" // checks if circle leader has at least USDCperCircle 
            );

            USDC.transferFrom(msg.sender, address(this), givingCircles[circleIndex].erc20Allocated); // transfer USDC to the contract
            // USDC.transferFrom(msg.sender, address(this), givingCircles[circleIndex].erc20Allocated * weiMultiplier); // transfer USDC to the contract

            //determine whether admin can fund in chunks
            // IF (USDC.balanceOf(adress(this) => ))
            givingCircles[circleIndex].isFunded = true;
            emit FundedCircle(circleIndex, givingCircles[circleIndex].erc20Allocated);
            // emit FundedCircle(circleIndex, givingCircles[circleIndex].erc20Allocated * weiMultiplier);
    }

    
    function redeemGift(uint256 circleIndex, uint256 proposalIndex) external {
        require(
            givingCircles[circleIndex].step == 3, "circle needs to be in gift redeem phase"
        );
        require(
            givingCircles[circleIndex].proposals[proposalIndex].giftAddress == msg.sender, "This is not your gift!"
        );
        require(
            isKYCed[msg.sender], "You need to be KYCed first!"
        );

        //not tested to work
        uint256 redemptionqty = USDCgiftPending[msg.sender]; // will be 10**18
        USDCgiftPending[msg.sender] = 0;
        address payable giftee = givingCircles[circleIndex].proposals[proposalIndex].giftAddress;
        //I think this line can get deleted. would like your confirmation.
        // totalUSDCpending -= redemptionqty / weiMultiplier; // reduce pending gifts by redeemed amount
        
        totalUSDCgifted += redemptionqty;
        // totalUSDCgifted += redemptionqty / weiMultiplier; // divide by weiMultiplier to give whole number totalUSDCgifted metric
        USDCgiftsReceived[msg.sender] += redemptionqty;
        // USDCgiftsReceived[msg.sender] += redemptionqty / weiMultiplier; // updates mapping to track total gifts withdrawn from contract

        USDC.approve(address(this), redemptionqty);
        USDC.transferFrom(address(this), giftee, redemptionqty); // USDCgiftPending mapping is 10**18, thus so is redemptionqty
        emit GiftRedeemed(redemptionqty, giftee);
    }

    function rollOverToIndex(uint256 startCircleIndex, uint256 endCircleIndex) public onlyRole(CIRCLE_LEADER_ROLE) {
        givingCircles[endCircleIndex].erc20Allocated += givingCircles[startCircleIndex].difference;
        givingCircles[startCircleIndex].difference = 0;
    }
    
    //End Phase 3 Core Functions

    // START UTILITY FUNCTIONS

    function getCircleStep(uint256 circleIndex) public view returns(uint256) {
        return givingCircles[circleIndex].step;
    }

    function isCreatingProposals(uint _checkcircle) public virtual returns (bool) {
        require (
            givingCircles[_checkcircle].step == 1, "Giving Circle is not open for proposal submission"
        );
        return true;
    }

    function isPlacingBeans(uint _checkcircle) public virtual returns (bool) {
        require (
            givingCircles[_checkcircle].step == 2, "Giving Circle is not open for bean placements."
        );
        return true;
    }

    function isGiftRedeeming(uint _checkcircle) public virtual returns (bool) {
        require (
            givingCircles[_checkcircle].step == 3, "Giving Circle is not open gift redeeming."
        );
        return true;
    }
    
    function getAttendeeAmountInCircle(uint256 circle) public view returns(uint256) {
        return givingCircles[circle].attendeeCount;
    }

    function getAttendeesInCircle(uint256 circleIndex) public view returns(address[] memory) {

        address[] memory arr = new address[](givingCircles[circleIndex].attendeeCount);

        for (uint256 i = 0; i < givingCircles[circleIndex].attendeeCount; i++) {
            arr[i] = givingCircles[circleIndex].attendees[i];
        }

        return arr;
    }

    function getProposalCountInCircle(uint256 circleIndex) public view returns(uint256) {
        return givingCircles[circleIndex].proposalCount;
    }

    function getBeanCountInCircleFromSender(uint256 circleIndex) public view returns(uint256) {
        return getBeanCountInCircle(circleIndex, msg.sender);
    }

    function getBeanCountInCircle(uint256 circleIndex, address addr) public view returns(uint256) {
        return givingCircles[circleIndex].attendeeBeanCount[addr];
    }

    function kycUser(address kycAddress) external onlyRole(CIRCLE_ADMIN_ROLE) {
        isKYCed[kycAddress] = true;
    }

    //END UTILITY FUNCTIONS

    //START USDC FUNDING CODE



    


    

    // @tlogs: 
    //         USDCperBean is 10**18 
    //         thus allocate will be 10**18 
    //         thus USDCgiftPending mapping will be 10**18

    
    //END USDC FUNDING CODE



    // START EXPLAIN DESIRE TO HAVE THIS

    //uint[] public checkforProp; // array or prop numbers for various 'for' loops
    //mapping (uint => Proposal) public proposalNumbers; // give each proposal a number. uint replicated in checkforProp array.

    // @tlogs: will return total USDC gifts withdrawn in decimal=0 in addition to an array of all props submitted

    // function getgiftrecords (address recipient) public returns (uint totalgifted, uint[] memory propssubmitted, uint[] memory USDCallocs) {
    //     uint[] memory propsposted = new uint[](checkforProp.length);
    //     uint[] memory votes = new uint[](checkforProp.length);
    //     uint recipientGifts = USDCgiftPending[recipient];
    // for (uint i = 0; i < checkforProp.length; i++) {
    //     if (proposalNumbers[checkforProp[i]].giftAddress == recipient) {        // checks for props where address is gift recipient
    //         propsposted[i] = checkforProp[i];
    //         votes[i] = proposalNumbers[i].beansReceived * givingCircles[returnCircleforProp(i)].USDCperBean;
    //         // insert call for circle's USDC per bean and move the
    //         }
    // }
    //     return (recipientGifts, propsposted, votes);   
    // }

    //DOES NOT WORK NOW AS CIRCLES AND PROPS ARE STORED BY MAPPINGS

    // mapping (uint => uint) proposalincircle; // proposal number > circle number, one-to-one, check which proposal a circle is in for USDCperBean lookup

    // quickly determine which circle a proposal is in for getgiftrecords calcs needing each circle's unique USDCperBean

    // function returnCircleforProp (uint prop) public virtual returns (uint circle) {
    //     return proposalincircle[prop];
    // }

    // END EXPLAIN DESIRE TO HAVE THIS
}