// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IUserAidMut {
    struct UserStruct {
        bool registered;
        address level1;
        address level2;
        address level3;
        address level4;
        address level5;
    }

    function getUser(
        address _address
    ) external view returns (UserStruct memory);

    function totalUsersBooCash() external view returns (uint);

    function allUsersBooCash(uint index) external view returns (address);

    function createUser(address level1) external;
}
