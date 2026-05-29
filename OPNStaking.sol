// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OPNStaking is ReentrancyGuard, Ownable {
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    uint256 public rewardRate; 
    uint256 public totalStaked;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRate) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
    }

    modifier updateReward(address account) {
        rewards[account] += calculateReward(account);
        lastUpdateTime[account] = block.timestamp;
        _;
    }

    function stake(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "Jumlah stake harus lebih dari 0");
        stakedBalance[msg.sender] += _amount;
        totalStaked += _amount;
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer gagal");
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "Jumlah penarikan harus lebih dari 0");
        require(stakedBalance[msg.sender] >= _amount, "Saldo stake tidak cukup");
        stakedBalance[msg.sender] -= _amount;
        totalStaked -= _amount;
        require(stakingToken.transfer(msg.sender, _amount), "Transfer gagal");
        emit Withdrawn(msg.sender, _amount);
    }

    function claimReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "Tidak ada reward untuk diklaim");
        rewards[msg.sender] = 0;
        require(rewardToken.transfer(msg.sender, reward), "Transfer reward gagal");
        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address account) public view returns (uint256) {
        if (stakedBalance[account] == 0) {
            return 0;
        }
        uint256 timeStaked = block.timestamp - lastUpdateTime[account];
        return (stakedBalance[account] * rewardRate * timeStaked) / 1000000000000000000;
    }
}
