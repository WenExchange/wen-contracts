//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract WenTreasuryV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Triggered when an amount of an ERC20 has been transferred from this contract to an address
     *
     * @param token               ERC20 token address
     * @param to                  Address of the receiver
     * @param amount              Amount of the transaction
     */
    event TransferERC20(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @notice Triggered when an amount of an ETH has been transferred from this contract to an address
     *
     * @param to                  Address of the receiver
     * @param amount              Amount of the transaction
     */
    event TransferETH(address indexed to, uint256 amount);

    /**
        @notice Receive ETH
     */
    receive() external payable {}

    /**
     * @notice Used to initialize a new Treasury contract
     */
    /**
        @notice Initialize UUPS upgradeable smart contract.
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
        @notice restrict upgrade to only owner.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    function setInitialInfo() external onlyOwner {
    }

    /**
     * @notice Transfers an amount of an ERC20 from this contract to an address
     *
     * @param _token address of the ERC20 token
     * @param _to address of the receiver
     * @param _amount amount of the transaction
     */
    function transferERC20(
        IERC20Upgradeable _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _token.safeTransfer(_to, _amount);

        emit TransferERC20(address(_token), _to, _amount);
    }

    function approveToken(address _token, address _to) external onlyOwner {
        IERC20Upgradeable(_token).approve(address(_to), type(uint256).max);
    }

    /**
        @notice Withdraw the contract's KSUDT balance at the end of the launch.
     */
    function transferETH(address _to, uint256 _amount) external onlyOwner {
        uint256 balanceOfETH = address(this).balance;
        require(
            balanceOfETH >= _amount,
            "There is no withdrawable amount of ETH"
        );

        payable(_to).transfer(_amount);
        emit TransferETH(_to, _amount);
    }

}