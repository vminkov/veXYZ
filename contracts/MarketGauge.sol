// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './interfaces/IMarket.sol';
import './Gauge.sol';

contract MarketGauge is Gauge {

  constructor(
    address _rewardToken,
    address _ve,
    address _target,
    address _distribution,
    address _internal_bribe,
    address _external_bribe
  ) Gauge(_rewardToken, _ve, _target, _distribution, _internal_bribe, _external_bribe) {}

  function claimFees() external nonReentrant returns (uint256) {
    return abi.decode(_claimFees(), (uint256));
  }

  function _claimFees() internal override returns (bytes memory) {
    uint256 fees = IMarket(TARGET).totalAdminFees();

    if (fees > 0) {
      IMarket(TARGET)._withdrawAdminFees(fees);
      address underlying = IMarket(TARGET).underlying();

      if (fees  > 0) {
        // assuming that the admin is the gauge
        IERC20(underlying).approve(internal_bribe, fees);
        IBribe(internal_bribe).notifyRewardAmount(underlying, fees);
      }
      emit ClaimFees(msg.sender, fees);
    }

    return abi.encode(fees);
  }
}