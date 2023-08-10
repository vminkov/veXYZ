// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Vm.sol";
import "forge-std/Test.sol";
import "../factories/GaugeFactory.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract BaseTest is Test {
  GaugeFactory public gaugeFactory;

  function setUp() public {
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
  }

  function testOwner() public {
    assertEq(gaugeFactory.owner(), address(this), "!owner");
  }
}
