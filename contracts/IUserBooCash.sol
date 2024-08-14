// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IUserBooCash {
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

    function getUser(
        address _address
    ) external view returns (UserStruct memory);

    function totalUsersBooCash() external view returns (uint);

    function allUsersBooCash(uint index) external view returns (address);

    function incrementTotalInvestment(address user, uint amount) external;

    function setVideo(address user, bool value) external;

    function createUser(address level1) external;
}
