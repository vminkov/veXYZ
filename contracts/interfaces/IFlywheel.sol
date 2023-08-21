// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlywheel {
  function rewardToken() external returns (IERC20);

  function flywheelRewards() external returns (address);

  function accrue(IERC20 strategy, address user) external returns (uint256);

  function claimRewards(address user) external;
}
