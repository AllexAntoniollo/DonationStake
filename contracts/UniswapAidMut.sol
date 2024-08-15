// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

contract UniswapAidMut {
    address public poolMutWmatic;
    address public poolWmaticUsdt;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }

    function setPoolMutWmatic(uint24 _fee) external onlyOwner {
        address _pool = IUniswapV3Factory(
            0x1F98431c8aD98523631AE4a59f267346ea31F984
        ).getPool(
                0xe4FeAb21b42919C5C960ed2B4BdFFc521E26881f, //MUT
                0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, //WMATIC
                _fee
            );
        require(_pool != address(0), "pool doesn't exist");

        poolMutWmatic = _pool;
    }

    function setPoolWmaticUsdt(uint24 _fee) external onlyOwner {
        address _pool = IUniswapV3Factory(
            0x1F98431c8aD98523631AE4a59f267346ea31F984
        ).getPool(
                0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, //WMATIC
                0xc2132D05D31c914a87C6611C10748AEb04B58e8F, //USDT
                _fee
            );
        require(_pool != address(0), "pool doesn't exist");

        poolWmaticUsdt = _pool;
    }

    function estimateAmountOut(
        uint128 amountIn
    ) external view returns (uint amountOut) {
        require(poolMutWmatic != address(0), "MUT/WMATIC pool not set");
        require(poolWmaticUsdt != address(0), "WMATIC/USDT pool not set");

        (int24 tickMutWmatic, ) = OracleLibrary.consult(poolMutWmatic, 10);
        uint amountOutInWmatic = OracleLibrary.getQuoteAtTick(
            tickMutWmatic,
            amountIn,
            0xe4FeAb21b42919C5C960ed2B4BdFFc521E26881f, //MUT
            0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270 // WMATIC address
        );

        (int24 tickWmaticUsdt, ) = OracleLibrary.consult(poolWmaticUsdt, 10);
        amountOut = OracleLibrary.getQuoteAtTick(
            tickWmaticUsdt,
            uint128(amountOutInWmatic),
            0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, // WMATIC address
            0xc2132D05D31c914a87C6611C10748AEb04B58e8F //USDT
        );
        return amountOut * 1e12;
    }
}
