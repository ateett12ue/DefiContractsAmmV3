// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.20;

import '@cryptoalgebra/integral-periphery/contracts/interfaces/ISwapRouter.sol';
import '@cryptoalgebra/integral-periphery/contracts/libraries/TransferHelper.sol';

contract SimpleSwap {
    ISwapRouter public immutable swapRouter;
    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }
    
    function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) {

        // Transfer the specified amount of MATIC to this contract.
        TransferHelper.safeTransferFrom(WMATIC, msg.sender, address(this), amountIn);
        // Approve the router to spend MATIC.
        TransferHelper.safeApprove(WMATIC, address(swapRouter), amountIn);
        uint256 minOut = 0; /* Calculate min output */
        uint160 priceLimit = 0; /* Calculate price limit */ 
        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WMATIC,
                tokenOut: DAI,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: minOut,
                limitSqrtPrice: priceLimit
            });
        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external returns(uint256 amountIn) {
        
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountInMaximum);
        TransferHelper.safeApprove(DAI, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: DAI,
                tokenOut: WMATIC,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                limitSqrtPrice: 0
            });
         amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(DAI, address(swapRouter), 0);
            TransferHelper.safeTransfer(DAI, msg.sender, amountInMaximum - amountIn);
        }
    }

    function swapExactInputMultihop(uint256 amountIn) external returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountIn);

        // Approve the router to spend DAI.
        TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(DAI, USDC, WMATIC),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        // Executes the swap.
        amountOut = swapRouter.exactInput(params);
    }

    /// @notice swapExactOutputMultihop swaps a minimum possible amount of DAI for a fixed amount of WMATIC through an intermediary pool.
    /// For this example, we want to swap DAI for WMATIC through a USDC pool but we specify the desired amountOut of WMATIC. Notice how the path encoding is slightly different in for exact output swaps.
    /// @dev The calling address must approve this contract to spend its DAI for this function to succeed. As the amount of input DAI is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The desired amount of WMATIC.
    /// @param amountInMaximum The maximum amount of DAI willing to be swapped for the specified amountOut of WMATIC.
    /// @return amountIn The amountIn of DAI actually spent to receive the desired amountOut.
    function swapExactOutputMultihop(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        // Transfer the specified `amountInMaximum` to this contract.
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountInMaximum);
        // Approve the router to spend  `amountInMaximum`.
        TransferHelper.safeApprove(DAI, address(swapRouter), amountInMaximum);

        // The parameter path is encoded as (tokenOut, tokenIn/tokenOut, tokenIn)
        // The tokenIn/tokenOut field is the shared token between the two pools used in the multiple pool swap. In this case USDC is the "shared" token.
        // For an exactOutput swap, the first swap that occurs is the swap which returns the eventual desired token.
        // In this case, our desired output token is WMATIC so that swap happens first, and is encoded in the path accordingly.
        ISwapRouter.ExactOutputParams memory params =
            ISwapRouter.ExactOutputParams({
                path: abi.encodePacked(WMATIC, USDC, DAI),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            });

        // Executes the swap, returning the amountIn actually spent.
        amountIn = swapRouter.exactOutput(params);

        // If the swap did not require the full amountInMaximum to achieve the exact amountOut then we refund msg.sender and approve the router to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(DAI, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(DAI, address(this), msg.sender, amountInMaximum - amountIn);
        }
    }
}