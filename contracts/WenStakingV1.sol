//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

interface IWenStaking {
    function updateRewardAmount() external;
}

contract WenStakingV1 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IWenStaking
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 balance;
    }
    IERC20Upgradeable public stakingToken;
    address[2] public rewardTokens;
    mapping(address => Reward) public rewardData;

    address public rewardsDistribution;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint256 public REWARDS_DURATION;

    address public wen_rewardToken;
    Reward public wen_rewardData;
    mapping(address => uint256) public wen_userRewardPerTokenPaid;
    mapping(address => uint256) public wen_rewards;

    event RewardAdded(address indexed rewardsToken, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(
        address indexed user,
        address indexed rewardsToken,
        uint256 reward
    );
    event RewardsDurationUpdated(uint256 newDuration);
    event UpdateReward(
        address rewardToken,
        uint256 rewardPerTokenStored,
        address user,
        uint256 earned,
        uint256 userRewardPerTokenPaid
    );

    /* ========== Restricted Function  ========== */

    /**
        @notice Initialize UUPS upgradeable smart contract.
     */
    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
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
     @notice sets initialInfo of the contract.
     */
    function setInitialInfo(
        address _stakingToken,
        address[2] memory _rewardTokens,
        uint256 _rewardDuration,
        address _rewardsDistribution
    ) external onlyOwner {
        stakingToken = IERC20Upgradeable(_stakingToken); // Wen
        rewardTokens = _rewardTokens; // KSP, SIG
        REWARDS_DURATION = _rewardDuration;
        rewardsDistribution = _rewardsDistribution;
    }

    /**
    @notice sets Wen reward info to contract
     */
    function setWen(address _WenAddr) external onlyOwner {
        wen_rewardToken = _WenAddr;
    }

    /**
     @notice update reward amount. 
     @dev only can be called from rewardDistribution contract. 
     */
    function updateRewardAmount()
        external
        override
        onlyRewardsDistribution
        updateReward(address(0))
    {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            if (token != address(0)) {
                Reward storage r = rewardData[token];
                uint256 unseen = IERC20Upgradeable(token).balanceOf(
                    address(this)
                ) - r.balance;
                if (unseen > 0) {
                    _notifyRewardAmount(r, unseen);
                    emit RewardAdded(token, unseen);
                }
            }
        }
    }

    /**
     @notice set reward duration. 
     */
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            _rewardsDuration > 0,
            "reward durationi should be longer than 0"
        );
        REWARDS_DURATION = _rewardsDuration;
        emit RewardsDurationUpdated(REWARDS_DURATION);
    }

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== External & Public Function  ========== */

    function stake(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        require(balanceOf[msg.sender] >= amount, "Balance is not enough.");
        _claimReward();
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimReward()
        public
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            Reward storage r = rewardData[token];
            if (token != address(0)) {
                // reward 업데이트가 지금으로부터 한 시간 전 보다 더되었으면 새로운 리워드가 있는지 확인을 해라.
                if (
                    block.timestamp + REWARDS_DURATION > r.periodFinish + 3600
                ) {
                    uint256 unseen = IERC20Upgradeable(token).balanceOf(
                        address(this)
                    ) - r.balance;
                    if (unseen > 0) {
                        _notifyRewardAmount(r, unseen);
                        emit RewardAdded(token, unseen);
                    }
                }
                uint256 reward = rewards[msg.sender][token];
                if (reward > 0) {
                    rewards[msg.sender][token] = 0;
                    r.balance -= reward;
                    IERC20Upgradeable(token).safeTransfer(msg.sender, reward);
                    emit RewardPaid(msg.sender, token, reward);
                }
            }
        }

        if (wen_rewardToken != address(0)) {
            Reward storage r = wen_rewardData;
            uint256 reward = wen_rewards[msg.sender];
            if (reward > 0) {
                wen_rewards[msg.sender] = 0;
                r.balance -= reward;
                IERC20Upgradeable(wen_rewardToken).safeTransfer(
                    msg.sender,
                    reward
                );
                emit RewardPaid(msg.sender, wen_rewardToken, reward);
            }
        }
    }

    /* ========== Internal & Private Function  ========== */
    function _claimReward() private {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            if (token != address(0)) {
                Reward storage r = rewardData[token];
                // reward 업데이트가 지금으로부터 한 시간 전 보다 더되었으면 새로운 리워드가 있는지 확인을 해라.
                if (
                    block.timestamp + REWARDS_DURATION > r.periodFinish + 3600
                ) {
                    uint256 unseen = IERC20Upgradeable(token).balanceOf(
                        address(this)
                    ) - r.balance;
                    if (unseen > 0) {
                        _notifyRewardAmount(r, unseen);
                        emit RewardAdded(token, unseen);
                    }
                }
                uint256 reward = rewards[msg.sender][token];
                if (reward > 0) {
                    rewards[msg.sender][token] = 0;
                    r.balance -= reward;
                    IERC20Upgradeable(token).safeTransfer(msg.sender, reward);
                    emit RewardPaid(msg.sender, token, reward);
                }
            }
        }

        if (wen_rewardToken != address(0)) {
            Reward storage r = wen_rewardData;
            uint256 reward = wen_rewards[msg.sender];
            if (reward > 0) {
                wen_rewards[msg.sender] = 0;
                r.balance -= reward;
                IERC20Upgradeable(wen_rewardToken).safeTransfer(
                    msg.sender,
                    reward
                );
                emit RewardPaid(msg.sender, wen_rewardToken, reward);
            }
        }
    }

    function _notifyRewardAmount(Reward storage r, uint256 reward) internal {
        if (block.timestamp >= r.periodFinish) {
            r.rewardRate = reward / REWARDS_DURATION;
        } else {
            uint256 remaining = r.periodFinish - block.timestamp;
            uint256 leftover = remaining * r.rewardRate;
            r.rewardRate = (reward + leftover) / REWARDS_DURATION;
        }
        r.lastUpdateTime = block.timestamp;
        r.periodFinish = block.timestamp + REWARDS_DURATION;
        r.balance += reward;
    }

    /* ========== View Function  ========== */

    function lastTimeRewardApplicable(address _rewardsToken)
        public
        view
        returns (uint256)
    {
        uint256 periodFinish = rewardData[_rewardsToken].periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
        @notice Calculate Reward per token. 
        @param _rewardsToken address of reward token.
     */
    function rewardPerToken(address _rewardsToken)
        public
        view
        returns (uint256)
    {
        if (totalSupply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        uint256 duration = lastTimeRewardApplicable(_rewardsToken) -
            rewardData[_rewardsToken].lastUpdateTime;
        uint256 pending = (duration *
            rewardData[_rewardsToken].rewardRate *
            1e18) / totalSupply; //1e18 is for preventing rounding error
        return rewardData[_rewardsToken].rewardPerTokenStored + pending;
    }

    function earned(address account, address _rewardsToken)
        public
        view
        returns (uint256)
    {
        uint256 rpt = rewardPerToken(_rewardsToken) -
            userRewardPerTokenPaid[account][_rewardsToken];
        return
            (balanceOf[account] * rpt) / 1e18 + rewards[account][_rewardsToken];
    }

    function getRewardForDuration(address _rewardsToken)
        external
        view
        returns (uint256)
    {
        return rewardData[_rewardsToken].rewardRate * REWARDS_DURATION;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    modifier updateReward(address account) {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = rewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(0)) {
                rewards[account][token] = earned(account, token);
                userRewardPerTokenPaid[account][token] = rewardData[token]
                    .rewardPerTokenStored;
                emit UpdateReward(
                    token,
                    rewardData[token].rewardPerTokenStored,
                    account,
                    rewards[account][token],
                    userRewardPerTokenPaid[account][token]
                );
            }
        }

        //Wen Update
        if (wen_rewardToken != address(0)) {
            wen_rewardData.rewardPerTokenStored = wen_rewardPerToken();
            wen_rewardData
                .lastUpdateTime = wen_lastTimeRewardApplicable();
            if (account != address(0)) {
                wen_rewards[account] = wen_earned(account);
                wen_userRewardPerTokenPaid[account] = wen_rewardData
                    .rewardPerTokenStored;
                emit UpdateReward(
                    wen_rewardToken,
                    wen_rewardData.rewardPerTokenStored,
                    account,
                    wen_rewards[account],
                    wen_userRewardPerTokenPaid[account]
                );
            }
        }

        _;
    }

    /* ========== WEN RELATED FUNCTIONS ========== */

    function wen_updateRewardAmount(uint256 _amount)
        external
        onlyRewardsDistribution
        updateReward(address(0))
    {
        require(_amount > 0, "Update Reward Amount should be bigger than 0");

        Reward storage r = wen_rewardData;
        IERC20Upgradeable(wen_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        _notifyRewardAmount(r, _amount);
        emit RewardAdded(wen_rewardToken, _amount);
    }

    
    function wen_lastTimeRewardApplicable() public view returns (uint256) {
        uint256 periodFinish = wen_rewardData.periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
        @notice Calculate Reward per token. 
     */
    function wen_rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return wen_rewardData.rewardPerTokenStored;
        }
        uint256 duration = wen_lastTimeRewardApplicable() -
            wen_rewardData.lastUpdateTime;
        uint256 pending = (duration * wen_rewardData.rewardRate * 1e18) /
            totalSupply; //1e18 is for preventing rounding error
        return wen_rewardData.rewardPerTokenStored + pending;
    }

    /**
        @notice Calculate Reward per token. 
     */
    function wen_earned(address account) public view returns (uint256) {
        uint256 rpt = wen_rewardPerToken() -
            wen_userRewardPerTokenPaid[account];
        return (balanceOf[account] * rpt) / 1e18 + wen_rewards[account];
    }

    /**
        @notice Calculate Reward per token. 
     */
    function wen_getRewardForDuration() external view returns (uint256) {
        return wen_rewardData.rewardRate * REWARDS_DURATION;
    }
}
