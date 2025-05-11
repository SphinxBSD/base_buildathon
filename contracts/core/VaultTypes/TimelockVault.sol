// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../BaseVault.sol";

/**
 * @title TimelockVault
 * @dev Implementación del vault tipo 3: bloqueo temporal
 * Las operaciones de retiro deben esperar un período de tiempo antes de ejecutarse
 */
contract TimelockVault is BaseVault {
    // Estructuras para operaciones con timelock
    struct TimelockOperation {
        address recipient;
        uint256 amount;
        uint256 executeAfter;
        bool executed;
        bool cancelled;
    }
    
    // Estado del timelock
    uint256 public timelockDuration;
    uint256 public operationCount;
    mapping(uint256 => TimelockOperation) public timelockOperations;
    
    // Eventos específicos
    event TimelockDurationChanged(uint256 newDuration);
    event OperationScheduled(uint256 indexed operationId, address indexed recipient, uint256 amount, uint256 executeAfter);
    event OperationExecuted(uint256 indexed operationId);
    event OperationCancelled(uint256 indexed operationId);
    
    /**
     * @dev Constructor
     * @param _owner Dirección del propietario/creador del vault
     * @param _name Nombre del vault
     * @param _description Descripción del vault
     * @param _category Categoría del vault
     * @param _imageURI URI de la imagen
     * @param _isPublic Si el vault es público o privado
     * @param _targetAmount Monto objetivo (opcional)
     * @param _timelockDuration Duración del período de bloqueo en segundos
     */
    constructor(
        address _owner,
        string memory _name,
        string memory _description,
        string memory _category,
        string memory _imageURI,
        bool _isPublic,
        uint256 _targetAmount,
        uint256 _timelockDuration
    ) BaseVault(
        _owner,
        _name,
        _description,
        _category,
        _imageURI,
        _isPublic,
        _targetAmount,
        VaultType.TIMELOCK
    ) {
        require(_timelockDuration > 0, "TimelockVault: duration must be greater than 0");
        timelockDuration = _timelockDuration;
        
        emit TimelockDurationChanged(_timelockDuration);
        emit TimelockSet(address(this), _timelockDuration);
    }
    
    /**
     * @dev Cambia la duración del período de bloqueo
     * @param _newDuration Nueva duración en segundos
     */
    function setTimelockDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "TimelockVault: duration must be greater than 0");
        timelockDuration = _newDuration;
        
        emit TimelockDurationChanged(_newDuration);
        emit TimelockSet(address(this), _newDuration);
    }
    
    /**
     * @dev Programa una operación de retiro con timelock
     * @param _recipient Destinatario de los fondos
     * @param _amount Cantidad a retirar
     */
    function scheduleWithdrawal(address payable _recipient, uint256 _amount) external onlyOwner nonReentrant returns (uint256) {
        require(_recipient != address(0), "TimelockVault: invalid recipient");
        require(_amount > 0 && _amount <= address(this).balance, "TimelockVault: invalid amount");
        
        uint256 operationId = operationCount++;
        uint256 executeAfter = block.timestamp + timelockDuration;
        
        timelockOperations[operationId] = TimelockOperation({
            recipient: _recipient,
            amount: _amount,
            executeAfter: executeAfter,
            executed: false,
            cancelled: false
        });
        
        emit OperationScheduled(operationId, _recipient, _amount, executeAfter);
        emit TimelockWithdrawalScheduled(address(this), operationId, _recipient, _amount, executeAfter);
        
        return operationId;
    }
    
    /**
     * @dev Ejecuta una operación programada después del período de bloqueo
     * @param _operationId ID de la operación
     */
    function executeTimelockWithdrawal(uint256 _operationId) external nonReentrant {
        TimelockOperation storage operation = timelockOperations[_operationId];
        
        require(!operation.executed, "TimelockVault: already executed");
        require(!operation.cancelled, "TimelockVault: already cancelled");
        require(block.timestamp >= operation.executeAfter, "TimelockVault: timelock not expired");
        require(operation.amount <= address(this).balance, "TimelockVault: insufficient balance");
        
        operation.executed = true;
        
        address payable recipient = payable(operation.recipient);
        uint256 amount = operation.amount;
        
        _executeWithdrawal(recipient, amount);
        
        emit OperationExecuted(_operationId);
        emit TimelockWithdrawalExecuted(address(this), _operationId);
        emit VaultWithdrawal(address(this), recipient, amount, address(this).balance);
    }
    
    /**
     * @dev Cancela una operación programada
     * @param _operationId ID de la operación
     */
    function cancelTimelockWithdrawal(uint256 _operationId) external onlyOwner nonReentrant {
        TimelockOperation storage operation = timelockOperations[_operationId];
        
        require(!operation.executed, "TimelockVault: already executed");
        require(!operation.cancelled, "TimelockVault: already cancelled");
        
        operation.cancelled = true;
        
        emit OperationCancelled(_operationId);
        emit TimelockWithdrawalCancelled(address(this), _operationId);
    }
    
    /**
     * @dev La función withdraw es sobreescrita pero revierte
     * Se debe usar el flujo de timelock para retiros
     */
    function withdraw(address payable _recipient, uint256 _amount) external override {
        revert("TimelockVault: use scheduleWithdrawal instead");
    }
    
    /**
     * @dev Obtiene información de una operación
     * @param _operationId ID de la operación
     */
    function getOperationInfo(uint256 _operationId) external view returns (
        address recipient,
        uint256 amount,
        uint256 executeAfter,
        bool executed,
        bool cancelled,
        bool isReady
    ) {
        TimelockOperation storage operation = timelockOperations[_operationId];
        
        return (
            operation.recipient,
            operation.amount,
            operation.executeAfter,
            operation.executed,
            operation.cancelled,
            (block.timestamp >= operation.executeAfter && !operation.executed && !operation.cancelled)
        );
    }
    
    /**
     * @dev Calcula el tiempo restante para que una operación sea ejecutable
     * @param _operationId ID de la operación
     */
    function getTimeRemaining(uint256 _operationId) external view returns (uint256) {
        TimelockOperation storage operation = timelockOperations[_operationId];
        
        if (operation.executed || operation.cancelled || block.timestamp >= operation.executeAfter) {
            return 0;
        }
        
        return operation.executeAfter - block.timestamp;
    }
}