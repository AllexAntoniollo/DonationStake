import {
  loadFixture,
  time,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Donation", function () {
  async function deployFixture() {
    const [owner, otherAccount] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy();
    const tokenAddress = await token.getAddress();

    const User = await ethers.getContractFactory("UserAidMut");
    const user = await User.deploy(owner.address);
    const userAddress = await user.getAddress();
    const Donation = await ethers.getContractFactory("DonationAidMut");
    const donation = await Donation.deploy(
      tokenAddress,
      owner.address,
      userAddress
    );
    const donationAddress = await donation.getAddress();

    await token.mint(donationAddress, ethers.parseUnits("1000", "ether"));
    await token.mint(owner.address, ethers.parseUnits("100", "ether"));
    await token.approve(donationAddress, ethers.parseUnits("1000", "ether"));

    return {
      owner,
      otherAccount,
      user,
      userAddress,
      donation,
      token,
      donationAddress,
    };
  }

  it("Should create donation", async function () {
    const {
      owner,
      otherAccount,
      user,
      userAddress,
      donation,
      token,
      donationAddress,
    } = await loadFixture(deployFixture);
    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("10", "ether")
    );
    expect(await token.balanceOf(donationAddress)).to.be.equal(
      ethers.parseUnits("1010", "ether")
    );
    expect((await donation.getUser(owner.address)).totalInvestment).to.be.equal(
      ethers.parseUnits("10", "ether")
    );
  });

  it("Should not create donation (invalid amount)", async function () {
    const { owner, otherAccount, user, userAddress, donation } =
      await loadFixture(deployFixture);

    await expect(
      donation.deposit(ethers.parseUnits("9", "ether"), true)
    ).revertedWith("Amount must be between 10 and 10,000 dollars");
    await expect(
      donation.deposit(ethers.parseUnits("11000", "ether"), true)
    ).revertedWith("Amount must be between 10 and 10,000 dollars");
  });
  it("Should not create donation (more than 1 donation)", async function () {
    const { owner, otherAccount, user, userAddress, donation } =
      await loadFixture(deployFixture);

    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    await expect(
      donation.deposit(ethers.parseUnits("10", "ether"), true)
    ).revertedWith("You can't have more than 1 donation");
  });
  it("Should not create donation (unregistered)", async function () {
    const { owner, otherAccount, user, userAddress, donation } =
      await loadFixture(deployFixture);

    await expect(
      donation
        .connect(otherAccount)
        .deposit(ethers.parseUnits("10", "ether"), true)
    ).revertedWith("Unregistered user");
  });
  it("Should withdraw donation", async function () {
    const {
      owner,
      otherAccount,
      user,
      userAddress,
      donation,
      token,
      donationAddress,
    } = await loadFixture(deployFixture);

    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    await time.increase(60 * 60 * 24 * 15);

    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("10.1", "ether")
    );

    await donation.withdraw();
    expect((await donation.getUser(owner.address)).balance).to.be.equal(0);

    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    await time.increase(60 * 60 * 24 * 30);
    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("10.2", "ether")
    );

    await donation.withdraw();
    expect((await donation.getUser(owner.address)).balance).to.be.equal(0);

    await donation.deposit(ethers.parseUnits("10", "ether"), true);
    await donation.setVideo(owner.address);
    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("10", "ether")
    );
    expect(await donation.timeUntilNextWithdrawal(owner.address)).to.be.closeTo(
      15 * 24 * 60 * 60,
      5
    );
    await time.increase(60 * 60 * 24 * 15);
    expect(await donation.timeUntilNextWithdrawal(owner.address)).to.be.closeTo(
      15 * 24 * 60 * 60,
      5
    );
    await time.increase(60 * 60 * 24 * 15);
    expect(await donation.timeUntilNextWithdrawal(owner.address)).to.be.equal(
      0
    );

    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("10.25", "ether")
    );
    await donation.withdraw();
    expect((await donation.getUser(owner.address)).balance).to.be.equal(0);

    await donation.deposit(ethers.parseUnits("10", "ether"), true);
    await donation.setVideo(owner.address);

    await time.increase(60 * 60 * 24 * 15);
    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("10.1", "ether")
    );
    await donation.withdraw();
    expect((await donation.getUser(owner.address)).balance).to.be.equal(0);
  });
  it("Should withdraw donation greater than 35M", async function () {
    const {
      owner,
      otherAccount,
      user,
      userAddress,
      donation,
      token,
      donationAddress,
    } = await loadFixture(deployFixture);
    await token.mint(donationAddress, ethers.parseUnits("35000000", "ether"));
    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    await time.increase(60 * 60 * 24 * 15);
    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("10.5", "ether")
    );

    await donation.withdraw();

    await donation.deposit(ethers.parseUnits("10", "ether"), true);
    await donation.setVideo(owner.address);
    await time.increase(60 * 60 * 24 * 30);

    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("11.25", "ether")
    );
    await donation.withdraw();
    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    await time.increase(60 * 60 * 24 * 35);

    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("11", "ether")
    );
  });
  it("Should withdraw donation greater than 75M", async function () {
    const {
      owner,
      otherAccount,
      user,
      userAddress,
      donation,
      token,
      donationAddress,
    } = await loadFixture(deployFixture);
    await token.mint(donationAddress, ethers.parseUnits("75000000", "ether"));
    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    await time.increase(60 * 60 * 24 * 15);
    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("11", "ether")
    );

    await donation.withdraw();

    await donation.deposit(ethers.parseUnits("10", "ether"), true);
    await donation.setVideo(owner.address);
    await time.increase(60 * 60 * 24 * 30);

    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("12.5", "ether")
    );
    await donation.withdraw();
    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    await time.increase(60 * 60 * 24 * 35);

    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("12", "ether")
    );
  });
  it("Should withdraw donation greater than 150M", async function () {
    const {
      owner,
      otherAccount,
      user,
      userAddress,
      donation,
      token,
      donationAddress,
    } = await loadFixture(deployFixture);
    await token.mint(donationAddress, ethers.parseUnits("150000000", "ether"));
    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    await time.increase(60 * 60 * 24 * 15);
    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("12", "ether")
    );

    await donation.withdraw();

    await donation.deposit(ethers.parseUnits("10", "ether"), true);
    await donation.setVideo(owner.address);
    await time.increase(60 * 60 * 24 * 30);

    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("15", "ether")
    );
    await donation.withdraw();
    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    await time.increase(60 * 60 * 24 * 35);

    expect((await donation.getUser(owner.address)).balance).to.be.equal(
      ethers.parseUnits("14", "ether")
    );
  });
  it("Should not withdraw donation", async function () {
    const {
      owner,
      otherAccount,
      user,
      userAddress,
      donation,
      token,
      donationAddress,
    } = await loadFixture(deployFixture);

    await donation.deposit(ethers.parseUnits("10", "ether"), true);

    await time.increase(60 * 60 * 24 * 14);

    await expect(donation.withdraw()).to.be.rejectedWith(
      "Tokens are still locked"
    );
  });

  it("Should create donation with 5 levels", async function () {
    this.timeout(120000000);

    const {
      owner,
      otherAccount,
      user,
      userAddress,
      donation,
      token,
      donationAddress,
    } = await loadFixture(deployFixture);

    const allSigners = [owner];
    await token.mint(owner.address, ethers.parseUnits("10000", "ether"));
    for (let i = 0; i < 6; i++) {
      const wallet = ethers.Wallet.createRandom().connect(ethers.provider);
      allSigners.push(wallet);

      await owner.sendTransaction({
        to: wallet.address,
        value: ethers.parseEther("1.0"),
      });
      await token.mint(wallet.address, ethers.parseUnits("1000", "ether"));
      await token
        .connect(wallet)
        .approve(donationAddress, ethers.parseUnits("1000", "ether"));
    }

    for (let i = 1; i < 7; i++) {
      await user.connect(allSigners[i]).createUser(allSigners[i - 1].address);
    }
    for (let index = 0; index < 6; index++) {
      await donation
        .connect(allSigners[index])
        .deposit(ethers.parseUnits("1000", "ether"), true);
    }
    for (let index = 0; index < 6; index++) {
      const baseValue = 6000 - 1000 * index;
      const expectedValue =
        baseValue > 3000
          ? ethers.parseUnits("4000", "ether")
          : ethers.parseUnits(String(baseValue), "ether");

      const actualValue = await donation.getUser(allSigners[index].address);

      expect(actualValue.totalInvestment).to.be.equal(expectedValue);
    }

    await time.increase(15 * 24 * 60 * 60);

    for (let index = 0; index < 6; index++) {
      await donation.connect(allSigners[index]).withdraw();
    }
    token.mint(donationAddress, ethers.parseUnits("35000000", "ether"));
    for (let index = 0; index < 6; index++) {
      await token
        .connect(allSigners[index])
        .approve(donationAddress, ethers.parseUnits("1000", "ether"));
      await donation
        .connect(allSigners[index])
        .deposit(ethers.parseUnits("1000", "ether"), true);
    }
    await time.increase(15 * 24 * 60 * 60);
    for (let index = 0; index < 6; index++) {
      await donation.connect(allSigners[index]).withdraw();
    }
    await time.increase(15 * 24 * 60 * 60);

    for (let index = 0; index < 6; index++) {
      await donation.connect(allSigners[index]).withdraw();
    }
    token.mint(donationAddress, ethers.parseUnits("45000000", "ether"));
    for (let index = 0; index < 6; index++) {
      await token
        .connect(allSigners[index])
        .approve(donationAddress, ethers.parseUnits("1000", "ether"));
      await donation
        .connect(allSigners[index])
        .deposit(ethers.parseUnits("1000", "ether"), true);
    }
    await time.increase(15 * 24 * 60 * 60);
    for (let index = 0; index < 6; index++) {
      await donation.connect(allSigners[index]).withdraw();
    }
    await time.increase(15 * 24 * 60 * 60);

    for (let index = 0; index < 6; index++) {
      await donation.connect(allSigners[index]).withdraw();
    }
    token.mint(donationAddress, ethers.parseUnits("90000000", "ether"));
    for (let index = 0; index < 6; index++) {
      await token
        .connect(allSigners[index])
        .approve(donationAddress, ethers.parseUnits("1000", "ether"));
      await donation
        .connect(allSigners[index])
        .deposit(ethers.parseUnits("1000", "ether"), true);
    }
    await time.increase(15 * 24 * 60 * 60);
    for (let index = 0; index < 6; index++) {
      await donation.connect(allSigners[index]).withdraw();
    }
  });
});
