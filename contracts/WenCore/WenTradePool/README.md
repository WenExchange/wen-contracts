Please check [WenTradePool Docs]('https://docs.wen.exchange/product/wen-trade-pool') before you look through the code. It would be much easier in that way.

# WenTradePoolV1 Smart Contract README

The `WenTradePoolV1` smart contract is designed to facilitate the staking of ETH and the minting and redeeming of wenETH, a token representing a staked value in Ethereum. It integrates with the `IBlast` interface for managing gas fees and yield claims, providing a comprehensive solution for participants in the DeFi ecosystem. Built on OpenZeppelin's upgradeable contracts, it ensures security, flexibility, and future-proofing through upgradability.

## Key Features

- **ETH Staking for wenETH**: Allows users to stake ETH and receive wenETH tokens in return, representing their staked value.
- **Yield and Gas Fee Management**: Integrates with the `IBlast` interface to manage and claim yields and gas fees for stakeholders.
- **Upgradeable**: Utilizes UUPS (Universal Upgradeable Proxy Standard) for easy upgrades without losing the contract's current state.
- **Access Control**: Managed by an owner with additional permissions for operators to manage key functionalities.
- **Pause Functionality**: Can be paused or unpaused by the owner in case of emergencies.

## Contract Functions

### Initialization and Setup

- `initialize()`: Prepares the contract with initial setup for ownership, reentrancy guard, and pausability.
- `setInitialInfo(address _wenETH, address _blast)`: Configures the wenETH token address and the Blast contract address for yield and gas management.

### Staking and Unstaking

- `stake()`: Allows users to stake ETH and mint wenETH tokens based on the current exchange rate.
- `unstake(uint256 _amount)`: Enables users to return their wenETH tokens and redeem the equivalent value in ETH.

### Yield and Gas Fee Management

- `claimYield(address recipient, uint256 amount)`: Claims a specified amount of yield for a recipient, emitting a `FeesReceived` event.
- `claimAllYield(address recipient)`: Claims all available yield for a recipient, emitting a `FeesReceived` event.

### Configuration and Management

- `setBlast(address _blast)`: Updates the IBlast contract address.
- `setBlastGovernor(address _governor)`: Configures the governor address in the Blast contract for authorized gas fee claims.
- `setOperator(address[] calldata _operators)`, `revokeOperator(address _operator)`: Manages operator permissions for contract management.

### Utility Functions

- `pause()`, `unpause()`: Enables the contract owner to pause or unpause contract operations for safety reasons.
- `_authorizeUpgrade(address newImplementation)`: Allows the contract owner to upgrade the contract.

### Exchange Rate and Conversion

- `getwenETHExchangeRate()`: Provides the current exchange rate between ETH and wenETH.
- `ethToWenETH(uint256 inputETH)`: Calculates the amount of wenETH that would be minted for a given amount of ETH.

## Modifiers

- `onlyOperator()`: Ensures that only approved operators can call certain functions.

## Events

- `Unstake`: Emitted when wenETH is redeemed for ETH.
- `Stake`: Emitted when ETH is staked for wenETH.
- `FeesReceived`: Emitted when yield or gas fees are claimed.

## Security and Upgradability

The contract leverages OpenZeppelin's security and upgradability features to protect against common vulnerabilities and ensure that the contract can be upgraded in the future without losing its existing state or assets. This design philosophy ensures that WenTradePoolV1 remains robust and adaptable to future requirements.
