// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IVaultTypes
 * @dev Interfaz común para funcionalidades compartidas entre tipos de vaults
 */
interface IVaultTypes {
    // Enum para tipos de vaults
    enum VaultType {
        SingleOwner,
        MultiSig,
        Timelock,
        Funding
    }

    // Struct básico de información de un vault
    struct VaultInfo {
        address creator;
        string name;
        string description;
        string category;
        string imageURI;
        bool isPublic;
        uint256 createdAt;
    }

    // Eventos comunes
    event VaultCreated(address indexed vault, address indexed owner, VaultType indexed vaultType);
    event FundsDeposited(address indexed vault, address indexed sender, uint256 amount);
    event FundsWithdrawn(address indexed vault, address indexed recipient, uint256 amount);

    // Funciones comunes
    function getVaultType() external pure returns (VaultType);
    function getVaultInfo() external view returns (VaultInfo memory);
    function deposit() external payable;
    function withdraw(address payable recipient, uint256 amount) external;
}