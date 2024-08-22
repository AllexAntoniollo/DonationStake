// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUserAidMut.sol";
import "./IUniswapAidMut.sol";

library Donation {
    struct UserDonation {
        uint balance;
        uint startedTimestamp;
        uint poolPaymentIndex;
        bool hasVideo;
        uint[5] totalInvestment;
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
    using SafeERC20 for IERC20;

    event UserDonated(address indexed user, uint amount);
    event ChangedBot(address indexed user);
    event UserClaimed(address indexed user, uint amount);

    IUserAidMut public immutable userAidMut;
    uint24 public constant limitPeriod = 15 days;
    IUniswapAidMut public uniswapOracle;

    Donation.PoolPayment[4] public poolPayments;
    IERC20 private immutable token;
    address walletBot;
    mapping(address => Donation.UserDonation) private users;
    mapping(address => bool) private blacklist;

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

    modifier onlyBot() {
        require(msg.sender == walletBot, "Only bot can call this function");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "Address is blacklisted");
        _;
    }

    function setWalletBot(address _address) external onlyOwner {
        walletBot = _address;
        emit ChangedBot(_address);
    }

    function getContractPoolBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function setUniswapOracle(address _address) external onlyOwner {
        uniswapOracle = IUniswapAidMut(_address);
    }

    function addVideo(address user) external onlyBot {
        users[user].hasVideo = true;
    }

    function removeVideo(address user) external onlyBot {
        users[user].hasVideo = false;
    }

    function addToBlacklist(address user) external onlyBot {
        blacklist[user] = true;
    }

    function removeFromBlacklist(address user) external onlyBot {
        blacklist[user] = false;
    }

    function isBlacklisted(address user) external view returns (bool) {
        return blacklist[user];
    }

    function timeUntilNextWithdrawal(
        address user
    ) external view notBlacklisted returns (uint256) {
        uint256 timeElapsed = block.timestamp - users[user].startedTimestamp;

        if (timeElapsed < limitPeriod) {
            return limitPeriod - timeElapsed;
        } else if (timeElapsed < limitPeriod * 2) {
            return limitPeriod * 2 - timeElapsed;
        } else {
            return 0;
        }
    }

    function donate(uint128 amount) external nonReentrant notBlacklisted {
        IUserAidMut.UserStruct memory userStruct = userAidMut.getUser(
            msg.sender
        );
        require(userStruct.registered, "Unregistered user");
        require(
            !hasActiveDonation(msg.sender),
            "You cannot have more than 1 donation"
        );
        uint amountUsdt = uniswapOracle.estimateAmountOut(amount);

        require(
            amountUsdt >= 10 ether && amountUsdt <= 10000 ether,
            "Amount must be between 10 and 10,000 dollars"
        );
        uint totalPool = getContractPoolBalance();

        users[msg.sender].balance = amount;
        users[msg.sender].startedTimestamp = block.timestamp;
        users[msg.sender].hasVideo = false;

        users[msg.sender].poolPaymentIndex = (totalPool >= 15e7 ether)
            ? 0
            : (totalPool >= 75e6 ether)
            ? 1
            : (totalPool >= 35e6 ether)
            ? 2
            : 3;

        recursiveIncrement(userStruct, amountUsdt);
        uniLevelDistribution(amount, userStruct);

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit UserDonated(msg.sender, amount);
    }

    function uniLevelDistribution(
        uint amount,
        IUserAidMut.UserStruct memory userStruct
    ) internal {
        Donation.UserDonation memory userDonation = users[msg.sender];
        if (hasActiveDonation(userStruct.level1)) {
            token.safeTransfer(
                userStruct.level1,
                getPercentage(
                    amount,
                    poolPayments[userDonation.poolPaymentIndex].level1
                )
            );
        }
        if (
            hasActiveDonation(userStruct.level2) &&
            users[userStruct.level2].totalInvestment[1] >= 500 ether
        ) {
            token.safeTransfer(
                userStruct.level2,
                getPercentage(
                    amount,
                    poolPayments[userDonation.poolPaymentIndex].level2
                )
            );
        }
        if (
            hasActiveDonation(userStruct.level3) &&
            users[userStruct.level3].totalInvestment[2] >= 1000 ether
        ) {
            token.safeTransfer(
                userStruct.level3,
                getPercentage(
                    amount,
                    poolPayments[userDonation.poolPaymentIndex].level3
                )
            );
        }
        if (
            hasActiveDonation(userStruct.level4) &&
            users[userStruct.level4].totalInvestment[3] >= 2000 ether
        ) {
            token.safeTransfer(
                userStruct.level4,
                getPercentage(
                    amount,
                    poolPayments[userDonation.poolPaymentIndex].level4
                )
            );
        }
        if (
            hasActiveDonation(userStruct.level5) &&
            users[userStruct.level5].totalInvestment[4] >= 3000 ether
        ) {
            token.safeTransfer(
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

    function hasActiveDonation(address user) internal view returns (bool) {
        return users[user].balance > 0;
    }

    function recursiveIncrement(
        IUserAidMut.UserStruct memory user,
        uint amount
    ) internal {
        if (user.level1 != address(0)) {
            users[user.level1].totalInvestment[0] += amount;
        }
        if (user.level2 != address(0)) {
            users[user.level2].totalInvestment[1] += amount;
        }
        if (user.level3 != address(0)) {
            users[user.level3].totalInvestment[2] += amount;
        }
        if (user.level4 != address(0)) {
            users[user.level4].totalInvestment[3] += amount;
        }
        if (user.level5 != address(0)) {
            users[user.level5].totalInvestment[4] += amount;
        }
    }

    function claimDonation() external nonReentrant notBlacklisted {
        require(
            users[msg.sender].startedTimestamp + limitPeriod <= block.timestamp,
            "Tokens are still locked"
        );

        uint totalValue = calculateTotalValue(msg.sender);

        users[msg.sender].balance = 0;
        token.safeTransfer(msg.sender, totalValue);
        emit UserClaimed(msg.sender, totalValue);
    }

    function getUser(
        address _user
    ) external view notBlacklisted returns (Donation.UserDonation memory) {
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
