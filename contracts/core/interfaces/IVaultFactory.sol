// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IBaseVault.sol";

/**
 * @title IVaultFactory
 * @dev Interface para la fabrica de vaults
 */

interface IVaultFactory {
    /**
     * @dev Enumeracion de los tipos de vault disponibles
     */
    enum VaultType {
        SingleOwner,
        MultiSig,
        TimeLock,
        Funding
    }

    /**
     * @dev Crear un nuevo vault de tipo SingleOwner
     * @param _name nombre del vault
     * @param _description descripcion del vault
     * @param _category Categoria del vault
     * @param _imageURI URI de la imagen
     * @param _isPublic Si el vault es publico o privado
     * @param _targetAmount Monto objetivo (opcional)
     * @return La direccion del nuevo vault
     */
    function createSingleOwnerVault(
        string memory _name,
        string memory _description,
        string memory _category,
        string memory _imageURI,
        bool _isPublic,
        uint256 _targetAmount
    ) external returns (address);

    /**
     * @dev Obtiene todos los vaults creados por un usuario
     * @param _owner Direccion del usuario
     * @return Array de direcciones de vaults
     */
    function getVaultsByOwner(address _owner) external view returns (address[] memory);

    /**
     * @dev Obtiene todos los vaults publicos
     * @return Array de direcciones de vaults publicos
     */
    function getPublicVaults() external view returns (address[] memory);

    /**
     * @dev Verifica si una direccion es un vault creado por la fabrica
     * @param _vault Direccion del vault
     * @return true si es un vault, false en caso contrario
     */
    function isValidVault(address _vault) external view returns (bool);

    /**
     * @dev Eventos que debe emitir la fabrica
     */
    event VaultCreated(
        address indexed vault,
        address indexed owner,
        VaultType vaultType,
        string name,
        uint256 timestamp
    );
}