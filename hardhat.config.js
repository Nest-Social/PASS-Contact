require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require('@openzeppelin/hardhat-upgrades');
require('hardhat-contract-sizer');
require('hardhat-abi-exporter');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    oktest: {
      url: process.env.RPC_URL_OKTEST,
      accounts: [process.env.PK_ACCOUNT_1],
      timeout: 600000,
      blockGasLimit: 0x1fffffffffffff,
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      allowUnlimitedContractSize: true,
    },
    fbchain: {
      url: process.env.RPC_URL_FBC,
      accounts: [process.env.PK_ACCOUNT_1],
      timeout: 600000,
    },
    bsctest: {
      url: process.env.RPC_URL_BSCTEST,
      accounts: [process.env.PK_ACCOUNT_1],
      gas: 30000000,
      timeout: 600000,
    },
    polygon_mumbai: {
      url: process.env.RPC_URL_POLYGONMUMBAI,
      accounts: [process.env.PK_ACCOUNT_1],
    },
    polygon: {
      url: process.env.RPC_URL_POLYGON,
      accounts: [process.env.PK_ACCOUNT_1],
    },
    fuji:{
      url: process.env.RPC_URL_FUJI,
      accounts: [process.env.PK_ACCOUNT_1],
      chainId: 43113,
      live: true,
      saveDeployments: true,
      tags: ["staging"],
      gas: 5000000,
      timeout: 100000000
    },
  },
  solidity: "0.8.21",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: true,
  }
};
