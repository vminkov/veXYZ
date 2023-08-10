// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IBribe.sol";
import "./interfaces/IGauge.sol";

interface IRewarder {
  function onReward(address user, address recipient, uint256 userBalance) external;
}

abstract contract Gauge is ReentrancyGuardUpgradeable, OwnableUpgradeable, IGauge {
  using SafeERC20 for IERC20;

  bool public emergency;

  IERC20 public rewardToken;

  // used in the inheriting contracts
  address public target;

  // TODO unused?
  address public ve;
  address public distribution;
  address public internal_bribe;
  address public external_bribe;

  uint256 internal _periodFinish;

  event RewardAdded(uint256 reward);
  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Harvest(address indexed user, uint256 reward);

  event ClaimFees(address indexed from, uint256 fees);
  event EmergencyActivated(address indexed gauge, uint256 timestamp);
  event EmergencyDeactivated(address indexed gauge, uint256 timestamp);

  modifier onlyDistribution() {
    require(msg.sender == distribution, "Caller is not RewardsDistribution contract");
    _;
  }

  modifier isNotEmergency() {
    require(emergency == false, "emergency");
    _;
  }

  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _rewardToken,
    address _ve,
    address _target,
    address _distribution,
    address _internal_bribe,
    address _external_bribe
  ) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();

    rewardToken = IERC20(_rewardToken); // main reward
    ve = _ve; // vested
    target = _target; // gauge target address
    distribution = _distribution; // distro address (voter)

    internal_bribe = _internal_bribe; // lp fees goes here
    external_bribe = _external_bribe; // bribe fees goes here

    emergency = false; // emergency flag
  }

  /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    ONLY OWNER
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

  ///@notice set distribution address (should be voter)
  function setDistribution(address _distribution) external onlyOwner {
    require(_distribution != address(0), "zero addr");
    require(_distribution != distribution, "same addr");
    distribution = _distribution;
  }

  ///@notice set new internal bribe contract (where to send fees)
  function setInternalBribe(address _int) external onlyOwner {
    require(_int >= address(0), "zero");
    internal_bribe = _int;
  }

  function activateEmergencyMode() external onlyOwner {
    require(emergency == false, "emergency");
    emergency = true;
    emit EmergencyActivated(address(this), block.timestamp);
  }

  function stopEmergencyMode() external onlyOwner {
    require(emergency == true, "emergency");

    emergency = false;
    emit EmergencyDeactivated(address(this), block.timestamp);
  }

  /* -----------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
                                  VIEW FUNCTIONS
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  ----------------------------------------------------------------------------- */

  ///@notice last time reward
  function lastTimeRewardApplicable() public view returns (uint256) {
    // return min
    return block.timestamp < _periodFinish ? block.timestamp : _periodFinish;
  }

  function periodFinish() external view returns (uint256) {
    return _periodFinish;
  }

  /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    DISTRIBUTION
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

  /// @dev Receive rewards from distribution

  function notifyRewardAmount(address token, uint256 reward) external virtual;

  function _claimFees() internal virtual returns (bytes memory);
}
