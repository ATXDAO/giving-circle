// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IGivingCircle.sol";
import "./KYCController.sol";
import "./partialIERC20.sol";
import "./Initialization.sol";
import "./Proposals.sol";

contract GivingCircle is IGivingCircle, AccessControl, Initializable {

    bytes32 public constant LEADER_ROLE = keccak256("LEADER_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant SPECIAL_BEAN_PLACER_ROLE = keccak256("SPECIAL_BEAN_PLACER_ROLE");
    bytes32 public constant SPECIAL_GIFT_REDEEMER_ROLE = keccak256("SPECIAL_GIFT_REDEEMER_ROLE");
    enum Phase
    {
        UNINITIALIZED, //Contract is not initialized. Cannot begin circle until no longer uninitalized.
        PROPOSAL_CREATION, //Register attendees, fund gifts, create new proposals, and progress phase to bean placement.
        BEAN_PLACEMENT, //Register attendees, fund gifts, place beans, and progress phase to gift redeem.
        GIFT_REDEEM //Redeem gifts. Rollover leftover funds to a different circle.
    }
    Phase public phase;

    uint256 public proposalCount;
    mapping (uint256 => Proposals.Proposal) public proposals;
    
    uint public erc20TokenPerBean;

    uint256 public beansToDispursePerAttendee;
    uint256 public numOfBeans;
    
    uint256 public attendeeCount;
    mapping (uint256 => address) public attendees;
    mapping (uint256 => uint256) beansAvailable;


    partialIERC20 public erc20Token;
    KYCController public kycController;

    uint256 public fundingThreshold;

    event ProposalCreated(uint indexed propNumb, address indexed giftrecipient);
    event BeansPlaced(uint indexed propNumb, uint indexed beansplaced, address indexed beanplacer); // emitted in placeBeans
    event GiftsAllocated();
    event VotingClosed();
    event GiftRedeemed(uint indexed giftwithdrawn, address indexed withdrawee);  // emitted in redeemGift

    constructor(Initialization.GivingCircleInitialization memory init) {
        initialize(init);
    }

    function initialize(Initialization.GivingCircleInitialization memory init) public initializer {

        phase = Phase.PROPOSAL_CREATION;
        beansToDispursePerAttendee = init.beansToDispursePerAttendee;
        fundingThreshold = init.fundingThreshold;
        attendeeCount = 0;
        erc20TokenPerBean = 0;
        proposalCount = 0;

        for (uint256 i = 0; i < init.circleLeaders.length; i++) {
            _grantRole(LEADER_ROLE, init.circleLeaders[i]);
        }  

        for (uint256 i = 0; i < init.specialBeanPlacers.length; i++) {
            _grantRole(SPECIAL_BEAN_PLACER_ROLE, init.specialBeanPlacers[i]);
        }

        for (uint256 i = 0; i < init.specialGiftRedeemers.length; i++) {
            _grantRole(SPECIAL_GIFT_REDEEMER_ROLE, init.specialGiftRedeemers[i]);
        }

        erc20Token = partialIERC20(init.erc20Token);
        kycController = KYCController(init.kycController);

    }

    //Start Phase 1 Core Functions

    function createNewProposal(address payable giftRecipient) public onlyRole(LEADER_ROLE) {
        require(phase == Phase.PROPOSAL_CREATION, "circle needs to be in proposal creation phase.");

        require(!hasRole(PROPOSER_ROLE, giftRecipient), "Recipient already present in proposal!");

        _grantRole(PROPOSER_ROLE, giftRecipient);

        uint256 proposalIndex = proposalCount;
        Proposals.Proposal storage newProposal = proposals[proposalIndex];
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

            attendees[attendeeCount] = addr;
            beansAvailable[attendeeCount] = beansToDispursePerAttendee;
            attendeeCount++;
        }
    }

    function ProgressToBeanPlacementPhase() external onlyRole(LEADER_ROLE) {
        require(phase == Phase.PROPOSAL_CREATION, "circle needs to be in proposal creation phase.");
        phase = Phase.BEAN_PLACEMENT;
    }

    //End Phase 1 Core Functions

    //Start Phase 2 Core Functions
    function placeBeans(address attendee, uint256 proposalIndex, uint256 beanQuantity) internal {
        require (
            phase == Phase.BEAN_PLACEMENT, "circle needs to be in bean placement phase."
        );

        bool isPresent = false;
        for (uint256 i = 0; i < attendeeCount; i++) {
            if (attendees[i] == attendee) {
                require(beansAvailable[i] >= beanQuantity, "not enough beans held to place bean quantity.");

                beansAvailable[i] -= beanQuantity;
                proposals[proposalIndex].beansReceived += beanQuantity;
                
                isPresent = true;
                emit BeansPlaced(proposalIndex, beanQuantity, attendee); 
                break;               
            }
        }

        require(isPresent, "attendee not found!");
    }

    function placeMyBeans(uint256 proposalIndex, uint256 beanQuantity) external {
        placeBeans(msg.sender, proposalIndex, beanQuantity);
    }

    function placeBeansForSomeone(address attendee, uint256 proposalIndex, uint256 beanQuantity) external onlyRole(SPECIAL_BEAN_PLACER_ROLE) {
        placeBeans(attendee, proposalIndex, beanQuantity);
    }
 
    function ProgressToGiftRedeemPhase() external onlyRole(LEADER_ROLE) {
        require(phase == Phase.BEAN_PLACEMENT, "circle needs to be in bean placement phase");
        require(erc20Token.balanceOf(address(this)) >= fundingThreshold, "Circle needs to be funded first!");

        _calcErc20TokenPerBean();
        _allocateGifts();

        phase = Phase.GIFT_REDEEM;
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

        uint256 totalAllocated;
        for (uint i = 0; i < proposalCount; i++) {
            uint256 amountToAllocate = proposals[i].beansReceived * erc20TokenPerBean;
            proposals[i].giftAmount = amountToAllocate;
            totalAllocated += amountToAllocate;
        }

        emit GiftsAllocated();
    }

    //End Phase 2 Internal Functions

    //Start Phase 3 Core Functions    

    function redeemGift(address addr) internal {
        require(
            phase == Phase.GIFT_REDEEM, "circle needs to be in gift redeem phase"
        );

        require(kycController.isUserKyced(addr), "You need to be KYCed first!");

        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].giftAddress == addr) {
                
                require(!proposals[i].hasRedeemed, "You already redeemed your gift!");

                erc20Token.approve(address(this), proposals[i].giftAmount);
                erc20Token.transferFrom(address(this), proposals[i].giftAddress, proposals[i].giftAmount); // USDCgiftPending mapping is 10**18, thus so is redemptionqty
                proposals[i].hasRedeemed = true;
                emit GiftRedeemed(proposals[i].giftAmount, proposals[i].giftAddress);
                break;
            }
        }
    }

    function redeemGiftForSomeone(address addr) external onlyRole(SPECIAL_GIFT_REDEEMER_ROLE) {
        redeemGift(addr);
    }
    
    function redeemMyGift() external onlyRole(PROPOSER_ROLE) {
        redeemGift(msg.sender);
    }

    function rollOverToCircle(address otherCircle) public onlyRole(LEADER_ROLE) {
        require(phase == Phase.GIFT_REDEEM, "circle needs to be in gift redeem phase");
        erc20Token.transfer(otherCircle, getLeftoverFunds());
    }

    //End Phase 3 Core Functions

    //Helper Functions
    function getAttendees() public view returns(address[] memory) {

        address[] memory arr = new address[](attendeeCount);

        for (uint256 i = 0; i < arr.length; i++) {
            arr[i] = attendees[i];
        }

        return arr;
    }

    function getProposals() public view returns(Proposals.Proposal[] memory) {

        Proposals.Proposal[] memory arr = new Proposals.Proposal[](proposalCount);

        for (uint256 i = 0; i < arr.length; i++) {
            arr[i] = proposals[i];
        }

        return arr;
    }

    function getAvailableBeans(address addr) external view returns(uint256) {

        for (uint256 i = 0; i < attendeeCount; i++) {
            if (attendees[i] == addr) {
                return beansAvailable[i];
            }
        }

        return 0;
    }

    function getLeftoverFunds() public view returns(uint256) {
        uint256 currentBalance = erc20Token.balanceOf(address(this));
        uint256 currentRedeemedAmount = getTotalUnredeemedFunds();
        return currentBalance - currentRedeemedAmount;
    }

    function getTotalRedeemedFunds() public view returns(uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < proposalCount; i++) {
            if (proposals[i].hasRedeemed) {
                total += proposals[i].giftAmount;
            }
        }

        return total;
    }

    function getTotalUnredeemedFunds() public view returns(uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < proposalCount; i++) {
            if (!proposals[i].hasRedeemed) {
                total += proposals[i].giftAmount;
            }
        }

        return total;
    }

    function getTotalAllocatedFunds() public view returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < proposalCount; i++) {
            total += proposals[i].giftAmount;
        }

        return total;
    }
}