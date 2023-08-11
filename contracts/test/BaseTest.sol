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
  constructor() ERC20("IONIC", "ION", 18) {

  }
}

contract BaseTest is Test {
  GaugeFactory public gaugeFactory;
  Voter public voter;
  VoteEscrow public ve;

  function setUp() public {
    IonicToken ionicToken = new IonicToken();

    address proxyAdmin = address(123);

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

    // TODO
    IBribeFactory bribeFactory = IBribeFactory(address(0));

    Voter voterImpl = new Voter();
    TransparentUpgradeableProxy voterProxy = new TransparentUpgradeableProxy(address(voterImpl), proxyAdmin, "");
    voter = Voter(address(voterProxy));
    voter.initialize(address(ve), address(gaugeFactory), address(bribeFactory), voterRolesAuth);
  }

  function testOwner() public {
    assertEq(gaugeFactory.owner(), address(this), "!owner");
  }
}
