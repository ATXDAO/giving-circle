const { expect } = require("chai");
const { ethers } = require("hardhat");

//uint256 step;
//step 1: Proposal Creation Phase
//step 2: Bean Placement Phase
//step 3: Gift Redeem Phase




describe("Giving Circle", function () {


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

    await givingCircle.registerAttendeeToCircle(attendee1.address);
    
    let attendeeCount2 = await givingCircle.attendeeCount();
    console.log(attendeeCount2);

    let attendees = await givingCircle.getAttendees();
    console.log(attendees);

    await givingCircle.createNewProposal(attendee1.address);
    await givingCircle.createNewProposal(attendee2.address);

    let proposalsCount = await givingCircle.proposalCount();
    console.log(proposalsCount);

    await givingCircle.closeProposalWindowAndAttendeeRegistration();

    let bc = await givingCircle.getBeanCountForAttendee(attendee1.address);
    console.log(bc);
    await givingCircle.connect(attendee1).placeBeans(0, 7);

    let bc2 = await givingCircle.getBeanCountForAttendee(attendee1.address);
    console.log(bc2);

    let bc3 = await givingCircle.getBeanCountForAttendee(attendee1.address);
    console.log(bc3);

    await erc20TokenContract.approve(givingCircle.address, 1000);

    await givingCircle.fundGift(1000);

    await givingCircle.closeCircleVoting();

    await kycController.kycUser(attendee1.address);

    let bo1= await erc20TokenContract.balanceOf(attendee1.address);
    console.log(bo1);

    await givingCircle.connect(attendee1).redeemGift(0);

    let bo = await erc20TokenContract.balanceOf(attendee1.address);
    console.log(bo);
    
   


  });
  return;


  it("", async function () {
    const [owner, attendee1, attendee2] = await ethers.getSigners();

    const UsdcDummyContract = await ethers.getContractFactory("TestERC20");
    const usdcDummyContract = await UsdcDummyContract.deploy();
    await usdcDummyContract.mint(15000);

    const Contract = await ethers.getContractFactory("ATXDAOgivingCircle");

    const contract = await Contract.deploy(usdcDummyContract.address, owner.address, owner.address);
    let count = await contract.circleCount();
    console.log(count);
    
    await contract.createNewCircleAndOpenProposalWindowAndAttendeeRegistration(1000, 10);
    
    let count2 = await contract.circleCount();
    console.log(count2);

    let attendeeCount1 = await contract.getAttendeeAmountInCircle(0);
    console.log(attendeeCount1);

    await contract.registerAttendeeToCircle(0, attendee1.address);
    
    let attendeeCount2 = await contract.getAttendeeAmountInCircle(0);
    console.log(attendeeCount2);

    let attendees = await contract.getAttendeesInCircle(0);
    console.log(attendees);

    await contract.createNewProposal(0, attendee1.address);
    await contract.createNewProposal(0, attendee2.address);

    let proposalsCount = await contract.getProposalCountInCircle(0);
    console.log(proposalsCount);

    await contract.closeProposalWindowAndAttendeeRegistration(0);

    let bc = await contract.getBeanCountInCircle(0, attendee1.address);
    console.log(bc);
    await contract.connect(attendee1).placeBeans(0, 0, 7);

    let bc2 = await contract.getBeanCountInCircle(0, attendee1.address);
    console.log(bc2);

    let bc3 = await contract.getBeanCountInCircle(0, attendee1.address);
    console.log(bc3);

    await usdcDummyContract.approve(contract.address, 1000);
    await contract.fundGiftForCircle(0);

    await contract.closeCircleVoting(0);
    
    await contract.kycUser(attendee1.address);

    let bo1= await usdcDummyContract.balanceOf(attendee1.address);
    console.log(bo1);

    await contract.connect(attendee1).redeemGift(0, 0);

    let bo = await usdcDummyContract.balanceOf(attendee1.address);
    console.log(bo);
    
    return;
    expect(await contract.sayHello()).to.equal("hello");
  });
});