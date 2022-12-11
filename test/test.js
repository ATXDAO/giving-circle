const { expect } = require("chai");

//uint256 step;
//step 0 = newCircle
//step 1 = propWindowOpen
//step 2 = dispursingBeans
//step 3 = beansDisbursed
//step 4 = votingOpen
//step 5 giftRedemption

describe("Giving Circle", function () {
  it("", async function () {
    const [owner] = await ethers.getSigners();

    const Contract = await ethers.getContractFactory("ATXDAOgivingCircle");


    const UsdcDummyContract = await ethers.getContractFactory("TestERC20");

    const usdcDummyContract = await UsdcDummyContract.deploy();
    await usdcDummyContract.mint(15000);
    console.log("minted!");

    console.log(usdcDummyContract.address);

    //owner.address SHOULD be Sam's address
    const contract = await Contract.deploy(usdcDummyContract.address, owner.address);
    
    //step 0 
    //sets to step 1
    await contract.newCircle(1); 
    console.log(await contract.getCircleStep(1));
    
    //create new proposals
    await contract.newProposal(1, 1, owner.address);


    //sets to step 2
    await contract.closePropWindow(1);
    console.log(await contract.getCircleStep(1));

//    function disburseBeans(uint disburseforCircleNumber, address[] memory attendees) public payable virtual returns (bool) {
    await contract.disburseBeans(1, [owner.address]);





    //step X: closeCircleVoting
    return;
    expect(await contract.sayHello()).to.equal("hello");
  });
});