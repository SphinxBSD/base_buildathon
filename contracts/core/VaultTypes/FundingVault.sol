// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../BaseVault.sol";

/**
 * @title FundingVault
 * @dev Implementación del vault tipo 4: objetivo de financiación
 * Permite establecer un objetivo de financiación y rastrear su progreso
 */
contract FundingVault is BaseVault {
    // Estado para objetivo de financiación
    bool public targetReached;
    uint256 public targetReachedAt;
    
    // Eventos específicos
    event TargetReached(uint256 targetAmount, uint256 timestamp);
    event TargetUpdated(uint256 oldTarget, uint256 newTarget);
    
    /**
     * @dev Modificador para verificar que el objetivo no ha sido alcanzado
     */
    modifier targetNotReached() {
        require(!targetReached, "FundingVault: target already reached");
        _;
    }
    
    /**
     * @dev Constructor
     * @param _owner Dirección del propietario/creador del vault
     * @param _name Nombre del vault
     * @param _description Descripción del vault
     * @param _category Categoría del vault
     * @param _imageURI URI de la imagen
     * @param _isPublic Si el vault es público o privado
     * @param _targetAmount Monto objetivo (requerido)
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
        VaultType.FUNDING_TARGET
    ) {
        require(_targetAmount > 0, "FundingVault: target must be greater than 0");
    }
    
    /**
     * @dev Sobreescribe la función de depósito para verificar si se alcanza el objetivo
     */
    function deposit() external payable override onlyActive nonReentrant {
        require(msg.value > 0, "FundingVault: deposit amount must be greater than 0");
        require(metadata.isPublic || allowedDepositors[msg.sender], "FundingVault: not allowed to deposit");
        
        _deposit(msg.sender, msg.value);
        
        // Verificar si se alcanzó el objetivo
        if (!targetReached && address(this).balance >= targetAmount) {
            targetReached = true;
            targetReachedAt = block.timestamp;
            
            emit TargetReached(targetAmount, targetReachedAt);
            emit TargetReached(address(this), targetAmount, targetReachedAt);
        }
        
        emit VaultFunded(address(this), msg.value, address(this).balance, targetAmount, targetReached);
    }
    
    /**
     * @dev Actualiza el objetivo de financiación
     * @param _newTarget Nuevo objetivo
     */
    function updateTargetAmount(uint256 _newTarget) external onlyOwner targetNotReached {
        require(_newTarget > 0, "FundingVault: target must be greater than 0");
        
        uint256 oldTarget = targetAmount;
        targetAmount = _newTarget;
        
        emit TargetUpdated(oldTarget, _newTarget);
        emit TargetAmountUpdated(address(this), oldTarget, _newTarget);
        
        // Verificar si el nuevo objetivo ya se ha alcanzado
        if (address(this).balance >= targetAmount) {
            targetReached = true;
            targetReachedAt = block.timestamp;
            
            emit TargetReached(targetAmount, targetReachedAt);
            emit TargetReached(address(this), targetAmount, targetReachedAt);
        }
    }
    
    /**
     * @dev Función para retirar fondos del vault
     * @param _recipient Dirección del destinatario
     * @param _amount Cantidad a retirar
     */
    function withdraw(address payable _recipient, uint256 _amount) external override onlyOwner nonReentrant {
        _executeWithdrawal(_recipient, _amount);
        
        emit VaultWithdrawal(address(this), _recipient, _amount, address(this).balance);
    }
    
    /**
     * @dev Obtiene el progreso hacia el objetivo de financiación
     */
    function getFundingProgress() external view returns (uint256 current, uint256 target, uint256 percentage, bool reached) {
        uint256 balance = address(this).balance;
        uint256 calculatedPercentage = targetAmount > 0 ? (balance * 100) / targetAmount : 0;
        
        return (
            balance,
            targetAmount,
            calculatedPercentage,
            targetReached
        );
    }
}