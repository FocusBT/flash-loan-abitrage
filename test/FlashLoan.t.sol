// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FlashLoan} from "../src/FlashLoan.sol";

contract FlashTester is Test {
    FlashLoan public flashloan;

    function setUp() public {
        flashloan = new FlashLoan(0x0496275d34753A48320CA58103d5220d394FF77F);

    }

    function testIncrement() public {
        flashloan.requestFlashLoan(0xda9d4f9b69ac6C22e444eD9aF0CfC043b7a7f53f, 1000);
    }

    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
