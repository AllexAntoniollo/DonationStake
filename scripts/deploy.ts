import { ethers } from "hardhat";

async function main() {
  // const UniswapAidMut = await ethers.getContractFactory("UniswapAidMut");
  // const uniswap = await UniswapAidMut.deploy();
  // await uniswap.waitForDeployment();
  // const uniswapAddress = await uniswap.getAddress();
  // console.log(`uniswapAddress deployed to ${uniswapAddress}`);
  // const Token = await ethers.getContractFactory("Token");
  // const token = await Token.deploy();
  // await token.waitForDeployment();
  // const tokenAddress = await token.getAddress();
  // console.log(`token deployed to ${tokenAddress}`);
  // const UserAidMut = await ethers.getContractFactory("UserAidMut");
  // const userAidMut = await UserAidMut.deploy(
  //   "0x1dD0dedBf32825652337F6BB7a3B3b4776547572"
  // );
  // await userAidMut.waitForDeployment();
  // const userAidMutAddress = await userAidMut.getAddress();
  // console.log(`userAidMut deployed to ${userAidMutAddress}`);
  // const DonationAidMut = await ethers.getContractFactory("DonationAidMut");
  // const donationAidMut = await DonationAidMut.deploy(
  //   "0xd2A5976E7750148Ec76c237e0C6d91Dd8A0799ba",
  //   "0x1dD0dedBf32825652337F6BB7a3B3b4776547572",
  //   "0x98F5d50627d98162084b3D3CEfc79969B5005cff"
  // );
  // await donationAidMut.waitForDeployment();
  // const donationAidMutAddress = await donationAidMut.getAddress();
  // console.log(`donationAidMutAddress deployed to ${donationAidMutAddress}`);
  const DonationAidMut = await ethers.getContractFactory("Teste");
  const donationAidMut = await DonationAidMut.deploy();
  await donationAidMut.waitForDeployment();
  const donationAidMutAddress = await donationAidMut.getAddress();
  console.log(`donationAidMutAddress deployed to ${donationAidMutAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
