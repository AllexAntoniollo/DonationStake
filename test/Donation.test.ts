import {
  loadFixture,
  time,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("UserBooCash", function () {
  async function deployFixture() {
    const [owner, otherAccount] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy();
    const tokenAddress = await token.getAddress();

    const User = await ethers.getContractFactory("UserBooCash");
    const user = await User.deploy(owner.address);
    const userAddress = await user.getAddress();
    const Donation = await ethers.getContractFactory("Donation");
    const donation = await Donation.deploy(
      tokenAddress,
      owner.address,
      userAddress
    );
    const donationAddress = await donation.getAddress();

    await token.mint(donationAddress, ethers.parseUnits("1000", "ether"));
    await token.mint(owner.address, ethers.parseUnits("100", "ether"));
    await token.approve(donationAddress, ethers.parseUnits("100", "ether"));

    return { owner, otherAccount, user, userAddress, donation };
  }

  it("Should create donation", async function () {
    const { owner, otherAccount, user, userAddress, donation } =
      await loadFixture(deployFixture);

    await donation.deposit(ethers.parseUnits("10", "ether"));
  });
});
