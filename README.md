# WenGasStationV1 Smart Contract

To maximize efficiency and ensure no value is lost from not achieving a 100% claim rate, gas fees will be collected every month. This collection process not only enhances the utility of the gas station but also serves as a beneficial resource for two main participant groups within the Wen Exchange ecosystem: active traders and WEN token stakers.

### The distribution of gas fees is structured into three distinct segments:

1. **Wen Exchange Users**
   Active participants engaging in bidding, buying NFTs, and listing NFTs on Wen Exchange are eligible to receive WEN airdrop points. A significant portion, amounting to 73% of the collected gas fees, is allocated for refunds to these users, rewarding their platform activity.
2. **Wen Token Stakers**
   After we start issuing the first WEN tokens, those who stake their WEN tokens in WEN staking farm will receive a 20% of the gas fees collected. This rewards long-term support and participation in the Wen ecosystem.
   Treasury
3. **The treasury** will amass 7% of the gas fees, dedicated to funding further development and growth of the platform. Importantly, decisions regarding the allocation and expenditure of the treasury funds are democratically made by WEN token holders, ensuring community involvement in the strategic direction of Wen Exchange.

## Key Features

- **Gas Fee and Yield Management:** Interface with the IBlast contract for gas and yield-related operations.
- **Upgradeable:** Leverages UUPS (Universal Upgradeable Proxy Standard) for safe and flexible contract upgrades.
- **Access Control:** Ownable and operator-based permissions for executing sensitive functions.
- **Pausable:** Contract can be paused and unpaused by the owner for emergency management.

## Main Functions

### Initial Setup

- `setInitialInfo(address _blast)`: Sets the initial configuration with the Blast contract address and configures claimable yield and gas.
- `initialize()`: Initializes the contract with necessary setups for ownership and security features.

### Configuration

- `setBlast(address _blast)`: Updates the IBlast contract address.
- `setBlastGovernor(address _governor)`: Sets the governor address in the Blast contract for claiming gas fees.
- `setOperator(address[] calldata _operators)`: Approves multiple operators for managing the contract.
- `revokeOperator(address _operator)`: Revokes an operator's permission.
- `addFeeReceiver(address _receiver, uint256 _percent)`: Adds a new fee receiver with their corresponding percentage for fee distribution.
- `removeFeeReceiver(address _receiver)`: Removes an existing fee receiver.
- `addFeeGiver(address _giver)`: Registers a new fee giver contract.
- `removeFeeGiver(address _giver)`: Removes an existing fee giver contract.

### Gas Fee Management

- `claimAll()`: Claims all gas fees for all registered fee giver contracts.
- `claimAllByContract(address addr)`: Claims all gas fees for a specific contract.
- `claimMax()`: Claims gas fees at a 100% claim rate for all registered fee giver contracts.
- `claimMaxByContract(address addr)`: Claims gas fees at a 100% claim rate for a specific contract.
- `claimGasAtMinClaimRate(uint256 minClaimRateBips)`: Claims gas fees with a minimum claim rate for all registered fee giver contracts.
- `claimGasAtMinClaimRateByContract(address addr, uint256 minClaimRateBips)`: Claims gas fees with a minimum claim rate for a specific contract.

### Yield Management

- `claimYield(address recipient, uint256 amount)`: Claims a specific amount of yield for a recipient.
- `claimAllYield(address recipient)`: Claims all available yield for a recipient.
- `claimYield(address contractAddress, address recipient, uint256 amount)`: Claims a specific amount of yield from a specific contract for a recipient.
- `claimAllYield(address contractAddress, address recipient)`: Claims all available yield from a specific contract for a recipient.

### Fee Distribution

- `distributeFees()`: Distributes the collected fees among registered fee receivers based on their percentage.

### Utility Functions

- `pause()`: Pauses the contract, disabling all non-view and non-pure functions.
- `unpause()`: Unpauses the contract, re-enabling all functions.

## Modifiers

- `onlyOperator()`: Restricts function access to approved operators.

## Events

- Events for tracking fees received, distributed, collected, and yield claimed.

## Notice

This contract is designed to interact with specific external contracts and systems. Ensure that you have proper permissions and understand the impact of these operations within your ecosystem.
