const { expect } = require("chai");

//uint256 step;
//step 1: Proposal Creation Phase
//step 2: Bean Placement Phase
//step 3: Gift Redeem Phase




describe("Giving Circle", function () {
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

    await contract.connect(attendee1).placeBeans(0, 0, 3);

    let bc3 = await contract.getBeanCountInCircle(0, attendee1.address);
    console.log(bc3);

    await contract.closeCircleVoting(0);

    await contract.fundGiftForCircle(0);
    
    await contract.connect(attendee1).redeemGift(0, 0);

    //step X: closeCircleVoting
    return;
    expect(await contract.sayHello()).to.equal("hello");
  });
});