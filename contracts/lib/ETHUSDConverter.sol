
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library ETHUSDConverter {
    function getETHPrice() public view returns (uint256) {
        // todo: make the feed address dynamic to permit testing and usage on multiple chains
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int price,,,) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function USDToETH(uint256 _USDAmount) public view returns(uint256, uint256) {
        uint256 ETHPrice = getETHPrice();

        uint256 standardUnitAmount = (_USDAmount * 1e18) / ETHPrice;
        uint256 readAbleAmount = standardUnitAmount / 1e18;

        return (standardUnitAmount, readAbleAmount);
    }

    function ETHToUSD(uint256 _ETHAmount) public view returns(uint256, uint256) {
        uint256 ETHPrice = getETHPrice();

        uint256 standardUnitPrice = (_ETHAmount * ETHPrice) / 1e18;
        uint256 readablePrice = standardUnitPrice / 1e18;

        return (standardUnitPrice, readablePrice);
    }
}
