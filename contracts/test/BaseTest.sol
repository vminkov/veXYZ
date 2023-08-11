// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Vm.sol";
import "forge-std/Test.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

import "../interfaces/IBribeFactory.sol";
import "../factories/GaugeFactory.sol";
import { Voter } from "../Voter.sol";
import { VoteEscrow } from "../VoteEscrow.sol";
import "../EpochsTimer.sol";

contract IonicToken is ERC20 {
  constructor() ERC20("IONIC", "ION", 18) {}

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }
}

contract IonicFlywheel is IFlywheel {
  IERC20 public rewardToken;
  address public flywheelRewards;

  constructor (address _rewards) {
    flywheelRewards = _rewards;
  }

  function accrue(IERC20, address) public returns (uint256) {
    return 0;
  }

  function claimRewards(address) public {}
}

contract BaseTest is Test {
  GaugeFactory public gaugeFactory;
  Voter public voter;
  VoteEscrow public ve;
  IonicToken ionicToken = new IonicToken();
  address proxyAdmin = address(123);
  address bridge1 = address(321);

  function setUp() public {
    ionicToken = new IonicToken();

    VoterRolesAuthority voterRolesAuthImpl = new VoterRolesAuthority();
    TransparentUpgradeableProxy rolesAuthProxy = new TransparentUpgradeableProxy(
      address(voterRolesAuthImpl),
      proxyAdmin,
      ""
    );
    VoterRolesAuthority voterRolesAuth = VoterRolesAuthority(address(rolesAuthProxy));
    voterRolesAuth.initialize(address(this));

    GaugeFactory impl = new GaugeFactory();
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), proxyAdmin, "");

    gaugeFactory = GaugeFactory(address(proxy));
    gaugeFactory.initialize(voterRolesAuth);

    VoteEscrow veImpl = new VoteEscrow();
    TransparentUpgradeableProxy veProxy = new TransparentUpgradeableProxy(address(veImpl), proxyAdmin, "");
    ve = VoteEscrow(address(veProxy));
    ve.initialize("veIonic", "veION", address(ionicToken));

    vm.chainId(ve.ARBITRUM_ONE());
    // advance it time
    vm.warp(200 weeks);

    EpochsTimer timer = new EpochsTimer();
    timer.update_period();

    // TODO
    IBribeFactory bribeFactory = IBribeFactory(address(0));

    Voter voterImpl = new Voter();
    TransparentUpgradeableProxy voterProxy = new TransparentUpgradeableProxy(address(voterImpl), proxyAdmin, "");
    voter = Voter(address(voterProxy));
    voter.initialize(address(ve), address(gaugeFactory), address(bribeFactory), address(timer), voterRolesAuth);

    ve.setVoter(address(voter));

    vm.prank(ve.owner());
    ve.addBridge(bridge1);
  }

  function testIonicLockAndVotingPower() public {
    uint256 tokenId;

    ionicToken.mint(address(this), 100e18);

    ionicToken.approve(address(ve), 1e36);

    // change to some other chain ID
    vm.chainId(1);

    vm.expectRevert("wrong chain id");
    tokenId = ve.create_lock(20e18, 52 weeks);

    // revert back to the master chain ID
    vm.chainId(ve.ARBITRUM_ONE());
    tokenId = ve.create_lock(20e18, 52 weeks);

    assertApproxEqAbs(ve.balanceOfNFT(tokenId), 20e18, 1e17, "wrong voting power");
  }

  function testCreateMarketGauges() public {
    address rewardsContract = address(922);
    address market = address(444);
    uint256 rewardsAmount = 233e18;
    IonicFlywheel flywheel = new IonicFlywheel(rewardsContract);

    vm.warp(block.timestamp + 1 weeks + 1);

    ionicToken.mint(address(this), 1000e18);

    (address gaugeAddress, ,) = voter.createMarketGauge(market, address(flywheel));
    MarketGauge marketGauge = MarketGauge(gaugeAddress);

    ionicToken.approve(address(ve), 1e36);
    uint256 tokenId = ve.create_lock(20e18, 52 weeks);
    voter.vote(tokenId, asArray(market), asArray(1e18));

    ionicToken.approve(address(voter), 1e36);
    voter.distributeAll();

    uint256 rewardsContractBalance = ionicToken.balanceOf(rewardsContract);
    assertEq(rewardsContractBalance, rewardsAmount, "!rewards contract balance");
  }

  function asArray(address value) public pure returns (address[] memory) {
    address[] memory array = new address[](1);
    array[0] = value;
    return array;
  }

  function asArray(uint256 value0, uint256 value1) public pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](2);
    array[0] = value0;
    array[1] = value1;
    return array;
  }

  function asArray(uint256 value) public pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = value;
    return array;
  }
}
