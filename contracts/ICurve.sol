// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurve {

    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        INSUFFICIENT_CIRCULATION
    }

    function validateSpotPrice(uint256 newSpotPrice) external view returns (bool valid);

    function getSpotPrice(uint256 currentCirculation, uint256 m, uint256 c) external pure returns (uint256 spotPrice); 

    function getSellPrice(uint256 currentCirculation, uint256 m, uint256 c, uint256 totalFeeMultiplier) external pure returns (uint256 sellPrice); 

    function getBuyInfo(
        uint256 startingCirculation,
        uint256 m,
        uint256 c,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier,
        uint256 dividendFeeMultiplier
    )
        external
        view
        returns (
            Error error,
            uint256 inputValue,
            uint256 tradeFee,
            uint256 protocolFee,
            uint256 dividendFee
        );
        
    function getSellInfo(
        uint256 startingCirculation,
        uint256 m,
        uint256 c,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier,
        uint256 dividendFeeMultiplier
    )
        external
        view
        returns (
            Error error,
            uint256 outputValue,
            uint256 tradeFee,
            uint256 protocolFee,
            uint256 dividendFee
        );
}