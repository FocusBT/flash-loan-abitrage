// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {Script} from "forge-std/Script.sol";
import {FlashLoan} from "../src/FlashLoan.sol";

contract DeployFlashLoan is Script {
    function run() external returns (FlashLoan) {
        vm.startBroadcast();

        FlashLoan flashloan = new FlashLoan(0x0496275d34753A48320CA58103d5220d394FF77F);

        vm.stopBroadcast();
        return flashloan;
    }
}