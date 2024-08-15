// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
struct UserStruct {
    bool registered;
    address level1;
    address level2;
    address level3;
    address level4;
    address level5;
}

contract UserAidMut is Ownable {
    event UserAdded(address indexed user, uint indexed timestamp);

    mapping(address => UserStruct) private users;

    address public constant defaultUser = address(0);

    constructor(address initialOwner) Ownable(initialOwner) {
        users[initialOwner].registered = true;
    }

    function createUser(address level1) external {
        _createUser(tx.origin, level1);
    }

    function ownerCreateUser(address user, address level1) external {
        _createUser(user, level1);
    }

    function _createUser(address user, address level1) internal {
        require(
            users[user].registered == false,
            "This user has already been registered"
        );

        if (users[level1].registered == false) {
            level1 = defaultUser;
        }

        UserStruct memory patrocinador = users[level1];
        users[user].registered = true;
        users[user].level1 = level1;
        addLevels(user, patrocinador);

        emit UserAdded(user, block.timestamp);
    }

    function addLevels(address user, UserStruct memory patrocinador) internal {
        users[user].level2 = patrocinador.level1;
        users[user].level3 = patrocinador.level2;
        users[user].level4 = patrocinador.level3;
        users[user].level5 = patrocinador.level4;
    }

    function getUser(
        address _address
    ) external view returns (UserStruct memory) {
        return users[_address];
    }
}
