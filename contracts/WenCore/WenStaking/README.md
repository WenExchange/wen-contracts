# WenStakingV1 Smart Contract README

The `WenStakingV1` smart contract is designed for staking ERC20 tokens and distributing rewards within a DeFi ecosystem. Built on OpenZeppelin's upgradeable contracts framework, it ensures enhanced security, flexibility, and future-proofing through upgradability. The contract facilitates staking of tokens, calculation and distribution of rewards, and supports multiple reward tokens, including special handling for WEN tokens.

## Key Features

- **ERC20 Token Staking**: Enables users to stake ERC20 tokens securely.
- **Multiple Reward Tokens**: Supports distribution of multiple types of rewards, including a specialized system for WEN tokens.
- **Upgradeable**: Utilizes UUPS (Universal Upgradeable Proxy Standard) for seamless future improvements.
- **Access Control**: Managed by an owner, with additional functionality for a rewards distribution role.
- **Pause Functionality**: Can be paused or unpaused by the owner in case of emergencies.

## Contract Functions

### Initialization and Setup

- `initialize()`: Prepares the contract with initial setup for ownership and pausability.
- `setInitialInfo(address _stakingToken, address[2] memory _rewardTokens, uint256 _rewardDuration, address _rewardsDistribution)`: Configures the staking token, reward tokens, duration of rewards, and the rewards distribution address.
- `setWen(address _WenAddr)`: Specifies the address for the WEN token for special reward treatment.

### Staking and Withdrawal

- `stake(uint256 amount)`: Allows users to stake their tokens into the contract.
- `withdraw(uint256 amount)`: Permits users to withdraw their staked tokens and claim rewards.

### Reward Management

- `claimReward()`: Enables users to claim their pending rewards.
- `updateRewardAmount()`: Updates the reward amounts based on the tokens available in the contract for distribution. This is restricted to the rewards distribution role.
- `setRewardsDuration(uint256 _rewardsDuration)`: Updates the rewards distribution period.
- `setRewardsDistribution(address _rewardsDistribution)`: Updates the rewards distribution address.

### Utility Functions

- `pause()`, `unpause()`: Enables the contract owner to pause or unpause contract operations for safety reasons.
- `_authorizeUpgrade(address newImplementation)`: Allows the contract owner to upgrade the contract.

### Reward Calculation and Views

- `rewardPerToken(address _rewardsToken)`: Calculates the current rate of rewards per token for a specified reward token.
- `earned(address account, address _rewardsToken)`: Determines the amount of rewards earned by an account for a specific reward token.
- `lastTimeRewardApplicable(address _rewardsToken)`: Fetches the last applicable timestamp for reward calculation for a specific reward token.
- `getRewardForDuration(address _rewardsToken)`: Retrieves the total rewards to be distributed over the current reward period for a specific reward token.

## Modifiers

- `onlyRewardsDistribution()`: Ensures that only the specified rewards distribution address can call a function.
- `updateReward(address account)`: Automatically updates reward calculations upon calling certain functions.

## Events

- `RewardAdded`: Emitted when new rewards are added to the pool.
- `Staked`: Emitted when a user stakes tokens.
- `Withdrawn`: Emitted when a user withdraws tokens.
- `RewardPaid`: Emitted when rewards are paid out to a user.
- `RewardsDurationUpdated`: Emitted when the rewards duration is updated.

## Special Handling for WEN Tokens

In addition to general reward tokens, this contract incorporates specialized functions and mechanisms for managing WEN tokens as rewards. This allows for unique reward distribution strategies and calculations for WEN token stakers.

## Security and Upgradability

The contract leverages OpenZeppelin's security and upgradability features to protect against common vulnerabilities and ensure that the contract can be upgraded in the future without losing its existing state or assets.
