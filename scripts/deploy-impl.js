// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require('hardhat')

async function deploy(contractName, ...args) {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await Contract.deploy(...args);
  
  console.log(`${contractName} is being deployed...`);
  console.log(`Transaction hash: ${contract.deployTransaction.hash}`);

  let tx = await contract.deployed();
  
  console.log(`Gas Price: ${ethers.utils.formatUnits(contract.deployTransaction.gasPrice.toNumber(), 'gwei')} gwei`)
  console.log(`Gas Limit: ${contract.deployTransaction.gasLimit.toNumber()}`)
  
  console.log(`Deployed ${contractName} to: ${contract.address}`);
  return contract;
}

async function main() {

  const [owner] = await ethers.getSigners();

  let implementation = await deploy(
    "GivingCircle", {
    beansToDispursePerAttendee: 1,
    fundingThreshold: 0,
    circleLeaders: [owner.address],
    beanPlacementAdmins: [],
    fundsManagers: [],
    erc20Token: "0x0000000000000000000000000000000000000000",
    kycController: "0x0000000000000000000000000000000000000000"
    }
  );

  return;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
