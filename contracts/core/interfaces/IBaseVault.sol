// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IBaseVault
 * @dev Interfaz para el contrato base de vault
 */
interface IBaseVault {
    /**
     * @dev Permite a un usuario depositar ETH en el vault
     */
    function deposit() external payable;
    
    /**
     * @dev Función para retirar fondos del vault
     * @param _recipient Dirección del destinatario
     * @param _amount Cantidad a retirar
     */
    function withdraw(address payable _recipient, uint256 _amount) external;
    
    /**
     * @dev Actualiza la configuración del vault
     * @param _name Nuevo nombre
     * @param _description Nueva descripción
     * @param _category Nueva categoría
     * @param _imageURI Nueva URI de imagen
     */
    function updateVaultConfig(
        string memory _name,
        string memory _description,
        string memory _category,
        string memory _imageURI
    ) external;
    
    /**
     * @dev Actualiza el estado de actividad del vault
     * @param _isActive Nuevo estado de actividad
     */
    function setActive(bool _isActive) external;
    
    /**
     * @dev Agrega un depositante permitido
     * @param _depositor Dirección del depositante
     */
    function addAllowedDepositor(address _depositor) external;
    
    /**
     * @dev Elimina un depositante permitido
     * @param _depositor Dirección del depositante
     */
    function removeAllowedDepositor(address _depositor) external;
    
    /**
     * @dev Cambia la visibilidad del vault
     * @param _isPublic Nueva visibilidad
     */
    function setPublic(bool _isPublic) external;
    
    /**
     * @dev Obtiene el balance actual del vault
     */
    function getBalance() external view returns (uint256);
    
    /**
     * @dev Verifica si una dirección puede depositar en el vault
     * @param _depositor Dirección a verificar
     */
    function canDeposit(address _depositor) external view returns (bool);
}