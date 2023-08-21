// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGaugeFactory {
  function createPairGauge(
    address _rewardToken,
    address _ve,
    address _target,
    address _distribution,
    address _internal_bribe,
    address _external_bribe
  ) external returns (address);

  function createMarketGauge(
    address _flywheel,
    address _rewardToken,
    address _ve,
    address _target,
    address _distribution,
    address _internal_bribe,
    address _external_bribe
  ) external returns (address);
}
