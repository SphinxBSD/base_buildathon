// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../BaseVault.sol";

/**
 * @title SingleOwnerVault
 * @dev Implementación del vault tipo 1: administración exclusiva
 * Un solo propietario tiene control total sobre el vault
 */
contract SingleOwnerVault is BaseVault {

    /**
     * @dev Constructor
     * @param _owner Dirección del propietario/creador del vault
     * @param _name Nombre del vault
     * @param _description Descripción del vault
     * @param _category Categoría del vault
     * @param _imageURI URI de la imagen
     * @param _isPublic Si el vault es público o privado
     * @param _targetAmount Monto objetivo (opcional)
     */
    
    constructor(
        address _owner,
        string memory _name,
        string memory _description,
        string memory _category,
        string memory _imageURI,
        bool _isPublic,
        uint256 _targetAmount
    ) BaseVault(
        _owner,
        _name,
        _description,
        _category,
        _imageURI,
        _isPublic,
        _targetAmount,
        VaultType.SINGLE_OWNER
    ) {}
    
    /**
     * @dev Función para retirar fondos del vault
     * @param _recipient Dirección del destinatario
     * @param _amount Cantidad a retirar
     */
    function withdraw(address payable _recipient, uint256 _amount) external override onlyOwner nonReentrant {
        _executeWithdrawal(_recipient, _amount);
        
        // Verificar si todavía hay un objetivo de financiación
        if (targetAmount > 0) {
            emit VaultWithdrawal(address(this), _recipient, _amount, address(this).balance);
        }
    }
}