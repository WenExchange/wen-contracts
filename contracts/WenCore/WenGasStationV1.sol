//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBlast {
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

    function configureGovernorOnBehalf(
        address _newGovernor,
        address contractAddress
    ) external;

    // claim yield
    function claimYield(
        address contractAddress,
        address recipientOfYield,
        uint256 amount
    ) external returns (uint256);

    function claimAllYield(
        address contractAddress,
        address recipientOfYield
    ) external returns (uint256);

    // claim gas
    function claimAllGas(
        address contractAddress,
        address recipientOfGas
    ) external returns (uint256);

    function claimGasAtMinClaimRate(
        address contractAddress,
        address recipientOfGas,
        uint256 minClaimRateBips
    ) external returns (uint256);

    function claimMaxGas(
        address contractAddress,
        address recipientOfGas
    ) external returns (uint256);

    function claimGas(
        address contractAddress,
        address recipientOfGas,
        uint256 gasToClaim,
        uint256 gasSecondsToConsume
    ) external returns (uint256);

    // read functions
    function readClaimableYield(
        address contractAddress
    ) external view returns (uint256);

    function readYieldConfiguration(
        address contractAddress
    ) external view returns (uint8);
}

contract WenGasStationV1 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct FeeReceiverContract {
        address receiver;
        uint256 percent;
    }

    struct FeeGiverContract {
        address giver;
    }

    /* ========== STATE VARIABLES ========== */

    /// @notice Blast Contract
    IBlast public blast;

    /// @notice Fee Receiver contract list.
    FeeReceiverContract[] public feeReceivers;

    /// @notice Fee giver contract list. (Contracts where fees are collected.)
    FeeGiverContract[] public feeGivers;

    /// @notice Operators that collect and distribute fees.
    mapping(address => bool) public operators;

    event FeesReceived(uint256 amount);
    event FeesDistributed(address contractAddress, uint256 amount);
    event FeesCollected(address contractAddress, uint256 amount);
    event YieldClaimed(address contractAddress, address receipient, uint256 amount);

    /* ========== Restricted Function  ========== */

    function setInitialInfo(address _blast) external onlyOwner {
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
     /**
        @notice Claim Yield for specific amount. 
     */
    function claimYield(
        address recipient,
        uint256 amount
    ) external onlyOperator {
        uint256 yield = blast.claimYield(address(this), recipient, amount);
        emit FeesReceived(yield);
    }

    /**
        @notice Claim all yields. This will be called by operator regularly.
     */
    function claimAllYield(address recipient) external onlyOperator {
        require(operators[msg.sender], "Not a operators");
        uint256 yield = blast.claimAllYield(address(this), recipient);
        emit FeesReceived(yield);
    }

    /**
        @notice restrict upgrade to only owner.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}

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

    /**
     @notice Add Fee Receiver Contract
     */
    function addFeeReceiver(
        address _receiver,
        uint256 _percent
    ) external onlyOwner {
        require(_receiver != address(0), "Invalid receiver address");
        feeReceivers.push(FeeReceiverContract(_receiver, _percent));
    }

    /**
     @notice Remove Fee Receiver Contract
     */
    function removeFeeReceiver(address _receiver) external onlyOwner {
        uint256 index = findFeeReceiverIndex(_receiver);
        require(index != type(uint256).max, "Receiver not found");

        feeReceivers[index] = feeReceivers[feeReceivers.length - 1];
        feeReceivers.pop();
    }

    /**
     @notice Add Fee Giver Contract
     */
    function addFeeGiver(address _giver) external onlyOwner {
        require(_giver != address(0), "Invalid giver address");
        feeGivers.push(FeeGiverContract(_giver));
    }

    /**
     @notice Remove Fee Giver Contract
     */
    function removeFeeGiver(address _giver) external onlyOwner {
        uint256 index = findFeeGiverIndex(_giver);
        require(index != type(uint256).max, "Giver not found");

        feeGivers[index] = feeGivers[feeGivers.length - 1];
        feeGivers.pop();
    }


    /**
     * @notice Claim All Gas Fees From Blast
     * @notice To claim all of your contract’s gas fees, regardless of your resulting claim rate.
     */
    function claimAll() external onlyOperator {
        for (uint256 i = 0; i < feeGivers.length; i++) {
            FeeGiverContract memory giver = feeGivers[i];
            uint256 feeAmount = blast.claimAllGas(giver.giver, address(this));
            emit FeesCollected(giver.giver, feeAmount);
        }
    }

    /**
     * @notice Claim All Gas Fee From Blast By Contract
     * @notice To claim all of your contract’s gas fees, regardless of your resulting claim rate.
     */
    function claimAllByContract(address addr) external onlyOperator {
        uint256 feeAmount = blast.claimAllGas(addr, address(this));
        emit FeesCollected(addr, feeAmount);
    }

    /**
     * @notice Claim Max Gas From Blast
     * @notice You can use claimMaxGas to guarantee a 100% claim rate
     */
    function claimMax() external onlyOperator {
        for (uint256 i = 0; i < feeGivers.length; i++) {
            FeeGiverContract memory giver = feeGivers[i];
            uint256 feeAmount = blast.claimMaxGas(giver.giver, address(this));
            emit FeesCollected(giver.giver, feeAmount);
        }
    }

    /**
     * @notice Claim Max Gas Fee From Blast By Contract
     * @notice You can use claimMaxGas to guarantee a 100% claim rate
     */
    function claimMaxByContract(address addr) external onlyOperator {
        uint256 feeAmount = blast.claimMaxGas(addr, address(this));
        emit FeesCollected(addr, feeAmount);
    }

    /**
     * @notice Claim Gas At Min From Blast
     * @param minClaimRateBips If you want minimum 80% claim rate, that translates to 8000 bips.
     */
    function claimGasAtMinClaimRate(
        uint256 minClaimRateBips
    ) external onlyOperator {
        for (uint256 i = 0; i < feeGivers.length; i++) {
            FeeGiverContract memory giver = feeGivers[i];
            uint256 feeAmount = blast.claimGasAtMinClaimRate(
                giver.giver,
                address(this),
                minClaimRateBips
            );
            emit FeesCollected(giver.giver, feeAmount);
        }
    }

    /**
     * @notice Claim Gas At Min From Blast
     * @param minClaimRateBips If you want minimum 80% claim rate, that translates to 8000 bips.
     */
    function claimGasAtMinClaimRateByContract(
        address addr,
        uint256 minClaimRateBips
    ) external onlyOperator {
        uint256 feeAmount = blast.claimGasAtMinClaimRate(
            addr,
            address(this),
            minClaimRateBips
        );
        emit FeesCollected(addr, feeAmount);
    }

    /**
     * @notice Distribute Fees
     */
    function distributeFees() external onlyOperator {
        require(address(this).balance > 0, "No Eth to distribute.");
        uint256 totalBalance = address(this).balance;

        // Calculate the total percentage sum of all fee receivers
        uint256 totalPercent = 0;
        for (uint256 i = 0; i < feeReceivers.length; i++) {
            totalPercent += feeReceivers[i].percent;
        }
        require(totalPercent > 0, "Total percent should be more than 0");

        // Distribute the balance according to each receiver's percentage
        for (uint256 i = 0; i < feeReceivers.length; i++) {
            FeeReceiverContract memory receiver = feeReceivers[i];
            uint256 amount = ((totalBalance * receiver.percent)*1e10 / totalPercent)/1e10;
            payable(receiver.receiver).transfer(amount);
            emit FeesDistributed(receiver.receiver, amount);
        }
    }

    function changePercentage(
        address contractAddr,
        uint256 newPercentage
    ) external onlyOwner {
        uint256 index = findFeeReceiverIndex(contractAddr);
        require(index != type(uint256).max, "Receiver not found");
        require(newPercentage > 0, "New Percentage should be bigger than 0");
        feeReceivers[index].percent = newPercentage;
    }

     /**
        @notice Claim Yield for specific amount. 
        @notice Claim Yield which gas station has been set as governor. 
     */
    function claimYield(address contractAddress, address recipient, uint256 amount) external onlyOperator{
        uint256 yield = blast.claimYield(contractAddress, recipient, amount);
        emit YieldClaimed(contractAddress, recipient, amount);
    }

    /* ========== External Function  ========== */

    /* ========== Internal Function  ========== */

    function findFeeReceiverIndex(
        address _receiver
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < feeReceivers.length; i++) {
            if (feeReceivers[i].receiver == _receiver) {
                return i;
            }
        }
        return type(uint256).max; // Receiver not found
    }

    function findFeeGiverIndex(address _giver) internal view returns (uint256) {
        for (uint256 i = 0; i < feeGivers.length; i++) {
            if (feeGivers[i].giver == _giver) {
                return i;
            }
        }
        return type(uint256).max; // Receiver not found
    }

    receive() external payable {}

    fallback() external payable {}

    /* ========== Modifier  ========== */
    modifier onlyOperator() {
        require(operators[msg.sender], "Not a operators");
        _;
    }
}
