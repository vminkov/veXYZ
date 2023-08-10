// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGauge {
  function notifyRewardAmount(address token, uint amount) external;

  function claimFees() external;

  function getReward(address account) external;

  function setDistribution(address _distro) external;

  function activateEmergencyMode() external;

  function stopEmergencyMode() external;

  function setInternalBribe(address intbribe) external;
}
