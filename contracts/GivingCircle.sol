// ATXDAO Giving Circle by tlogs.eth via Crypto Learn Lab
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./partialIERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//can only redeem USDC if approved by an admin (aka Megan or multisig)

contract ATXDAOgivingCircle is AccessControl {

    struct GivingCircle {
        uint USDCperBean; // 
        address circleLeader; // set to current circleleader per utility variable when newCircle function is run.
        uint256 step;
        bool circleFunded;
        uint256 proposalCount;
        mapping (uint256 => Proposal) proposals;
    }

    struct Proposal {
        uint beansReceived;
        address payable giftAddress;
        bool kyced;
    }

    uint circleCount;
    mapping (uint256 => GivingCircle) givingCircles;
    mapping (address => uint) beanBalances; // beanBalances have decimals of 0. tracks outstanding votes from all circles attended.

    // bean events
    event BeansDisbursed(uint indexed circleNumb, address[] indexed circleattendees, uint indexed beansdisbursedforcircle); // emitted in disburseBeans
    event BeansPlaced(uint indexed propNumb, uint indexed beansplaced, address indexed beanplacer); // emitted in placeBeans

    // circle events
    event CircleCreated(uint indexed circleNumb); // emitted in newCircle
    event ProposalWindowClosed(uint indexed circleNumb, uint256 indexed proposalCount); // emitted in closePropWindow
    event VotingClosed(uint indexed circleNumb); // emitted in closeCircleVoting

    // proposal events
    event ProposalCreated(uint indexed propNumb, uint indexed circleNumb, address indexed giftrecipient); // emitted by proposeGift

    bytes32 public constant CIRCLE_LEADER_ROLE = keccak256("CIRCLE_LEADER_ROLE");

    constructor(address _usdc, address _circleLeader) {
        _grantRole(CIRCLE_LEADER_ROLE, _circleLeader);

        USDC = partialIERC20(_usdc); // set usdc contract address
        weiMultiplier = 10**18;  // set weiMultiplier to convert between ERC-20 decimal = 10**18 and decimal 0
        USDCperCircle = 1000; // set initial USDCperCircle. to be multiplied by weiMultiplier in all ERC20 calls
    }

    function createNewCircleAndOpenProposalWindow() public onlyRole(CIRCLE_LEADER_ROLE) {

        GivingCircle storage _theGivingCircle = givingCircles[circleCount];
        circleCount++;

        _theGivingCircle.USDCperBean = 0;
        _theGivingCircle.circleLeader = msg.sender;
        _theGivingCircle.step = 1;
        _theGivingCircle.circleFunded = false;
        _theGivingCircle.proposalCount = 0;
        
        emit CircleCreated(circleCount);
    }

    function closeProposalWindowAndDisburseBeans(uint256 _circleIndex, address[] memory attendees) public onlyRole(CIRCLE_LEADER_ROLE) {
        require(givingCircles[_circleIndex].step == 1, "circle needs to be in proposal creation phase.");

        emit ProposalWindowClosed(_circleIndex, givingCircles[_circleIndex].proposalCount);

        for (uint i = 0; i < attendees.length; i++) // for loop to allocate attendee addresses +10 beans
        beanBalances[attendees[i]] += 10; // change to beanBalances should be mirrored by totalbeans change below
        totalBeans += (10 * attendees.length); // affects USDCperBean.
        _calcUSDCperBean(_circleIndex); // make sure this is correct
        
        emit BeansDisbursed(_circleIndex,attendees, (10 * attendees.length));

        givingCircles[_circleIndex].step == 2;
    }


    function closeCircleVoting(uint256 _circleIndex) public onlyRole(CIRCLE_LEADER_ROLE) {
        require(givingCircles[_circleIndex].step == 2, "circle needs to be in bean placement phase");
        givingCircles[_circleIndex].step = 3;
        emit VotingClosed(_circleIndex);
    }

    function createNewProposal(uint256 circleIndex, address payable giftRecipient) public virtual returns (bool) {
        require(givingCircles[circleIndex].step == 1, "circle needs to be in proposal creation phase.");

        uint256 proposalIndex = givingCircles[circleIndex].proposalCount;
        Proposal storage newProposal = givingCircles[circleIndex].proposals[proposalIndex];
        newProposal.beansReceived = 0;
        newProposal.giftAddress = giftRecipient;
        newProposal.kyced = false;

        givingCircles[circleIndex].proposalCount++;

        emit ProposalCreated(proposalIndex, circleIndex, giftRecipient);
        return true;
    }

    function placeBeans(uint256 circleIndex, uint256 proposalIndex, uint256 beanQuantity) external {
        require (
            givingCircles[circleIndex].step == 2, "circle needs to be in bean placement phase."
        );
        require (
            beanBalances[msg.sender] >= beanQuantity, "not enough beans held to place beanqty"
        );

        beanBalances[msg.sender] -= beanQuantity;
        totalBeans -= beanQuantity;
        givingCircles[circleIndex].proposals[proposalIndex].beansReceived += beanQuantity;
        emit BeansPlaced(proposalIndex, beanQuantity, msg.sender);
    }

    // START UTILITY FUNCTIONS

    function getBeanBalance (address beanholder) external virtual returns (uint) {
        return beanBalances[beanholder];
    }

    function getCircleStep(uint256 circleIndex) public view returns(uint256) {
        return givingCircles[circleIndex].step;
    }

    // @tlogs: Returns the address of the circleLeader for a given circleNumber.
    // IMPLEMENT a version of the below which searchs array of circle numbers for all circles an address was circleLeader

    function getCircleLeaderForCircle(uint _circle) public view virtual returns (address) {
        return givingCircles[_circle].circleLeader;
    }

    // @tlogs: Check if a Giving Circle already exists at creation

    function doesCircleExists(uint circleIndex) public view returns (bool) {
        return circleIndex < circleCount;
    }

    // add a for loop so proposalWindowOpen can receive all proposalNumbers from a circle in uint[] array then check if any exist in proposalNumbers mapping

    function proposalWindowOpen (uint _checkcircle) public virtual returns (bool) {
        require (
            givingCircles[_checkcircle].step < 2, "Giving Circle is not open for proposal submission"
        );
        return true;
    }
    //END UTILITY FUNCTIONS

    //START USDC FUNDING CODE

    partialIERC20 public USDC; // implement USDC ERC20 interface with USDC contract address in constructor

    uint public weiMultiplier; // utilized in various calcs to convert to ERC20 decimals

    uint public totalUSDCgifted; // decimals = 0

    uint public totalUSDCpending; // decimals = 0

    uint public totalBeans; // decimals = 0

    uint[] public givingCircleIDs; // array of circle numbers utilized to check if giving cricle exists. array of all circle numbers

    uint public USDCperCircle; // initially 1000 USDC per circle. decmials = 0 (multiplied by weiMultiplier in all calcs)

    mapping (address => uint) public USDCgiftPending; // beanBalances have decimals of 10**18, always mirror changes in totalUSDCpending when changing mapping.
    mapping (address => uint) public USDCgiftsReceived; // tracks total gifts withdrawn by proposers, decimals = 0

    event FundedCircle(uint indexed circleNumb, uint256 amount); // emitted by proposeGift

    // gift events
    event GiftsAllocated(uint indexed circleNumb, address[] indexed giftrecipients, uint[] indexed giftamounts);  // emitted in _allocateGifts
    event GiftRedeemed(uint indexed giftwithdrawn, address indexed withdrawee);  // emitted in redeemGift

    function fundGiftForCircle(uint circleIndex) public payable onlyRole(CIRCLE_LEADER_ROLE) {
            require(
                givingCircles[circleIndex].circleFunded == false, "Circle has already been funded!"
            );

            require (
                USDC.balanceOf(msg.sender) >= (USDCperCircle * weiMultiplier), "not enough USDC to fund circle" // checks if circle leader has at least USDCperCircle 
            );

            USDC.approve(msg.sender, (USDCperCircle * weiMultiplier)); // insure approve increases circle leader allowance
            USDC.transferFrom(msg.sender, address(this), USDCperCircle * weiMultiplier); // transfer USDC to the contract

            givingCircles[circleIndex].circleFunded = true;
            emit FundedCircle(circleIndex, USDCperCircle * weiMultiplier);
    }

    function redeemGift(uint256 circleIndex, uint256 proposalIndex) external {
        require(
            givingCircles[circleIndex].step == 3, "circle needs to be in gift redeem phase"
        );
        require(
            givingCircles[circleIndex].proposals[proposalIndex].giftAddress == msg.sender, "This is not your gift!"
        );
        require(
            givingCircles[circleIndex].proposals[proposalIndex].kyced == true, "You need to be KYCed first!"
        );

        //not tested to work
        uint256 redemptionqty = USDCgiftPending[msg.sender]; // will be 10**18
        USDCgiftPending[msg.sender] = 0;
        address payable giftee = givingCircles[circleIndex].proposals[proposalIndex].giftAddress;
        totalUSDCpending -= redemptionqty / weiMultiplier; // reduce pending gifts by redeemed amount
        totalUSDCgifted += redemptionqty / weiMultiplier; // divide by weiMultiplier to give whole number totalUSDCgifted metric
        USDCgiftsReceived[msg.sender] += redemptionqty / weiMultiplier; // updates mapping to track total gifts withdrawn from contract
        USDC.transferFrom(address(this), giftee, redemptionqty); // USDCgiftPending mapping is 10**18, thus so is redemptionqty
        emit GiftRedeemed(redemptionqty, giftee);
    }

    // @tlogs: 
    //         USDCperBean is 10**18 
    //         thus allocate will be 10**18 
    //         thus USDCgiftPending mapping will be 10**18

    function _allocateGifts (uint circleIndex) internal virtual returns (bool) { 
            uint256 useUSDCperBean = givingCircles[circleIndex].USDCperBean;


            uint256 propCount = givingCircles[circleIndex].proposalCount;

            address[] memory giftees = new address[](propCount);
            uint[] memory allocations = new uint[](propCount);

        for (uint i = 0; i < propCount; i++) {
            uint256 allocate = givingCircles[circleIndex].proposals[i].beansReceived * useUSDCperBean; // beans received is decimal 0, USDCperBean is decimal 10**18, thus allocate is 10**18

            USDCgiftPending[givingCircles[circleIndex].proposals[i].giftAddress] += allocate; // utilizes 10**18
            totalUSDCpending += allocate / weiMultiplier; // ensure proper decimal usage here, desired is decimals = 0 

            giftees[i] = givingCircles[circleIndex].proposals[i].giftAddress;
    
            allocations[i] = allocate;
        }

            emit GiftsAllocated(circleIndex, giftees, allocations);

            return true;
    }

    // @tlogs: availableUSDC multiplies denominator by weiMultiplier to mitigate rounding errors due to uint

    function _calcUSDCperBean (uint256 circle_) internal virtual returns (uint) {
        uint256 availableUSDC = USDC.balanceOf(address(this)) - (totalUSDCpending * weiMultiplier); // availableUSDC is 10**18
        uint256 newusdcperbean = (availableUSDC) / totalBeans; // numberator is large due to weiMultipler, total beans is decimal = 0.
        givingCircles[circle_].USDCperBean = newusdcperbean;
        return newusdcperbean; // availableUSDC is 10**18, thus minimizing rounding with small totalBeans uint (not 10**18).
    }
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

    //event BeansRemoved(address indexed beanhorder, uint indexed beansremoved); // emitted in removeBeans

    //NOT SURE HOW WE PLAN TO USE THIS
    // @tlogs: cleanup function for circle leader to delete unallocated bean balances after a circle

    // function removeBeanBalances(address beanhorder) public returns (bool) {
    //     require(
    //        circleLeader == msg.sender, "only circle leader can remove bean balances"
    //     );  
    //     uint deletedbalance = beanBalances[beanhorder];
    //     delete beanBalances[beanhorder];
    //     emit BeansRemoved(beanhorder, deletedbalance);
    //     return true;
    // }

}