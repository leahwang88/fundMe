// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {FundMe} from "../src/FundMe.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast, not a real transaction ,no gas
        HelperConfig helpConfig = new HelperConfig();
        address priceFeed = helpConfig.activeNetworkConfig();

        vm.startBroadcast();
        // After startBroadcast, a real transaction ,need gas
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
        return fundMe;
    }

    function deployFundMe() public returns (FundMe, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        address priceFeed = helperConfig
            .getConfigByChainId(block.chainid)
            .priceFeed;

        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
        return (fundMe, helperConfig);
    }
}
