require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require('hardhat-contract-sizer');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        // settings: {
        //   optimizer: {
        //     enabled: true,
        //     runs: 200
        //   }
        // }
      }
    ]
  },
  contractSizer: {
    alphaSort: false,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  networks: {
    eth: {
      url: process.env.URL_ETHEREUM,
      accounts: [process.env.PRIVATE_KEY],
    },
    eth: {
      url: process.env.URL_POLYGON,
      accounts: [process.env.PRIVATE_KEY],
    },
    goerli: {
      url: process.env.URL_GOERLI,
      accounts: [process.env.PRIVATE_KEY],
    },
    mumbai: {
      url: process.env.URL_MUMBAI,
      accounts: [process.env.PRIVATE_KEY],
      },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    apiKey: process.env.POLYGONSCAN_API_KEY,
  }
};
