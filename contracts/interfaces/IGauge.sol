// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account) external;
    function claimFees() external;
    function balanceOf(address _account) external view returns (uint);
    function totalSupply() external view returns (uint);
    function earned(address account) external view returns (uint);
}