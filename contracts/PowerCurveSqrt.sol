// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICurve} from "./ICurve.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

contract PowerCurveSqrt is ICurve {
    using FixedPointMathLib for uint256;

    uint256 public constant MIN_PRICE = 1000000 wei;

    function validateSpotPrice(
        uint256 spotPrice
    ) external pure override returns (bool) {
        return spotPrice >= MIN_PRICE;
    }

    function getSpotPrice(
        uint256 currentCirculation,
        uint256 m,
        uint256 c
    ) public pure override returns (uint256 spotPrice) {
        spotPrice =
            (currentCirculation * FixedPointMathLib.WAD * FixedPointMathLib.WAD)
                .sqrt()
                .mulWadUp(m) +
            c;
    }

    function getSellPrice(
        uint256 currentCirculation,
        uint256 m,
        uint256 c,
        uint256 totalFeeMultiplier
    ) public pure override returns (uint256 sellPrice) {
        uint256 spotPrice = (currentCirculation *
            FixedPointMathLib.WAD *
            FixedPointMathLib.WAD).sqrt().mulWadUp(m) + c;
        sellPrice = spotPrice - spotPrice.mulWadUp(totalFeeMultiplier);
    }

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
        pure
        override
        returns (
            Error error,
            uint256 inputValue,
            uint256 tradeFee,
            uint256 protocolFee,
            uint256 dividendFee
        )
    {
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0);
        }

        for (uint256 i = 0; i < numItems; ++i) {
            inputValue += getSpotPrice(startingCirculation + i, m, c);
        }

        protocolFee = inputValue.mulWadUp(protocolFeeMultiplier);
        tradeFee = inputValue.mulWadUp(feeMultiplier);
        dividendFee = inputValue.mulWadUp(dividendFeeMultiplier);

        error = Error.OK;
    }

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
        pure
        override
        returns (
            Error error,
            uint256 outputValue,
            uint256 tradeFee,
            uint256 protocolFee,
            uint256 dividendFee
        )
    {
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0);
        }

        if (numItems > startingCirculation) {
            return (Error.INSUFFICIENT_CIRCULATION, 0, 0, 0, 0);
        }

        for (uint256 i = 0; i < numItems; ++i) {
            outputValue += getSellPrice(
                startingCirculation - i - 1,
                m,
                c,
                feeMultiplier + protocolFeeMultiplier + dividendFeeMultiplier
            );
        }

        protocolFee = outputValue.mulWadUp(protocolFeeMultiplier);
        tradeFee = outputValue.mulWadUp(feeMultiplier);
        dividendFee = outputValue.mulWadUp(dividendFeeMultiplier);
        outputValue -= protocolFee + tradeFee + dividendFee;

        error = Error.OK;
    }
}
