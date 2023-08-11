// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IMarket.sol";
import "./Gauge.sol";

interface IFlywheel {
  function isRewardsDistributor() external returns (bool);

  function isFlywheel() external returns (bool);

  function flywheelPreSupplierAction(address market, address supplier) external;

  function flywheelPreBorrowerAction(address market, address borrower) external;

  function flywheelPreTransferAction(address market, address src, address dst) external;

  function compAccrued(address user) external view returns (uint256);

  function addMarketForRewards(IERC20 strategy) external;

  function marketState(IERC20 strategy) external view returns (uint224 index, uint32 lastUpdatedTimestamp);

  function rewardToken() external returns (IERC20);

  function flywheelRewards() external returns (address);

  function accrue(IERC20 strategy, address user) external returns (uint256);

  function claimRewards(address user) external;
}

contract MarketGauge is Gauge {
  using SafeERC20 for IERC20;

  IFlywheel public flywheel;

  function initialize(
    address _flywheel,
    address _rewardToken,
    address _ve,
    address _target,
    address _distribution,
    address _internal_bribe,
    address _external_bribe
  ) external initializer {
    __Gauge_init(_rewardToken, _ve, _target, _distribution, _internal_bribe, _external_bribe);
    flywheel = IFlywheel(_flywheel);
  }

  function notifyRewardAmount(
    address token,
    uint256 reward
  ) external override nonReentrant isNotEmergency onlyDistribution {
    require(token == address(rewardToken), "not rew token");
    address flywheelRewards = flywheel.flywheelRewards();
    require(flywheelRewards != address(0), "zero addr flywheel");
    rewardToken.safeTransferFrom(distribution, flywheelRewards, reward);
  }

  function getReward(address _user) public override nonReentrant onlyDistribution {
    flywheel.accrue(IERC20(target), _user);
    flywheel.claimRewards(_user);
  }

  function claimFees() external {
    claimMarketFees();
  }

  function claimMarketFees() public nonReentrant returns (uint256) {
    return abi.decode(_claimFees(), (uint256));
  }

  function _claimFees() internal override returns (bytes memory) {
    uint256 fees = IMarket(target).totalAdminFees();

    if (fees > 0) {
      IMarket(target)._withdrawAdminFees(fees);
      address underlying = IMarket(target).underlying();

      if (fees > 0) {
        // assuming that the admin is the gauge
        IERC20(underlying).approve(internal_bribe, fees);
        IBribe(internal_bribe).notifyRewardAmount(underlying, fees);
      }
      emit ClaimFees(msg.sender, fees);
    }

    return abi.encode(fees);
  }
}
