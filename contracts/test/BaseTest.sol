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

contract IonicToken is ERC20 {
  constructor() ERC20("IONIC", "ION", 18) {}

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }
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

    // TODO
    IBribeFactory bribeFactory = IBribeFactory(address(0));

    Voter voterImpl = new Voter();
    TransparentUpgradeableProxy voterProxy = new TransparentUpgradeableProxy(address(voterImpl), proxyAdmin, "");
    voter = Voter(address(voterProxy));
    voter.initialize(address(ve), address(gaugeFactory), address(bribeFactory), voterRolesAuth);

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

  }
}
