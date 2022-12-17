// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./partialIERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./KYCController.sol";
import "./IGivingCircle.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract GivingCircle is IGivingCircle, AccessControl, Initializable {

    bytes32 public constant LEADER_ROLE = keccak256("LEADER_ROLE");
    bytes32 public constant FUNDER_ROLE = keccak256("FUNDER_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    enum Phase 
    {
        UNINITIALIZED, //Contract is not initialized. Cannot begin circle until no longer uninitalized.
        PROPOSAL_CREATION, //Register attendees, fund gifts, create new proposals, and progress phase to bean placement.
        BEAN_PLACEMENT, //Register attendees, fund gifts, place beans, and progress phase to gift redeem.
        GIFT_REDEEM //Redeem gifts.
    }
    Phase public phase;

    struct Proposal {
        uint beansReceived;
        uint256 giftAmount;
        bool hasRedeemed;
        address payable giftAddress;
    }

    uint256 public proposalCount;
    mapping (uint256 => Proposal) public proposals;
    
    uint256 public unallocatedFunds;

    uint public erc20TokenPerBean;
    bool public isFunded;

    uint256 public beansToDispursePerAttendee;
    uint256 public numOfBeans;
    mapping (address => uint256) public attendeeBeanCount;
    
    uint256 public attendeeCount;
    mapping (uint256 => address) public attendees;

    partialIERC20 public erc20Token;
    KYCController public kycController;

    event ProposalCreated(uint indexed propNumb, address indexed giftrecipient);
    event BeansPlaced(uint indexed propNumb, uint indexed beansplaced, address indexed beanplacer); // emitted in placeBeans
    event GiftsAllocated();
    event VotingClosed();
    event GiftRedeemed(uint indexed giftwithdrawn, address indexed withdrawee);  // emitted in redeemGift
    event FundedCircle(uint256 amount); // emitted by proposeGift

    constructor(address _circleLeader, address _funder, uint256 _beansToDispursePerAttendee, address _kycController, address _erc20Token) {
        initialize(_circleLeader, _funder, _beansToDispursePerAttendee, _kycController, _erc20Token);
    }

    function initialize(address _circleLeader, address _funder, uint256 _beansToDispursePerAttendee, address _kycController, address _erc20Token) public initializer {
        
        _grantRole(LEADER_ROLE, _circleLeader);
        _grantRole(FUNDER_ROLE, _funder);
        erc20Token = partialIERC20(_erc20Token);
        kycController = KYCController(_kycController);

        attendeeCount = 0;
        erc20TokenPerBean = 0;
        phase = Phase.PROPOSAL_CREATION;
        isFunded = false;
        proposalCount = 0;
        beansToDispursePerAttendee = _beansToDispursePerAttendee;
    }

    //Start Phase 1 Core Functions

    function createNewProposal(address payable giftRecipient) public onlyRole(LEADER_ROLE) {
        require(phase == Phase.PROPOSAL_CREATION, "circle needs to be in proposal creation phase.");

        require(!hasRole(PROPOSER_ROLE, giftRecipient), "Recipient already present in proposal!");

        _grantRole(PROPOSER_ROLE, giftRecipient);

        uint256 proposalIndex = proposalCount;
        Proposal storage newProposal = proposals[proposalIndex];
        newProposal.beansReceived = 0;
        newProposal.giftAddress = giftRecipient;

        proposalCount++;

        emit ProposalCreated(proposalIndex, giftRecipient);
    }

    //In current setup, allows for Megan or circle leader to mass add a list of arrays if they chose to gather them all beforehand
    //or at the event.
    function registerAttendees(address[] memory addrs) public onlyRole(LEADER_ROLE) {
        for (uint256 i = 0; i < addrs.length; i++) {
            registerAttendee(addrs[i]);
        }
    }

    //In current setup, allows for an iPad to reach a server from a QR code scanned by a wallet. - More offhands approach
    function registerAttendee(address addr) public onlyRole(LEADER_ROLE) {
        require (
            phase == Phase.PROPOSAL_CREATION ||
            phase == Phase.BEAN_PLACEMENT,
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

    function ProgressToBeanPlacementPhase() public onlyRole(LEADER_ROLE) {
        require(phase == Phase.PROPOSAL_CREATION, "circle needs to be in proposal creation phase.");
        phase = Phase.BEAN_PLACEMENT;
    }

    //End Phase 1 Core Functions

    //Start Phase 2 Core Functions
    function placeBeans(uint256 proposalIndex, uint256 beanQuantity) external {
        require (
            phase == Phase.BEAN_PLACEMENT, "circle needs to be in bean placement phase."
        );

        require(attendeeBeanCount[msg.sender] >= beanQuantity, "not enough beans held to place bean quantity.");

        attendeeBeanCount[msg.sender] -= beanQuantity;
        proposals[proposalIndex].beansReceived += beanQuantity;
        emit BeansPlaced(proposalIndex, beanQuantity, msg.sender);
    }

    function ProgressToGiftRedeemPhase() public onlyRole(LEADER_ROLE) {
        require(phase == Phase.BEAN_PLACEMENT, "circle needs to be in bean placement phase");
        require(isFunded == true, "Circle needs to be funded first!");

        _calcErc20TokenPerBean();
        _allocateGifts();

        phase = Phase.GIFT_REDEEM;
        emit VotingClosed();
    }

    function fundGift(uint256 amount) public payable onlyRole(FUNDER_ROLE) {
        require(
            isFunded == false, "Circle has already been funded!"
        );

        require (
            erc20Token.balanceOf(msg.sender) >= amount, "not enough USDC to fund circle"
        );

        erc20Token.transferFrom(msg.sender, address(this), amount); // transfer USDC to the contract

        isFunded = true;

        emit FundedCircle(erc20Token.balanceOf(address(this)));
    }

    //Start Phase 2 Internal Functions

    function _calcErc20TokenPerBean () internal virtual returns (uint) {
        uint256 availableUSDC = erc20Token.balanceOf(address(this));
        uint256 newerc20TokenPerBean = (availableUSDC) / numOfBeans;
        
        erc20TokenPerBean = newerc20TokenPerBean;
        return newerc20TokenPerBean;
    }

    function _allocateGifts () internal { 

        uint256 totalAllocated;
        for (uint i = 0; i < proposalCount; i++) {
            uint256 amountToAllocate = proposals[i].beansReceived * erc20TokenPerBean;
            proposals[i].giftAmount = amountToAllocate;
            totalAllocated += amountToAllocate;
        }

        unallocatedFunds = erc20Token.balanceOf(address(this)) - totalAllocated;

        emit GiftsAllocated();
    }

    //End Phase 2 Internal Functions

    //Start Phase 3 Core Functions    

    function redeemMyGift() external onlyRole(PROPOSER_ROLE) {
        require(
            phase == Phase.GIFT_REDEEM, "circle needs to be in gift redeem phase"
        );

        require(kycController.isUserKyced(msg.sender), "You need to be KYCed first!");

        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].giftAddress == msg.sender) {
                
                require(!proposals[i].hasRedeemed, "You already redeemed your gift!");

                erc20Token.approve(address(this), proposals[i].giftAmount);
                erc20Token.transferFrom(address(this), proposals[i].giftAddress, proposals[i].giftAmount); // USDCgiftPending mapping is 10**18, thus so is redemptionqty
                proposals[i].hasRedeemed = true;
                emit GiftRedeemed(proposals[i].giftAmount, proposals[i].giftAddress);
                break;
            }
        }
    }

    //End Phase 3 Core Functions

    function getAttendees() public view returns(address[] memory) {

        address[] memory arr = new address[](attendeeCount);

        for (uint256 i = 0; i < attendeeCount; i++) {
            arr[i] = attendees[i];
        }

        return arr;
    }

    function rollOverToCircle(address otherCircle) public onlyRole(LEADER_ROLE) {
        erc20Token.transferFrom(address(this), otherCircle, unallocatedFunds);
    }
}