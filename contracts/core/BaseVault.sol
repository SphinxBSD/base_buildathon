// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IBaseVault.sol";
import "../utils/VaultEvents.sol";

/**
 * @title BaseVault
 * @dev Contrato base para todos los tipos de vault
 * Implementa las funcionalidades comunes que todos los vaults necesitan
 */
abstract contract BaseVault is VaultEvents, IBaseVault, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // Estructuras de datos
    struct VaultMetadata {
        string name;
        string description;
        string category;
        string imageURI;
        bool isPublic;
        VaultType vaultType;
    }
    
    // Enumeraciones
    enum VaultType { SINGLE_OWNER, MULTI_SIG, TIMELOCK, FUNDING_TARGET }
    
    // Estado del vault
    VaultMetadata public metadata;
    uint256 public targetAmount;
    uint256 public totalDeposited;
    address public immutable factory;
    mapping(address => uint256) public deposits;
    mapping(address => bool) public allowedDepositors;
    bool public isActive = true;
    
    // Eventos (además de los definidos en VaultEvents)
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);
    event VaultConfigUpdated(string name, string description, string category, string imageURI);
    event VaultStatusChanged(bool isActive);
    
    /**
     * @dev Modifier para verificar que el vault esté activo
     */
    modifier onlyActive() {
        require(isActive, "Vault: not active");
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
     * @param _targetAmount Monto objetivo (opcional)
     * @param _vaultType Tipo de vault
     */
    constructor(
        address _owner,
        string memory _name,
        string memory _description,
        string memory _category,
        string memory _imageURI,
        bool _isPublic,
        uint256 _targetAmount,
        VaultType _vaultType
    ) Ownable(_owner) {
        metadata = VaultMetadata({
            name: _name,
            description: _description,
            category: _category,
            imageURI: _imageURI,
            isPublic: _isPublic,
            vaultType: _vaultType
        });
        targetAmount = _targetAmount;
        factory = msg.sender;
        
        emit VaultCreated(address(this), _owner, _name, _description, _category, _imageURI, _isPublic, _targetAmount, uint8(_vaultType));
    }
    
    /**
     * @dev Función para recibir ETH
     */
    receive() external payable {
        if (msg.value > 0) {
            _deposit(msg.sender, msg.value);
        }
    }
    
    /**
     * @dev Permite a un usuario depositar ETH en el vault
     */
    function deposit() external payable virtual onlyActive nonReentrant {
        require(msg.value > 0, "Vault: deposit amount must be greater than 0");
        require(metadata.isPublic || allowedDepositors[msg.sender], "Vault: not allowed to deposit");
        
        _deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev Lógica interna para procesar un depósito
     * @param _depositor Dirección del depositante
     * @param _amount Cantidad depositada
     */
    function _deposit(address _depositor, uint256 _amount) internal {
        deposits[_depositor] += _amount;
        totalDeposited += _amount;
        
        emit Deposit(_depositor, _amount);
    }
    
    /**
     * @dev Función para retirar fondos del vault
     * @param _recipient Dirección del destinatario
     * @param _amount Cantidad a retirar
     */
    function withdraw(address payable _recipient, uint256 _amount) external virtual;
    
    /**
     * @dev Función interna para ejecutar el retiro de fondos
     * @param _recipient Dirección del destinatario
     * @param _amount Cantidad a retirar
     */
    function _executeWithdrawal(address payable _recipient, uint256 _amount) internal {
        require(_recipient != address(0), "Vault: recipient is zero address");
        require(_amount > 0, "Vault: amount must be greater than 0");
        require(_amount <= address(this).balance, "Vault: insufficient balance");
        
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Vault: transfer failed");
        
        emit Withdrawal(_recipient, _amount);
    }
    
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
    ) external onlyOwner {
        metadata.name = _name;
        metadata.description = _description;
        metadata.category = _category;
        metadata.imageURI = _imageURI;
        
        emit VaultConfigUpdated(_name, _description, _category, _imageURI);
    }
    
    /**
     * @dev Actualiza el estado de actividad del vault
     * @param _isActive Nuevo estado de actividad
     */
    function setActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
        emit VaultStatusChanged(_isActive);
    }
    
    /**
     * @dev Agrega un depositante permitido
     * @param _depositor Dirección del depositante
     */
    function addAllowedDepositor(address _depositor) external onlyOwner {
        require(_depositor != address(0), "Vault: depositor is zero address");
        allowedDepositors[_depositor] = true;
    }
    
    /**
     * @dev Elimina un depositante permitido
     * @param _depositor Dirección del depositante
     */
    function removeAllowedDepositor(address _depositor) external onlyOwner {
        allowedDepositors[_depositor] = false;
    }
    
    /**
     * @dev Cambia la visibilidad del vault
     * @param _isPublic Nueva visibilidad
     */
    function setPublic(bool _isPublic) external onlyOwner {
        metadata.isPublic = _isPublic;
    }
    
    /**
     * @dev Obtiene el balance actual del vault
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Obtiene la información completa del vault
     */
    function getVaultInfo() external view returns (
        address owner,
        string memory name,
        string memory description,
        string memory category,
        string memory imageURI,
        bool isPublic,
        uint256 balance,
        uint256 target,
        uint256 total,
        VaultType vaultType,
        bool active
    ) {
        return (
            owner,
            metadata.name,
            metadata.description,
            metadata.category,
            metadata.imageURI,
            metadata.isPublic,
            address(this).balance,
            targetAmount,
            totalDeposited,
            metadata.vaultType,
            isActive
        );
    }
    
    /**
     * @dev Verifica si una dirección puede depositar en el vault
     * @param _depositor Dirección a verificar
     */
    function canDeposit(address _depositor) external view returns (bool) {
        return metadata.isPublic || allowedDepositors[_depositor];
    }
}