// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

import "lib/dynamic-contracts/src/presets/BaseRouter.sol";

import "../extension/Multicall.sol";

import "../dynamic-contracts/extension/Initializable.sol";
import "../dynamic-contracts/extension/Permissions.sol";
import "../dynamic-contracts/extension/ERC2771ContextUpgradeable.sol";

import "../dynamic-contracts/init/ContractMetadataInit.sol";
import "../dynamic-contracts/init/ERC1155Init.sol";
import "../dynamic-contracts/init/OwnableInit.sol";
import "../dynamic-contracts/init/PermissionsEnumerableInit.sol";
import "../dynamic-contracts/init/RoyaltyInit.sol";
import "../dynamic-contracts/init/DefaultOperatorFiltererInit.sol";

/**
 *  Defualt extensions to add:
 *      - Pack logic
 *      - PermissionsEnumerable
 */

contract PackRouter is
    Initializable,
    Multicall,
    ERC2771ContextUpgradeable,
    BaseRouter,
    DefaultOperatorFiltererInit,
    ContractMetadataInit,
    ERC1155Init,
    OwnableInit,
    PermissionsEnumerableInit,
    RoyaltyInit
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("PackRouter");
    uint256 private constant VERSION = 2;

    address private immutable forwarder;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /*///////////////////////////////////////////////////////////////
                    Constructor and Initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(Extension[] memory _extensions, address _trustedForwarder) BaseRouter(_extensions) {
        forwarder = _trustedForwarder;
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _royaltyRecipient,
        uint16 _royaltyBps
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC1155_init(_contractURI);

        name = _name;
        symbol = _symbol;

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRoles(_defaultAdmin);

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);

        _setupOperatorFilterer();
    }

    function _setupRoles(address _defaultAdmin) internal onlyInitializing {
        bytes32 _operatorRole = keccak256("OPERATOR_ROLE");
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        bytes32 _assetRole = keccak256("ASSET_ROLE");

        bytes32 _defaultAdminRole = 0x00;

        _setupRole(_defaultAdminRole, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));
        _setupRole(_operatorRole, _defaultAdmin);
        _setupRole(_operatorRole, address(0));

        // note: see `onlyRoleWithSwitch` for ASSET_ROLE behaviour.
        _setupRole(_assetRole, address(0));
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a plugin can be set in the given execution context.
    function _canSetExtension() internal view virtual override returns (bool) {
        bytes32 defaultAdminRole = 0x00;
        return _hasRole(defaultAdminRole, _msgSender());
    }

    /// @dev Checks whether an account holds the given role.
    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][addr];
    }
}
