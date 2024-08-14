// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

struct UserStruct {
    bool registered;
    uint8 totalLevels;
    address level1;
    address level2;
    address level3;
    address level4;
    address level5;
    uint totalInvestment;
    bool hasVideo;
}

contract UserBooCash is Ownable {
    event UserAdded(address indexed user, uint indexed timestamp);

    mapping(address => UserStruct) private users;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function createUser(address level1) external {
        _createUser(tx.origin, level1);
    }

    function ownerCreateUser(address user, address level1) external {
        _createUser(user, level1);
    }

    function _createUser(address user, address level1) internal {
        require(level1 != address(0), "Zero address cannot be an affiliate");
        require(
            users[user].registered == false,
            "This user has already been registered"
        );
        require(
            users[level1].registered == true || msg.sender == owner(),
            "Sponsor must be registered"
        );

        UserStruct memory patrocinador = users[level1];
        users[user].registered = true;
        users[user].level1 = level1;
        addLevels(user, patrocinador);
        users[user].totalLevels = patrocinador.totalLevels + 1 <= 5
            ? patrocinador.totalLevels + 1
            : 5;

        emit UserAdded(user, block.timestamp);
    }

    function addLevels(address user, UserStruct memory patrocinador) internal {
        uint8 totalLevels = patrocinador.totalLevels;

        if (totalLevels >= 1) {
            users[user].level2 = patrocinador.level1;
            if (totalLevels >= 2) {
                users[user].level3 = patrocinador.level2;
                if (totalLevels >= 3) {
                    users[user].level4 = patrocinador.level3;
                    if (totalLevels >= 4) {
                        users[user].level5 = patrocinador.level4;
                    }
                }
            }
        }
    }

    function incrementTotalInvestment(address user, uint amount) external {
        users[user].totalInvestment += amount;
    }

    function setVideo(address user, bool value) external {
        users[user].hasVideo = value;
    }

    function getUser(
        address _address
    ) external view returns (UserStruct memory) {
        return users[_address];
    }
}
