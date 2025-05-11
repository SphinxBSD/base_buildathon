// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IBaseVault.sol";
import "./interfaces/IVaultFactory.sol";
import "./VaultTypes/SingleOwnerVault.sol";

/**
 * @title VaultFactory
 * @dev Fabrica para crear diferentes tipos de vaults
 */
contract VaultFactory is IVaultFactory {
    // Mapping de propietarios a sus vaults
    mapping(address => address[]) private ownerToVaults;

    // Array de vaults publicos
    address[] private publicVaults;

    // Mapping para verificar si una direccion es un vault creado por la fabrica
    mapping(address => bool) private isVault;

    /**
     * @dev Crea un nuevo vault de tipo SingleOwner
     * @param _name Nombre del vault
     * @param _description Descripción del vault
     * @param _category Categoría del vault
     * @param _imageURI URI de la imagen
     * @param _isPublic Si el vault es público o privado
     * @param _targetAmount Monto objetivo (opcional)
     * @return La dirección del nuevo vault
     */
    function createSingleOwnerVault(
        string memory _name,
        string memory _description,
        string memory _category,
        string memory _imageURI,
        bool _isPublic,
        uint256 _targetAmount
    ) external override returns (address) {
        
        // Crear el nuevo vault
        SingleOwnerVault newVault = new SingleOwnerVault(
            msg.sender,
            _name,
            _description,
            _category,
            _imageURI,
            _isPublic,
            _targetAmount
        );

        // Registrar el vault
        address vaultAddress = address(newVault);
        ownerToVaults[msg.sender].push(vaultAddress);
        isVault[vaultAddress] = true;

        // Si el vault es publico, agregarlo a la lista de vaults públicos
        if (_isPublic) {
            publicVaults.push(vaultAddress);
        }

        // Emitir evento de creación de vault
        emit VaultCreated(
            vaultAddress,
            msg.sender,
            IVaultFactory.VaultType.SingleOwner,
            _name,
            block.timestamp
        );
        return vaultAddress;
    }

    /**
     * @dev Obtiene todos los vaults creados por un propietario
     * @param _owner Dirección del propietario
     * @return Array de direcciones de vaults
     */
    function getVaultsByOwner(address _owner) external view override returns (address[] memory) {
        return ownerToVaults[_owner];
    }

    /**
     * @dev Obtiene todos los vaults públicos
     * @return Array de direcciones de vaults públicos
     */
    function getPublicVaults() external view override returns (address[] memory) {
        return publicVaults;
    }

    /**
     * @dev Verifica si una dirección es un vault creado por esta fábrica
     * @param _vault Dirección del vault
     * @return true si es un vault, false en caso contrario
     */
    function isValidVault(address _vault) external view returns (bool) {
        return isVault[_vault];
    }
    
}