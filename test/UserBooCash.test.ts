import {
  loadFixture,
  time,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("UserAidMut", function () {
  async function deployFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const User = await ethers.getContractFactory("UserAidMut");
    const user = await User.deploy(owner.address);
    const userAddress = await user.getAddress();

    return { owner, otherAccount, user, userAddress };
  }

  it("Should create user", async function () {
    const { owner, otherAccount, user, userAddress } = await loadFixture(
      deployFixture
    );
    await user.connect(otherAccount).createUser(owner.address);
  });
  it("Should create user default level1", async function () {
    const { owner, otherAccount, user, userAddress } = await loadFixture(
      deployFixture
    );
    await user.connect(otherAccount).createUser(otherAccount.address);
  });

  it("Should owner create user", async function () {
    const { owner, otherAccount, user, userAddress } = await loadFixture(
      deployFixture
    );
    await user.ownerCreateUser(otherAccount, owner.address);
  });
  it("Should not owner create user (double registered)", async function () {
    const { owner, otherAccount, user, userAddress } = await loadFixture(
      deployFixture
    );
    await user.ownerCreateUser(otherAccount, owner.address);
    await expect(
      user.ownerCreateUser(otherAccount, owner.address)
    ).to.be.revertedWith("This user has already been registered");
  });

  it("Should create a user with 6 levels", async function () {
    const { owner, otherAccount, user, userAddress } = await loadFixture(
      deployFixture
    );

    const allSigners = [owner];
    for (let i = 0; i < 6; i++) {
      const wallet = ethers.Wallet.createRandom().connect(ethers.provider);
      allSigners.push(wallet);

      await owner.sendTransaction({
        to: wallet.address,
        value: ethers.parseEther("1.0"),
      });
    }

    for (let i = 1; i < 7; i++) {
      await user.connect(allSigners[i]).createUser(allSigners[i - 1].address);
    }

    const user25 = await user.getUser(allSigners[5].address);
    const user26 = await user.getUser(allSigners[6].address);

    expect(user25.level1).to.equal(allSigners[4].address);
    expect(user26.level1).to.equal(allSigners[5].address);
  });
});
