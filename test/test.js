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
    const kycController = await KYCController.deploy([owner.address]);

    const GivingCircleImplementation = await ethers.getContractFactory("GivingCircle");

    const givingCircleImplementation = await GivingCircleImplementation.deploy({
      name: "impl",
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

    const CIRCLE_CREATOR_ROLE = await givingCircleFactory.CIRCLE_CREATOR_ROLE();
    await givingCircleFactory.grantRole(CIRCLE_CREATOR_ROLE, owner.address);



    await givingCircleFactory.setImplementation(givingCircleImplementation.address);
    let impl = await givingCircleFactory.implementation();
    console.log(impl);

    await givingCircleFactory.createGivingCircle({
      name: "example",
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

    let attendeeCount1 = await givingCircleImplementation.attendeeCount();
    console.log(attendeeCount1);

    await givingCircleImplementation.registerAttendee(attendee1.address);
    
    let attendeeCount2 = await givingCircleImplementation.attendeeCount();
    console.log(attendeeCount2);
    
    let attendees = await givingCircleImplementation.getAttendees();
    console.log(attendees);

    await givingCircleImplementation.createNewProposal(
      { 
          addr: attendee1.address, name: "Jeff", contributions: "I made a thing!" , fundsAllocated: 0, hasRedeemed: false
      }
      
      );

      
    await givingCircleImplementation.createNewProposal(
{
  addr: attendee2.address, name: "Tony", contributions: "I made another thing!" , fundsAllocated: 0, hasRedeemed: false

}      );



    let proposalsCount = await givingCircleImplementation.proposalCount();
    console.log(proposalsCount);

    await givingCircleImplementation.ProgressToBeanPlacementPhase();

    let bc = await givingCircleImplementation.getAvailableBeans(attendee1.address);
    console.log(bc);

    await givingCircleImplementation.connect(attendee1).placeMyBeans(0, 7);

    let bc2 = await givingCircleImplementation.getAvailableBeans(attendee1.address);
    console.log(bc2);

    await givingCircleImplementation.connect(attendee1).placeMyBeans(1, 2);

    let bc3 = await givingCircleImplementation.getAvailableBeans(attendee1.address);
    console.log(bc3);

    await erc20TokenContract.transfer(givingCircleImplementation.address, 1000);

    await givingCircleImplementation.ProgressToFundsRedemptionPhase();

    await erc20TokenContract.transfer(givingCircleImplementation.address, 300);

    await kycController.kycUser(attendee1.address);
    await kycController.kycUser(attendee2.address);

    let bo1= await erc20TokenContract.balanceOf(attendee1.address);
    console.log(bo1);

    await givingCircleImplementation.connect(attendee1).redeemMyFunds();

    let bo = await erc20TokenContract.balanceOf(attendee1.address);
    console.log(bo);

    let bo3 = await erc20TokenContract.balanceOf(attendee2.address);
    console.log(bo3);

    await givingCircleImplementation.connect(attendee2).redeemMyFunds();

    let bo4 = await erc20TokenContract.balanceOf(attendee2.address);
    console.log(bo4);

    await erc20TokenContract.transfer(givingCircleImplementation.address, 200);

    let i = await givingCircleImplementation.getLeftoverFunds();
    console.log(i);

    let j = await givingCircleImplementation.getProposals();
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