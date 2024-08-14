// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUserBooCash.sol";
import "hardhat/console.sol";

library Stake {
    struct UserStake {
        uint balance;
        uint timestamp;
        uint startedTimestamp;
        uint poolValue;
    }
}

contract Donation is ReentrancyGuard, Ownable {
    event UserDeposited(address indexed user, uint amount, uint timestamp);
    event UserWithdrawn(address indexed user, uint amount, uint timestamp);

    IUserBooCash public userBooCash;
    uint public totalPool;
    uint24 public limitPeriod = 15 days;
    IERC20 private immutable token;
    mapping(address => Stake.UserStake) public users;

    constructor(
        address _token,
        address initialOwner,
        address initialUser
    ) Ownable(initialOwner) {
        token = IERC20(_token);
        userBooCash = IUserBooCash(initialUser);
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

    function calculateTotalValue(
        address user
    ) internal view returns (uint balance) {
        if (userBooCash.getUser(user).hasVideo) {
            if (
                users[user].startedTimestamp + 2 * limitPeriod <=
                block.timestamp
            ) {
                return (users[user].balance * 3) / 2;
            } else {
                if (
                    users[user].startedTimestamp + limitPeriod <=
                    block.timestamp
                ) {
                    return (users[user].balance * 6) / 5;
                } else {
                    return users[user].balance;
                }
            }
        } else {
            if (
                users[user].startedTimestamp + 2 * limitPeriod <=
                block.timestamp
            ) {
                return (users[user].balance * 7) / 5;
            } else {
                if (
                    users[user].startedTimestamp + limitPeriod <=
                    block.timestamp
                ) {
                    return (users[user].balance * 6) / 5;
                } else {
                    return users[user].balance;
                }
            }
        }
    }

    function getUser(
        address _user
    ) external view returns (Stake.UserStake memory) {
        Stake.UserStake memory userStake = users[_user];
        userStake.balance = calculateTotalValue(_user);
        return userStake;
    }

    function deposit(uint amount) external nonReentrant {
        require(
            !hasActiveDonation(msg.sender),
            "You can't have more than 1 donation"
        );
        require(
            amount >= 10 ether && amount <= 10000 ether,
            "Amount must be between 10 and 10,000 dollars"
        );

        // TODO: recalcular o totalInvestment dos 100 level1
        totalPool += amount;
        uniLevelDistribution(amount);
        recursiveIncrement(msg.sender, amount, 100);

        userBooCash.setVideo(msg.sender, false);
        uint totalValue = calculateTotalValue(msg.sender);
        users[msg.sender].balance = totalValue;
        users[msg.sender].startedTimestamp = block.timestamp;
        users[msg.sender].timestamp = block.timestamp;
        users[msg.sender].poolValue = totalPool;

        token.transferFrom(msg.sender, address(this), amount);

        emit UserDeposited(msg.sender, amount, block.timestamp);
    }

    function recursiveIncrement(
        address user,
        uint amount,
        uint depth
    ) internal {
        if (depth == 0) {
            return;
        }

        IUserBooCash.UserStruct memory userStruct = userBooCash.getUser(user);
        userBooCash.incrementTotalInvestment(user, amount);

        if (userStruct.level1 != address(0)) {
            recursiveIncrement(userStruct.level1, amount, depth - 1);
        }
    }

    function uniLevelDistribution(uint amount) internal {
        IUserBooCash.UserStruct memory userStruct = userBooCash.getUser(
            msg.sender
        );
        if (totalPool >= 150000000 ether) {
            if (hasActiveDonation(userStruct.level1)) {
                token.transfer(userStruct.level1, amount / 10);
            }
            if (hasActiveDonation(userStruct.level2)) {
                token.transfer(userStruct.level2, amount / 20);
            }
            if (hasActiveDonation(userStruct.level3)) {
                token.transfer(userStruct.level3, (amount * 3) / 100);
            }
            if (hasActiveDonation(userStruct.level4)) {
                token.transfer(userStruct.level4, amount / 50);
            }
            if (hasActiveDonation(userStruct.level5)) {
                token.transfer(userStruct.level5, amount / 100);
            }
        } else if (totalPool >= 75000000 ether) {
            if (hasActiveDonation(userStruct.level1)) {
                token.transfer(userStruct.level1, amount / 20);
            }
            if (hasActiveDonation(userStruct.level2)) {
                token.transfer(userStruct.level2, (amount * 5) / 200);
            }
            if (hasActiveDonation(userStruct.level3)) {
                token.transfer(userStruct.level3, (amount * 3) / 200);
            }
            if (hasActiveDonation(userStruct.level4)) {
                token.transfer(userStruct.level4, amount / 100);
            }
            if (hasActiveDonation(userStruct.level5)) {
                token.transfer(userStruct.level5, amount / 200);
            }
        } else if (totalPool >= 35000000 ether) {
            if (hasActiveDonation(userStruct.level1)) {
                token.transfer(userStruct.level1, (amount * 5) / 200);
            }
            if (hasActiveDonation(userStruct.level2)) {
                token.transfer(userStruct.level2, (amount * 5) / 400);
            }
            if (hasActiveDonation(userStruct.level3)) {
                token.transfer(userStruct.level3, (amount * 75) / 10000);
            }
            if (hasActiveDonation(userStruct.level4)) {
                token.transfer(userStruct.level4, (amount * 50) / 10000);
            }
            if (hasActiveDonation(userStruct.level5)) {
                token.transfer(userStruct.level5, (amount * 50) / 20000);
            }
        } else {
            if (hasActiveDonation(userStruct.level1)) {
                token.transfer(userStruct.level1, amount / 100);
            }
            if (hasActiveDonation(userStruct.level2)) {
                token.transfer(userStruct.level2, (amount) / 200);
            }
            if (hasActiveDonation(userStruct.level3)) {
                token.transfer(userStruct.level3, (amount) / 400);
            }
            if (hasActiveDonation(userStruct.level4)) {
                token.transfer(userStruct.level4, (amount) / 400);
            }
            if (hasActiveDonation(userStruct.level5)) {
                token.transfer(userStruct.level5, (amount) / 400);
            }
        }
    }

    function hasActiveDonation(address user) public view returns (bool) {
        return users[user].balance > 0;
    }

    function withdraw(uint amount) external nonReentrant {
        require(
            users[msg.sender].startedTimestamp + limitPeriod <= block.timestamp,
            "Tokens are still locked"
        );

        uint totalValue = calculateTotalValue(msg.sender);
        require(totalValue >= amount, "Insufficient balance for withdrawal");

        users[msg.sender].balance = totalValue - amount;
        token.transfer(msg.sender, amount);
        emit UserWithdrawn(msg.sender, amount, block.timestamp);
    }
}
