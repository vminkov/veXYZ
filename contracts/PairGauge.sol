// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IPair.sol";
import "./Gauge.sol";

contract PairGauge is Gauge {
  using SafeERC20 for IERC20;

  IERC20 public TOKEN;

  function initialize(IERC20 _token) external initializer {
    TOKEN = _token;
  }

  ///@notice deposit all TOKEN of msg.sender
  function depositAll() external {
    _deposit(TOKEN.balanceOf(msg.sender), msg.sender);
  }

  ///@notice deposit amount TOKEN
  function deposit(uint256 amount) external {
    _deposit(amount, msg.sender);
  }

  ///@notice deposit internal
  function _deposit(uint256 amount, address account) internal nonReentrant isNotEmergency updateReward(account) {
    require(amount > 0, "deposit(Gauge): cannot stake 0");

    _balances[account] = _balances[account] + amount;
    _totalSupply = _totalSupply + amount;

    TOKEN.safeTransferFrom(account, address(this), amount);

    emit Deposit(account, amount);
  }

  ///@notice withdraw all token
  function withdrawAll() external {
    _withdraw(_balances[msg.sender]);
  }

  ///@notice withdraw a certain amount of TOKEN
  function withdraw(uint256 amount) external {
    _withdraw(amount);
  }

  ///@notice withdraw internal
  function _withdraw(uint256 amount) internal nonReentrant isNotEmergency updateReward(msg.sender) {
    require(amount > 0, "Cannot withdraw 0");
    require(_balances[msg.sender] > 0, "no balances");

    _totalSupply = _totalSupply - amount;
    _balances[msg.sender] = _balances[msg.sender] - amount;

    TOKEN.safeTransfer(msg.sender, amount);

    emit Withdraw(msg.sender, amount);
  }

  function emergencyWithdraw() external nonReentrant {
    require(emergency, "emergency");
    require(_balances[msg.sender] > 0, "no balances");
    uint256 _amount = _balances[msg.sender];
    _totalSupply = _totalSupply - _amount;
    _balances[msg.sender] = 0;
    TOKEN.safeTransfer(msg.sender, _amount);
    emit Withdraw(msg.sender, _amount);
  }

  function emergencyWithdrawAmount(uint256 _amount) external nonReentrant {
    require(emergency, "emergency");
    _totalSupply = _totalSupply - _amount;

    _balances[msg.sender] = _balances[msg.sender] - _amount;
    TOKEN.safeTransfer(msg.sender, _amount);
    emit Withdraw(msg.sender, _amount);
  }

  ///@notice withdraw all TOKEN and harvest rewardToken
  function withdrawAllAndHarvest() external {
    _withdraw(_balances[msg.sender]);
    getReward();
  }

  function claimFees() external {
    claimPairFees();
  }

  function claimPairFees() public nonReentrant returns (uint256 claimed0, uint256 claimed1) {
    return abi.decode(_claimFees(), (uint256, uint256));
  }

  function _claimFees() internal override returns (bytes memory) {
    uint256 claimed0;
    uint256 claimed1;
    IPair pair = IPair(target);

    (claimed0, claimed1) = pair.claimFees();
    if (claimed0 > 0 || claimed1 > 0) {
      uint256 _fees0 = claimed0;
      uint256 _fees1 = claimed1;

      (address _token0, address _token1) = pair.tokens();

      if (_fees0 > 0) {
        IERC20(_token0).approve(internal_bribe, 0);
        IERC20(_token0).approve(internal_bribe, _fees0);
        IBribe(internal_bribe).notifyRewardAmount(_token0, _fees0);
      }
      if (_fees1 > 0) {
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
