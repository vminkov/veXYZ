// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './interfaces/IPair.sol';
import './Gauge.sol';

contract PairGauge is Gauge {
  IERC20 public immutable TOKEN;

  constructor(
    address _rewardToken,
    address _ve,
    address _target,
    address _distribution,
    address _internal_bribe,
    address _external_bribe
  ) Gauge(_rewardToken, _ve, _target, _distribution, _internal_bribe, _external_bribe) {
    TOKEN = IERC20(_target);                 // underlying (LP)
  }

  function claimFees() external nonReentrant returns (uint256 claimed0, uint256 claimed1) {
    return abi.decode(_claimFees(), (uint256, uint256));
  }

  function _claimFees() internal override returns (bytes memory) {
    uint256 claimed0;
    uint256 claimed1;

    address _token = address(TOKEN);
    (claimed0, claimed1) = IPair(_token).claimFees();
    if (claimed0 > 0 || claimed1 > 0) {

      uint256 _fees0 = claimed0;
      uint256 _fees1 = claimed1;

      (address _token0, address _token1) = IPair(_token).tokens();

      if (_fees0  > 0) {
        IERC20(_token0).approve(internal_bribe, 0);
        IERC20(_token0).approve(internal_bribe, _fees0);
        IBribe(internal_bribe).notifyRewardAmount(_token0, _fees0);
      }
      if (_fees1  > 0) {
        IERC20(_token1).approve(internal_bribe, 0);
        IERC20(_token1).approve(internal_bribe, _fees1);
        IBribe(internal_bribe).notifyRewardAmount(_token1, _fees1);
      }
      emit ClaimFees(msg.sender, claimed0, claimed1);
    }

    return abi.encode(claimed0, claimed1);
  }

  event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
}