// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC721Upgradeable, IERC721MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

abstract contract XERC721Upgradeable is ERC721Upgradeable {
  event BridgeAdded(address indexed bridge);
  event BridgeRemoved(address indexed bridge);

  mapping(address => bool) internal _whitelistedBridges;

  constructor() {}

  function initialize(address _owner, string memory _name, string memory _symbol) public initializer {
    __XERC721_init();
    __ERC20_init(_name, _symbol);
    __ERC20Permit_init(_name);
    __ProposedOwnable_init();

    // Set specified owner
    _setOwner(_owner);
  }

  function __XERC721_init() internal onlyInitializing {
    __XERC721_init_unchained();
  }

  function __XERC721_init_unchained() internal onlyInitializing {}

  error XERC721__onlyBridge_notBridge();
  error XERC721__addBridge_alreadyAdded();
  error XERC721__removeBridge_alreadyRemoved();

  modifier onlyBridge() {
    if (!_whitelistedBridges[msg.sender]) {
      revert XERC721__onlyBridge_notBridge();
    }
    _;
  }

  function addBridge(address _bridge) external onlyOwner {
    if (_whitelistedBridges[_bridge]) {
      revert XERC721__addBridge_alreadyAdded();
    }
    emit BridgeAdded(_bridge);
    _whitelistedBridges[_bridge] = true;
  }

  function removeBridge(address _bridge) external onlyOwner {
    if (!_whitelistedBridges[_bridge]) {
      revert XERC721__removeBridge_alreadyRemoved();
    }
    emit BridgeRemoved(_bridge);
    _whitelistedBridges[_bridge] = false;
  }

  function mint(address _to, uint256 _amount) public onlyBridge {
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) public onlyBridge {
    _burn(_from, _amount);
  }

  uint256[49] private __GAP; // gap for upgrade safety
}