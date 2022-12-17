// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IGivingCircle.sol";
import "./KYCController.sol";
import "./partialIERC20.sol";

contract GivingCircle is IGivingCircle, AccessControl, Initializable {

    bytes32 public constant LEADER_ROLE = keccak256("LEADER_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    enum Phase
    {
        UNINITIALIZED, //Contract is not initialized. Cannot begin circle until no longer uninitalized.
        PROPOSAL_CREATION, //Register attendees, fund gifts, create new proposals, and progress phase to bean placement.
        BEAN_PLACEMENT, //Register attendees, fund gifts, place beans, and progress phase to gift redeem.
        GIFT_REDEEM //Redeem gifts. Rollover leftover funds to a different circle.
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
    
    uint public erc20TokenPerBean;

    uint256 public beansToDispursePerAttendee;
    uint256 public numOfBeans;
    mapping (address => uint256) public attendeeBeanCount;
    
    uint256 public attendeeCount;
    mapping (uint256 => address) public attendees;

    partialIERC20 public erc20Token;
    KYCController public kycController;

    uint256 public fundingThreshold;

    event ProposalCreated(uint indexed propNumb, address indexed giftrecipient);
    event BeansPlaced(uint indexed propNumb, uint indexed beansplaced, address indexed beanplacer); // emitted in placeBeans
    event GiftsAllocated();
    event VotingClosed();
    event GiftRedeemed(uint indexed giftwithdrawn, address indexed withdrawee);  // emitted in redeemGift

    constructor(address _circleLeader, uint256 _beansToDispursePerAttendee, address _kycController, address _erc20Token, uint256 _fundingThreshold) {
        initialize(_circleLeader, _beansToDispursePerAttendee, _kycController, _erc20Token, _fundingThreshold);
    }

    function initialize(address _circleLeader, uint256 _beansToDispursePerAttendee, address _kycController, address _erc20Token, uint256 _fundingThreshold) public initializer {
        
        _grantRole(LEADER_ROLE, _circleLeader);
        erc20Token = partialIERC20(_erc20Token);
        kycController = KYCController(_kycController);

        attendeeCount = 0;
        erc20TokenPerBean = 0;
        phase = Phase.PROPOSAL_CREATION;
        proposalCount = 0;
        beansToDispursePerAttendee = _beansToDispursePerAttendee;

        fundingThreshold = _fundingThreshold;
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

    //adding funds has been removed from the 
    function ProgressToGiftRedeemPhase() public onlyRole(LEADER_ROLE) {
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

    function rollOverToCircle(address otherCircle) public onlyRole(LEADER_ROLE) {
        require(phase == Phase.GIFT_REDEEM, "circle needs to be in gift redeem phase");
        erc20Token.transfer(otherCircle, getLeftoverFunds());
    }

    //End Phase 3 Core Functions

    function getAttendees() public view returns(address[] memory) {

        address[] memory arr = new address[](attendeeCount);

        for (uint256 i = 0; i < attendeeCount; i++) {
            arr[i] = attendees[i];
        }

        return arr;
    }

    function getProposals() public view returns(Proposal[] memory) {

        Proposal[] memory arr = new Proposal[](proposalCount);

        for (uint256 i = 0; i < proposalCount; i++) {
            arr[i] = proposals[i];
        }

        return arr;
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