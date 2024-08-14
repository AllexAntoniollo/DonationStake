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
    uint32 public paymentDuration = 30 days;
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

    function calculateDurationLocked(
        address user
    ) internal view returns (uint8) {
        // uint8 durationLocked = uint8(
        //     (block.timestamp - users[user].timestampMonths) / paymentDuration
        // );
        // return
        //     (durationLocked + users[user].monthsLocked > 12)
        //         ? 12
        //         : durationLocked;
    }

    function timeUntilNextWithdrawal(
        address user
    ) external view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - users[user].startedTimestamp;

        if (timeElapsed < limitPeriod) {
            return limitPeriod - timeElapsed;
        } else if (timeElapsed < paymentDuration) {
            return paymentDuration - timeElapsed;
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
            users[msg.sender].balance == 0,
            "You can't have more than 1 donation"
        );
        require(
            amount >= 10 ether && amount <= 10000 ether,
            "Amount must be between 10 and 10,000 dollars"
        );

        // if (
        //     users[msg.sender].balance == 0 &&
        //     userBooCash.getUser(msg.sender).registered == false
        // ) {
        //     userBooCash.createUser(address(0), address(0));
        // }
        totalPool += amount;

        userBooCash.incrementTotalInvestment(msg.sender, amount);
        userBooCash.setVideo(msg.sender, false);
        uint totalValue = calculateTotalValue(msg.sender);
        users[msg.sender].balance = totalValue;
        users[msg.sender].startedTimestamp = block.timestamp;
        users[msg.sender].timestamp = block.timestamp;
        users[msg.sender].poolValue = totalPool;

        token.transferFrom(msg.sender, address(this), amount);

        emit UserDeposited(msg.sender, amount, block.timestamp);
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
