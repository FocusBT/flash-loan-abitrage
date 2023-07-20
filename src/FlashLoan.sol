// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// import {FlashLoanSimpleReceiverBase} from "https://github.com/aave/aave-v3-core/blob/master/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
// import {IPoolAddressesProvider} from "https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPoolAddressesProvider.sol";
// import {IERC20} from "https://github.com/aave/aave-v3-core/blob/master/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
// import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol";

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol";

contract FlashLoan is FlashLoanSimpleReceiverBase {

    ISwapRouter uniswapV3Router;
    ISwapRouter sushiswapV3Router;
    address private usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT address
    address private eth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH address

    address payable owner;

    constructor (address _addressProvider, address _uniswapV3Router, address _sushiswapV3Router)
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
        owner = payable(msg.sender);
        uniswapV3Router = ISwapRouter(_uniswapV3Router);
        sushiswapV3Router = ISwapRouter(_sushiswapV3Router);

    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
        function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Ensure that the asset received is USDT
        require(asset == usdt, "The asset is not USDT");

        // Approve Uniswap Router to spend USDT
        IERC20(usdt).approve(address(uniswapV3Router), amount);

        // Define the path to swap USDT -> ETH (WETH)
        ISwapRouter.ExactInputSingleParams memory swapToETHParams = ISwapRouter.ExactInputSingleParams(
            usdt,
            eth,
            3000, // Pool fee, set as you need
            address(this),
            block.timestamp + 60, // Deadline
            amount,
            0, // Amount out min, setting this to 0 for the example, but you should calculate this value
            0 // Sqrt price limit x96
        );

        // Swap USDT to ETH on Uniswap V3
        uniswapV3Router.exactInputSingle(swapToETHParams);

        // Get the amount of ETH swapped
        uint256 ethAmount = IERC20(eth).balanceOf(address(this));

        // Approve Sushiswap Router to spend ETH
        IERC20(eth).approve(address(sushiswapV3Router), ethAmount);

        // Define the path to swap ETH -> USDT
        ISwapRouter.ExactInputSingleParams memory swapToUSDTParams = ISwapRouter.ExactInputSingleParams(
            eth,
            usdt,
            3000, // Pool fee, set as you need
            address(this),
            block.timestamp + 60, // Deadline
            ethAmount,
            0, // Amount out min, setting this to 0 for the example, but you should calculate this value
            0 // Sqrt price limit x96
        );

        // Swap ETH back to USDT on Sushiswap V3
        sushiswapV3Router.exactInputSingle(swapToUSDTParams);

        // At the end of your logic above, this contract owes
        // the flashloaned amount + premiums.
        uint256 amountOwed = amount + premium;

        // Ensure the contract has enough USDT to repay the flash loan
        require(IERC20(usdt).balanceOf(address(this)) >= amountOwed, "Not enough USDT to repay the loan");

        // Approve the LendingPool contract to pull the owed amount
        IERC20(usdt).approve(address(POOL), amountOwed);

        return true;
    }


    function requestFlashLoan(address _token, uint256 _amount) public {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }



    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}
}