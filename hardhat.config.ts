import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
import "@nomicfoundation/hardhat-ethers";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.24",
      },
      {
        version: "0.7.6",
      },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000,
      },
      viaIR: true,
    },
  },
  networks: {
    amoy: {
      url: process.env.RPC_URL,
      chainId: parseInt(`${process.env.CHAIN_ID}`),
      accounts: [process.env.SECRET!],
    },
  },
  etherscan: {
    apiKey: process.env.API_KEY,
  },
};

export default config;
