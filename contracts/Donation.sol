// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUserAidMut.sol";
import "hardhat/console.sol";

library Donation {
    struct UserDonation {
        uint balance;
        uint startedTimestamp;
        uint poolPaymentIndex;
        bool hasVideo;
        uint totalInvestment;
    }
    struct PoolPayment {
        uint level1;
        uint level2;
        uint level3;
        uint level4;
        uint level5;
        uint blockTime;
        uint blockTime2;
        uint blockTime2Video;
    }
}

contract DonationAidMut is ReentrancyGuard, Ownable {
    event UserDeposited(address indexed user, uint amount, uint timestamp);
    event UserWithdrawn(address indexed user, uint amount, uint timestamp);

    IUserAidMut public userAidMut;
    uint24 public limitPeriod = 15 days;

    Donation.PoolPayment[4] public poolPayments;
    IERC20 private immutable token;
    mapping(address => Donation.UserDonation) public users;

    constructor(
        address _token,
        address initialOwner,
        address initialUser
    ) Ownable(initialOwner) {
        token = IERC20(_token);
        userAidMut = IUserAidMut(initialUser);
        poolPayments[0] = Donation.PoolPayment(
            1000,
            500,
            300,
            200,
            100,
            2000,
            4000,
            5000
        );
        poolPayments[1] = Donation.PoolPayment(
            500,
            250,
            150,
            100,
            50,
            1000,
            2000,
            2500
        );
        poolPayments[2] = Donation.PoolPayment(
            250,
            125,
            75,
            50,
            25,
            500,
            1000,
            1250
        );
        poolPayments[3] = Donation.PoolPayment(
            100,
            50,
            25,
            25,
            25,
            100,
            200,
            250
        );
    }

    function setVideo(address user) external onlyOwner {
        users[user].hasVideo = true;
    }

    function timeUntilNextWithdrawal(
        address user
    ) external view returns (uint256) {
        uint256 timeElapsed = block.timestamp - users[user].startedTimestamp;

        if (timeElapsed < limitPeriod) {
            return limitPeriod - timeElapsed;
        } else if (timeElapsed < limitPeriod * 2) {
            return limitPeriod * 2 - timeElapsed;
        } else {
            return 0;
        }
    }

    function deposit(uint amount) external nonReentrant {
        IUserAidMut.UserStruct memory userStruct = userAidMut.getUser(
            msg.sender
        );
        require(userStruct.registered, "Unregistered user");
        require(
            !hasActiveDonation(msg.sender),
            "You can't have more than 1 donation"
        );
        require(
            amount >= 10 ether && amount <= 10000 ether,
            "Amount must be between 10 and 10,000 dollars"
        );
        token.transferFrom(msg.sender, address(this), amount);

        uint totalPool = token.balanceOf(address(this));

        uniLevelDistribution(amount, userStruct);
        recursiveIncrement(msg.sender, amount, 100);

        users[msg.sender].balance = amount;
        users[msg.sender].startedTimestamp = block.timestamp;
        users[msg.sender].hasVideo = false;

        if (totalPool >= 150000000 ether) {
            users[msg.sender].poolPaymentIndex = 0;
        } else if (totalPool >= 75000000 ether) {
            users[msg.sender].poolPaymentIndex = 1;
        } else if (totalPool >= 35000000 ether) {
            users[msg.sender].poolPaymentIndex = 2;
        } else {
            users[msg.sender].poolPaymentIndex = 3;
        }

        emit UserDeposited(msg.sender, amount, block.timestamp);
    }

    function uniLevelDistribution(
        uint amount,
        IUserAidMut.UserStruct memory userStruct
    ) internal {
        Donation.UserDonation memory userDonation = users[msg.sender];
        if (hasActiveDonation(userStruct.level1)) {
            token.transfer(
                userStruct.level1,
                getPercentage(
                    amount,
                    poolPayments[userDonation.poolPaymentIndex].level1
                )
            );
        }
        if (hasActiveDonation(userStruct.level2)) {
            //TotalInvestment >= 500
            token.transfer(
                userStruct.level2,
                getPercentage(
                    amount,
                    poolPayments[userDonation.poolPaymentIndex].level2
                )
            );
        }
        if (hasActiveDonation(userStruct.level3)) {
            //TotalInvestment >= 1000
            token.transfer(
                userStruct.level3,
                getPercentage(
                    amount,
                    poolPayments[userDonation.poolPaymentIndex].level3
                )
            );
        }
        if (hasActiveDonation(userStruct.level4)) {
            //TotalInvestment >= 2000
            token.transfer(
                userStruct.level4,
                getPercentage(
                    amount,
                    poolPayments[userDonation.poolPaymentIndex].level4
                )
            );
        }
        if (hasActiveDonation(userStruct.level5)) {
            //TotalInvestment >= 3000
            token.transfer(
                userStruct.level5,
                getPercentage(
                    amount,
                    poolPayments[userDonation.poolPaymentIndex].level5
                )
            );
        }
    }

    function getPercentage(
        uint amount,
        uint percentage
    ) internal pure returns (uint percentageOfAmounts) {
        if (percentage == 1000) {
            return amount / 10;
        }
        if (percentage == 500) {
            return amount / 20;
        }
        if (percentage == 300) {
            return (amount * 3) / 100;
        }
        if (percentage == 200) {
            return amount / 50;
        }
        if (percentage == 100) {
            return amount / 100;
        }
        if (percentage == 2000) {
            return amount / 5;
        }
        if (percentage == 4000) {
            return (amount * 2) / 5;
        }
        if (percentage == 5000) {
            return (amount) / 2;
        }
        if (percentage == 250) {
            return (amount) / 40;
        }
        if (percentage == 150) {
            return (amount * 3) / 200;
        }
        if (percentage == 50) {
            return (amount) / 200;
        }
        if (percentage == 2500) {
            return (amount) / 4;
        }
        if (percentage == 125) {
            return (amount * 25) / 2000;
        }
        if (percentage == 75) {
            return (amount * 15) / 2000;
        }
        if (percentage == 25) {
            return (amount) / 400;
        }
        if (percentage == 1250) {
            return (amount) / 8;
        }
    }

    function hasActiveDonation(address user) public view returns (bool) {
        return users[user].balance > 0;
    }

    function recursiveIncrement(
        address user,
        uint amount,
        uint depth
    ) internal {
        if (depth == 0) {
            return;
        }
        IUserAidMut.UserStruct memory userStruct = userAidMut.getUser(user);
        if (users[user].totalInvestment <= 3000 ether) {
            users[user].totalInvestment += amount;
        }
        if (userStruct.level1 != address(0)) {
            recursiveIncrement(userStruct.level1, amount, depth - 1);
        }
    }

    function withdraw() external nonReentrant {
        require(
            users[msg.sender].startedTimestamp + limitPeriod <= block.timestamp,
            "Tokens are still locked"
        );

        uint totalValue = calculateTotalValue(msg.sender);

        users[msg.sender].balance = 0;
        token.transfer(msg.sender, totalValue);
        emit UserWithdrawn(msg.sender, totalValue, block.timestamp);
    }

    function getUser(
        address _user
    ) external view returns (Donation.UserDonation memory) {
        Donation.UserDonation memory userDonation = users[_user];
        userDonation.balance = calculateTotalValue(_user);
        return userDonation;
    }

    function calculateTotalValue(
        address user
    ) internal view returns (uint balance) {
        uint multiplier;

        if (users[user].hasVideo) {
            if (
                users[user].startedTimestamp + 2 * limitPeriod <=
                block.timestamp
            ) {
                multiplier = poolPayments[users[user].poolPaymentIndex]
                    .blockTime2Video;
            } else if (
                users[user].startedTimestamp + limitPeriod <= block.timestamp
            ) {
                multiplier = poolPayments[users[user].poolPaymentIndex]
                    .blockTime;
            } else {
                return users[user].balance;
            }
        } else {
            if (
                users[user].startedTimestamp + 2 * limitPeriod <=
                block.timestamp
            ) {
                multiplier = poolPayments[users[user].poolPaymentIndex]
                    .blockTime2;
            } else if (
                users[user].startedTimestamp + limitPeriod <= block.timestamp
            ) {
                multiplier = poolPayments[users[user].poolPaymentIndex]
                    .blockTime;
            } else {
                return users[user].balance;
            }
        }

        return
            users[user].balance +
            getPercentage(users[user].balance, multiplier);
    }
}
