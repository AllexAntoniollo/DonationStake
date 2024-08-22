import { ethers } from "hardhat";

async function main() {
  // const UniswapAidMut = await ethers.getContractFactory("UniswapAidMut");
  // const uniswap = await UniswapAidMut.deploy();
  // await uniswap.waitForDeployment();
  // const uniswapAddress = await uniswap.getAddress();
  // console.log(`uniswapAddress deployed to ${uniswapAddress}`);
  const UserAidMut = await ethers.getContractFactory("UserAidMut");
  const userAidMut = await UserAidMut.deploy(
    "0x14690441b74bab2E3f72844a3f355bF51a721B1F"
  );
  await userAidMut.waitForDeployment();
  const userAidMutAddress = await userAidMut.getAddress();
  console.log(`userAidMut deployed to ${userAidMutAddress}`);
  const DonationAidMut = await ethers.getContractFactory("DonationAidMut");
  const donationAidMut = await DonationAidMut.deploy(
    "0xe4FeAb21b42919C5C960ed2B4BdFFc521E26881f",
    "0x14690441b74bab2E3f72844a3f355bF51a721B1F",
    userAidMutAddress
  );
  await donationAidMut.waitForDeployment();
  const donationAidMutAddress = await donationAidMut.getAddress();
  console.log(`donationAidMutAddress deployed to ${donationAidMutAddress}`);
  await donationAidMut.setUniswapOracle(
    "0x4e18321254f88b2ade21884ca33ca2c129b4f6e6"
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
