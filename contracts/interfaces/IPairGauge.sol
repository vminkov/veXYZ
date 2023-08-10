// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IGauge.sol";

interface IPairGauge is IGauge {
  function balanceOf(address _account) external view returns (uint);

  function totalSupply() external view returns (uint);

  function earned(address account) external view returns (uint);
}
