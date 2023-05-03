# Smart Contracts

The Giving Circle concept relies on two main smart contracts that follow the Factory Design Pattern.

`GivingCircleFactory.sol` - A smart contract that holds a reference to a `GivingCircle.sol` implementation and deploys copies of it through the Factory Design Pattern.

`GivingCircle.sol` - The Giving Circle in its entirety. Can be deployed standalone or to be used by `GivingCircleFactory.sol` as a template.

With supporting smart contracts which makes development easier on both inside the repository and out into other projects.
These smart contracts include

`IGivingCircle.sol` - The interface for GivingCircle.sol functions.
`Attendees.sol` - A struct pertaining to a Giving Circle's attendees.
`Proposals.sol` - A struct pertaining to a Giving Circle's proposals, containing information about a contributor(s) and their contributions.
`Initialization.sol` - A struct containing parameters used to customize a Giving Circle.

There are two other smart contracts which are utilized by `GivingCircle.sol`:
`KYCController.sol` acts as an on-chain KYC database and is used directly by `GivingCircle.sol`
`partialIERC20.sol` is an interface that used by `GivingCircle.sol` which provides a slice of the functions contained in the ERC20 standard. 

# Deployment
Simple deployment through hardhat by running `npx hardhat run scripts/DEPLOY_SCRIPT.js --network NETWORK`.
`deploy-factory.js` deploys a new instance of GivingCircleFactory.sol
`deploy-impl.js` deploys a new instance of GivingCircle.sol
`deploy-kyc.js` deploys a new instance of KYCController.sol
`deploy.js` deploys a new instance of GivingCircle.sol, then deploys a new instance of GivingCircleFactory.sol passing in the recently deployed instance of GivingCircle.sol 

# Testing
Simple testing through hardhat by running `npx hardhat test` which runs the tests found at `test/test.js`. 
Currently testing is purely based around the success of the Giving Circle lifecycle. You should be able to create a new Giving Circle, and run through its phases end to end without running into any errors. It does not test for edge cases.