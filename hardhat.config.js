require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
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
