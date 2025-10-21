// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library XNTUSDConverter {
    // XNT is only a test-net token and not a real token - the pricefeed for SNX(the Synthetix protocol token) is used instead 
    function getXNTPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xc0F82A46033b8BdBA4Bb0B0e28Bc2006F64355bC);
        (, int price,,,) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function USDToXNT(uint256 _USDAmount) public view returns(uint256, uint256) {
        uint256 XNTPrice = getXNTPrice();

        uint256 standardUnitAmount = (_USDAmount * 1e18) / XNTPrice;
        uint256 readAbleAmount = standardUnitAmount / 1e18;

        return (standardUnitAmount, readAbleAmount);
    }

    function XNTToUSD(uint256 _XNTAmount) public view returns(uint256, uint256) {
        uint256 XNTPrice = getXNTPrice();

        uint256 standardUnitPrice = (_XNTAmount * XNTPrice) / 1e18;
        uint256 readablePrice = standardUnitPrice / 1e18;

        return (standardUnitPrice, readablePrice);
    }
}