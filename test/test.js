const { expect } = require("chai");
const { ethers } = require("hardhat");

//uint256 step;
//step 1: Proposal Creation Phase
//step 2: Bean Placement Phase
//step 3: Gift Redeem Phase

describe("Giving Circle", function () {

  it("", async function () {

    const [owner, attendee1, attendee2, badActor] = await ethers.getSigners();

    const Erc20TokenContract = await ethers.getContractFactory("TestERC20");
    const erc20TokenContract = await Erc20TokenContract.deploy();
    await erc20TokenContract.mint(1500);

    const KYCController = await ethers.getContractFactory("KYCController");
    const kycController = await KYCController.deploy(owner.address);

    const GivingCircleImplementation = await ethers.getContractFactory("GivingCircle");
    const givingCircleImplementation = await GivingCircleImplementation.deploy({
      beansToDispursePerAttendee: 10,
      fundingThreshold: 1000,
      circleLeaders: [owner.address],
      beanPlacementAdmins: [],
      fundsManagers: [],
      erc20Token: erc20TokenContract.address,
      kycController: kycController.address
    });

    const GivingCircleFactory = await ethers.getContractFactory("GivingCircleFactory");
    const givingCircleFactory = await GivingCircleFactory.deploy([owner.address]);
    await givingCircleFactory.setImplementation(givingCircleImplementation.address);
    let impl = await givingCircleFactory.implementation();
    console.log(impl);

    await givingCircleFactory.createGivingCircle({
      beansToDispursePerAttendee: 10,
      fundingThreshold: 1000,
      circleLeaders: [owner.address],
      beanPlacementAdmins: [],
      fundsManagers: [],
      erc20Token: erc20TokenContract.address,
      kycController: kycController.address
    });
    
    let count = await givingCircleFactory.instancesCount();
    console.log(count);

    let addr = await givingCircleFactory.instances(0);
    console.log(addr);

    let attendeeCount1 = await givingCircleFactory.attendeeCount(0);
    console.log(attendeeCount1);

    await givingCircleFactory.registerAttendee(0, attendee1.address);
    
    let attendeeCount2 = await givingCircleFactory.attendeeCount(0);
    console.log(attendeeCount2);
    
    let attendees = await givingCircleFactory.getAttendees(0);
    console.log(attendees);

    await givingCircleFactory.createNewProposal(0, attendee1.address);
    await givingCircleFactory.createNewProposal(0, attendee2.address);

    let proposalsCount = await givingCircleFactory.proposalCount(0);
    console.log(proposalsCount);

    await givingCircleFactory.ProgressToBeanPlacementPhase(0);

    
    let bc = await givingCircleFactory.getAvailableBeans(0, attendee1.address);
    console.log(bc);

    await givingCircleFactory.connect(attendee1).placeMyBeans(0, 0, 7);

    let bc2 = await givingCircleFactory.getAvailableBeans(0, attendee1.address);
    console.log(bc2);

    await givingCircleFactory.connect(attendee1).placeMyBeans(0, 1, 2);

    let bc3 = await givingCircleFactory.getAvailableBeans(0, attendee1.address);
    console.log(bc3);

    await erc20TokenContract.transfer(givingCircleFactory.instances(0), 1000);

    await givingCircleFactory.ProgressToGiftRedeemPhase(0);

    await erc20TokenContract.transfer(givingCircleFactory.instances(0), 300);

    await kycController.kycUser(attendee1.address);
    await kycController.kycUser(attendee2.address);


    let bo1= await erc20TokenContract.balanceOf(attendee1.address);
    console.log(bo1);

    await givingCircleFactory.connect(attendee1).redeemMyGift(0);

    let bo = await erc20TokenContract.balanceOf(attendee1.address);
    console.log(bo);

    let bo3 = await erc20TokenContract.balanceOf(attendee2.address);
    console.log(bo3);

    await givingCircleFactory.connect(attendee2).redeemMyGift(0);

    let bo4 = await erc20TokenContract.balanceOf(attendee2.address);
    console.log(bo4);

    await erc20TokenContract.transfer(givingCircleFactory.instances(0), 200);

    let i = await givingCircleFactory.getLeftoverFunds(0);
    console.log(i);

    let j = await givingCircleFactory.getProposals(0);
    console.log(j);
  });

  return;

  it("", async function () {

    const [owner, attendee1, attendee2] = await ethers.getSigners();
    
    const Erc20TokenContract = await ethers.getContractFactory("TestERC20");
    const erc20TokenContract = await Erc20TokenContract.deploy();
    await erc20TokenContract.mint(1500);

    const KYCController = await ethers.getContractFactory("KYCController");
    const kycController = await KYCController.deploy(owner.address);

    const GivingCircle = await ethers.getContractFactory("GivingCircle");
    const givingCircle = await GivingCircle.deploy({
        beansToDispursePerAttendee: 10,
        fundingThreshold: 1000,
        circleLeaders: [owner.address],
        specialBeanPlacers: [],
        specialGiftRedeemers: [],
        erc20Token: erc20TokenContract.address,
        kycController: kycController.address
      });
    
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

    
    let bc = await givingCircle.getAvailableBeans(attendee1.address);
    console.log(bc);

    await givingCircle.connect(attendee1).placeMyBeans(0, 7);

    let bc2 = await givingCircle.getAvailableBeans(attendee1.address);
    console.log(bc2);

    await givingCircle.connect(attendee1).placeMyBeans(1, 2);


    let bc3 = await givingCircle.getAvailableBeans(attendee1.address);
    console.log(bc3);

    await erc20TokenContract.transfer(givingCircle.address, 1000);

    await givingCircle.ProgressToGiftRedeemPhase();

    await erc20TokenContract.transfer(givingCircle.address, 300);

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

    await erc20TokenContract.transfer(givingCircle.address, 200);

    let i = await givingCircle.getLeftoverFunds();
    console.log(i);

    let j = await givingCircle.getProposals();
    console.log(j);
    return;

  });
});