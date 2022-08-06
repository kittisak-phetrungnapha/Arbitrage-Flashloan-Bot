// SPDX-License-Identifier: MIT
pragma solidity <=0.8.15;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDODO {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external returns (address);
}

contract BscArbitrage {
    IUniswapV2Router02 public immutable apeRouter;
    IUniswapV2Router02 public immutable pancakeRouter;

    address public owner;

    constructor(address _apeRouter, address _pancakeRouter) {
        apeRouter = IUniswapV2Router02(_apeRouter); // ApeSwap
        pancakeRouter = IUniswapV2Router02(_pancakeRouter); // PancakeSwap
        owner = msg.sender;
    }

    function executeTrade(
        bool _startOnPancakeSwap,
        address _loanToken,
        address _pool,
        uint256 _flashAmount
    ) external {
        address flashLoanBase = IDODO(_pool)._BASE_TOKEN_();
        address quoteToken = IDODO(_pool)._QUOTE_TOKEN_();
        uint256 balanceBefore = IERC20(_loanToken).balanceOf(address(this));

        bytes memory data = abi.encode(
            _startOnPancakeSwap,
            _loanToken,
            quoteToken,
            _pool,
            _flashAmount,
            balanceBefore
        );

        if (flashLoanBase == _loanToken) {
            IDODO(_pool).flashLoan(_flashAmount, 0, address(this), data);
        } else {
            IDODO(_pool).flashLoan(0, _flashAmount, address(this), data);
        }
    }

    function DVMFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function DSPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        _flashLoanCallBack(sender, baseAmount, quoteAmount, data);
    }

    function _flashLoanCallBack(
        address sender,
        uint256,
        uint256,
        bytes calldata data
    ) internal {
        (
            bool startOnPancakeSwap,
            address loanToken,
            address quoteToken,
            address pool,
            uint256 flashAmount,
            uint256 balanceBefore
        ) = abi.decode(
                data,
                (bool, address, address, address, uint256, uint256)
            );

        require(
            sender == address(this) && msg.sender == pool,
            "HANDLE_FLASH_DENIED"
        );

        uint256 balanceAfter = IERC20(loanToken).balanceOf(address(this));

        require(
            balanceAfter - balanceBefore == flashAmount,
            "contract did not get the loan"
        );

        address[] memory path = new address[](2);

        path[0] = loanToken;
        path[1] = quoteToken;

        if (startOnPancakeSwap) {
            _swapOnPancakeSwap(path, flashAmount, 0);

            path[0] = quoteToken;
            path[1] = loanToken;

            _swapOnApeSwap(
                path,
                IERC20(quoteToken).balanceOf(address(this)),
                flashAmount
            );
        } else {
            _swapOnApeSwap(path, flashAmount, 0);

            path[0] = quoteToken;
            path[1] = loanToken;

            _swapOnPancakeSwap(
                path,
                IERC20(quoteToken).balanceOf(address(this)),
                flashAmount
            );
        }

        IERC20(loanToken).transfer(
            owner,
            IERC20(loanToken).balanceOf(address(this)) - flashAmount
        );

        IERC20(loanToken).transfer(pool, flashAmount);
    }

    // -- INTERNAL FUNCTIONS -- //

    function _swapOnPancakeSwap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _amountOut
    ) internal {
        require(
            IERC20(_path[0]).approve(address(pancakeRouter), _amountIn),
            "PancakeSwap approval failed."
        );

        pancakeRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOut,
            _path,
            address(this),
            (block.timestamp + 1200)
        );
    }

    function _swapOnApeSwap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _amountOut
    ) internal {
        require(
            IERC20(_path[0]).approve(address(apeRouter), _amountIn),
            "ApeSwap approval failed."
        );

        apeRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOut,
            _path,
            address(this),
            (block.timestamp + 1200)
        );
    }
}
