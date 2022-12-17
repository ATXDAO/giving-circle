const { expect } = require("chai");
const { ethers } = require("hardhat");

//uint256 step;
//step 1: Proposal Creation Phase
//step 2: Bean Placement Phase
//step 3: Gift Redeem Phase

describe("Giving Circle", function () {

  it("", async function () {
    const [owner, giftRecipient1, attendee1] = await ethers.getSigners();

    const Erc20TokenContract = await ethers.getContractFactory("TestERC20");
    const erc20TokenContract = await Erc20TokenContract.deploy();
    await erc20TokenContract.mint(1500);

    const KYCController = await ethers.getContractFactory("KYCController");
    const kycController = await KYCController.deploy(owner.address);

    const GivingCircleImplementation = await ethers.getContractFactory("GivingCircle");
    const givingCircleImplementation = await GivingCircleImplementation.deploy(owner.address, owner.address, 10, kycController.address, erc20TokenContract.address);

    const GivingCircleFactory = await ethers.getContractFactory("GivingCircleFactory");
    const givingCircleFactory = await GivingCircleFactory.deploy();
    await givingCircleFactory.setImplementation(givingCircleImplementation.address);
    let impl = await givingCircleFactory.implementation();
    console.log(impl);

    await givingCircleFactory.createGivingCircle(owner.address, owner.address, 10, kycController.address, erc20TokenContract.address);
    
    let count = await givingCircleFactory.givingCirclesCount();
    console.log(count);

    let addr = await givingCircleFactory.givingCircles(0);
    console.log(addr);
  });

  it("", async function () {
    const [owner, attendee1, attendee2] = await ethers.getSigners();
    
    const Erc20TokenContract = await ethers.getContractFactory("TestERC20");
    const erc20TokenContract = await Erc20TokenContract.deploy();
    await erc20TokenContract.mint(1500);

    const KYCController = await ethers.getContractFactory("KYCController");
    const kycController = await KYCController.deploy(owner.address);

    const GivingCircle = await ethers.getContractFactory("GivingCircle");
    const givingCircle = await GivingCircle.deploy(owner.address, owner.address, 10, kycController.address, erc20TokenContract.address);

    let attendeeCount1 = await givingCircle.attendeeCount();
    console.log(attendeeCount1);

    await givingCircle.registerAttendee(attendee1.address);
    
    let attendeeCount2 = await givingCircle.attendeeCount();
    console.log(attendeeCount2);

    let attendees = await givingCircle.getAttendees();
    console.log(attendees);

    await givingCircle.createNewProposal(attendee1.address);
    await givingCircle.createNewProposal(attendee2.address);

    let proposalsCount = await givingCircle.proposalCount();
    console.log(proposalsCount);

    await givingCircle.ProgressToBeanPlacementPhase();

    let bc = await givingCircle.attendeeBeanCount(attendee1.address);
    console.log(bc);
    await givingCircle.connect(attendee1).placeBeans(0, 7);
    await givingCircle.connect(attendee1).placeBeans(1, 2);

    let bc2 = await givingCircle.attendeeBeanCount(attendee1.address);
    console.log(bc2);

    let bc3 = await givingCircle.attendeeBeanCount(attendee1.address);
    console.log(bc3);

    await erc20TokenContract.approve(givingCircle.address, 1000);

    await givingCircle.fundGift(1000);

    await givingCircle.ProgressToGiftRedeemPhase();

    await kycController.kycUser(attendee1.address);
    await kycController.kycUser(attendee2.address);

    let bo1= await erc20TokenContract.balanceOf(attendee1.address);
    console.log(bo1);

    await givingCircle.connect(attendee1).redeemMyGift();

    let bo = await erc20TokenContract.balanceOf(attendee1.address);
    console.log(bo);

    let bo3 = await erc20TokenContract.balanceOf(attendee2.address);
    console.log(bo3);

    await givingCircle.connect(attendee2).redeemMyGift();

    let bo4 = await erc20TokenContract.balanceOf(attendee2.address);
    console.log(bo4);

    let i = await givingCircle.unallocatedFunds();

    console.log(i);
  });
});