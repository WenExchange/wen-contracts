//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBlast{
    // base configuration options
    function configureClaimableYield() external;
    function configureClaimableYieldOnBehalf(address contractAddress) external;
    function configureAutomaticYield() external;
    function configureAutomaticYieldOnBehalf(address contractAddress) external;
    function configureVoidYield() external;
    function configureVoidYieldOnBehalf(address contractAddress) external;
    function configureClaimableGas() external;
    function configureClaimableGasOnBehalf(address contractAddress) external;
    function configureVoidGas() external;
    function configureVoidGasOnBehalf(address contractAddress) external;
    function configureGovernor(address _governor) external;
    function configureGovernorOnBehalf(address _newGovernor, address contractAddress) external;

    // claim yield
    function claimYield(address contractAddress, address recipientOfYield, uint256 amount) external returns (uint256);
    function claimAllYield(address contractAddress, address recipientOfYield) external returns (uint256);

    // claim gas
    function claimAllGas(address contractAddress, address recipientOfGas) external returns (uint256);
    function claimGasAtMinClaimRate(address contractAddress, address recipientOfGas, uint256 minClaimRateBips) external returns (uint256);
    function claimMaxGas(address contractAddress, address recipientOfGas) external returns (uint256);
    function claimGas(address contractAddress, address recipientOfGas, uint256 gasToClaim, uint256 gasSecondsToConsume) external returns (uint256);

    // read functions
    function readClaimableYield(address contractAddress) external view returns (uint256);
    function readYieldConfiguration(address contractAddress) external view returns (uint8);
}

interface IwenETHToken is IERC20Upgradeable {
    function mint(address _to, uint256 _value) external returns (bool);
    function burn(address _from, uint256 _value) external returns (bool);
}




contract WenTradePoolV1 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IwenETHToken;

    /* ========== STATE VARIABLES ========== */

    /// @notice wenETH token which can be minted in WenTradePool.
    IwenETHToken public wenETH;

    /// @notice Blast Contract
    IBlast public blast;

    mapping(address => bool) public operators;

    event Unstake(uint256 redeemedwenETH, uint256 ETHQueued);
    event Stake(uint256 stakedETH, uint256 mintedwenETH);
    event FeesReceived(uint256 amount);

    /* ========== Restricted Function  ========== */

    function setInitialInfo(
        address _wenETH,
        address _blast
    ) external onlyOwner {
        wenETH = IwenETHToken(_wenETH);
        blast = IBlast(_blast);
        blast.configureClaimableYield();
        blast.configureClaimableGas();
    }

    /**
        @notice Set Blast address
     */
    function setBlast(address _blast) external onlyOwner {
        blast = IBlast(_blast);
    }
    

    /**
        @notice Initialize UUPS upgradeable smart contract.
     */
    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    

   /**
    @notice Set blast governor which is approved for cliaming gas fees. 
    @param _governor governor address
     */
    function setBlastGovernor(address _governor) external onlyOwner {
        blast.configureGovernor(_governor);
    }
    

    /**
        @notice Claim Yield for specific amount. 
     */
    function claimYield(address recipient, uint256 amount) external onlyOperator{
        uint256 yield = blast.claimYield(address(this), recipient, amount);
        emit FeesReceived(yield);
    }


    /**
        @notice Claim all yields. This will be called by operator regularly.
     */
	function claimAllYield(address recipient) external onlyOperator{
        require(operators[msg.sender], "Not a operators");
        uint256 yield = blast.claimAllYield(address(this), recipient);
        emit FeesReceived(yield);
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

    /**
        @notice pause contract functions.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
        @notice unpause contract functions.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
    @notice Approve contracts to mint and renounce ownership
    @dev In production the only minters should be `SIGFarm`
             Addresses are given via dynamic array to allow extra minters during testing
     */
    function setOperator(address[] calldata _operators) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++) {
            operators[_operators[i]] = true;
        }
    }

    /**
     @notice Revoke authority to mint and burn the given token.
     */
    function revokeOperator(address _operator) external onlyOwner {
        require(operators[_operator], "This address is not an operator");
        operators[_operator] = false;
    }

    /* ========== External Function  ========== */

    /**
        @notice stake ETH for wenETH
     */
    function stake() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Stake ETH amount should be bigger than 0");
        uint256 _amount = msg.value; // 이더의 양은 msg.value를 통해 얻음
        uint256 ETHAmount = address(this).balance - _amount;
        uint256 wenETHAmount = wenETH.totalSupply();

        uint256 wenETHToGet;
        if (ETHAmount == 0) {
            wenETHToGet = _amount;
        } else {
            wenETHToGet = (_amount * wenETHAmount * 1e18) / ETHAmount;
            wenETHToGet /= 1e18;
        }

        wenETH.mint(msg.sender, wenETHToGet);

        emit Stake(_amount, wenETHToGet);
    }

    /**
        @notice Return wenETH for ETH which is compounded over time. It needs unlocking period.
        @param _amount The amount of wenETH to redeem
     */
    function unstake(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Redeem wenETH should be bigger than 0");
        require(
            wenETH.balanceOf(msg.sender) >= _amount,
            "Not enough wenETH amount to unstake."
        );
        wenETH.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 ETHAmount = address(this).balance;
        uint256 wenETHAmount = wenETH.totalSupply();

        uint256 ETHToReturn = (_amount * ETHAmount * 1e18) / wenETHAmount;

        ETHToReturn /= 1e18;

        wenETH.burn(address(this), _amount);
        payable(msg.sender).transfer(ETHToReturn);

        emit Unstake(_amount, ETHToReturn);
    }

    receive() external payable {}

    fallback() external payable {}


    /* ========== View Function  ========== */

    /**
        @notice You should devide return value by 10^7 to get a right number.
     */
    function getwenETHExchangeRate() external view returns (uint256) {
        uint256 ETHAmount = address(this).balance;
        if (ETHAmount == 0) {
            return 1 * 1e7;
        } else {
            uint256 wenETHAmount = wenETH.totalSupply();
            return (ETHAmount * 1e7) / wenETHAmount;
        }
    }

    function ethToWenETH(uint256 inputETH) external view returns (uint256) {
        uint256 ETHAmount = address(this).balance;
        if (ETHAmount == 0) {
            return inputETH;
        } else {
            uint256 wenETHAmount = wenETH.totalSupply();
            return ((wenETHAmount * 1e18 * inputETH) / ETHAmount)/1e18;
        }
    }

    //TODO: DELETE
    function getCurrentEthBalance() external view returns (uint256) {
        return address(this).balance;
    }

    modifier onlyOperator() {
         require(operators[msg.sender], "Not a operators");
         _;
    }
}
