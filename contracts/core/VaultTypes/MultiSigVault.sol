// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../BaseVault.sol";

/**
 * @title MultiSigVault
 * @dev Implementación del vault tipo 2: co-administración
 * Requiere aprobación de múltiples administradores para retirar fondos
 */
contract MultiSigVault is BaseVault {
    // Estructuras para propuestas de retiro
    struct WithdrawalProposal {
        address recipient;
        uint256 amount;
        uint256 approvals;
        bool executed;
        bool cancelled;
        mapping(address => bool) hasApproved;
    }
    
    // Estado del vault multisig
    mapping(address => bool) public coAdmins;
    uint256 public coAdminCount;
    uint256 public requiredApprovals;
    uint256 public proposalCount;
    mapping(uint256 => WithdrawalProposal) public withdrawalProposals;
    
    // Eventos específicos
    event CoAdminAdded(address indexed admin);
    event CoAdminRemoved(address indexed admin);
    event RequiredApprovalsChanged(uint256 newRequired);
    event ProposalCreated(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event ProposalApproved(uint256 indexed proposalId, address indexed approver);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    
    /**
     * @dev Modificador para verificar que el remitente es un administrador
     */
    modifier onlyAdmin() {
        require(msg.sender == owner() || coAdmins[msg.sender], "MultiSigVault: not an admin");
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
     * @param _initialCoAdmins Lista inicial de co-administradores
     * @param _requiredApprovals Número de aprobaciones requeridas
     */
    constructor(
        address _owner,
        string memory _name,
        string memory _description,
        string memory _category,
        string memory _imageURI,
        bool _isPublic,
        uint256 _targetAmount,
        address[] memory _initialCoAdmins,
        uint256 _requiredApprovals
    ) BaseVault(
        _owner,
        _name,
        _description,
        _category,
        _imageURI,
        _isPublic,
        _targetAmount,
        VaultType.MULTI_SIG
    ) {
        // Añadir co-administradores iniciales
        for (uint256 i = 0; i < _initialCoAdmins.length; i++) {
            address admin = _initialCoAdmins[i];
            require(admin != address(0) && admin != _owner, "MultiSigVault: invalid admin");
            coAdmins[admin] = true;
            emit CoAdminAdded(admin);
            
            // Emitir evento global
            emit CoAdminAdded(address(this), admin);
        }
        
        coAdminCount = _initialCoAdmins.length;
        
        // Validar y establecer aprobaciones requeridas
        uint256 totalAdmins = coAdminCount + 1; // +1 por el owner
        require(_requiredApprovals > 0 && _requiredApprovals <= totalAdmins, "MultiSigVault: invalid approvals");
        requiredApprovals = _requiredApprovals;
    }
    
    /**
     * @dev Añade un nuevo co-administrador
     * @param _admin Dirección del nuevo co-administrador
     */
    function addCoAdmin(address _admin) external onlyOwner {
        require(_admin != address(0) && _admin != owner(), "MultiSigVault: invalid admin");
        require(!coAdmins[_admin], "MultiSigVault: already admin");
        
        coAdmins[_admin] = true;
        coAdminCount++;
        
        emit CoAdminAdded(_admin);
        emit CoAdminAdded(address(this), _admin);
    }
    
    /**
     * @dev Elimina un co-administrador
     * @param _admin Dirección del co-administrador a eliminar
     */
    function removeCoAdmin(address _admin) external onlyOwner {
        require(coAdmins[_admin], "MultiSigVault: not an admin");
        
        coAdmins[_admin] = false;
        coAdminCount--;
        
        emit CoAdminRemoved(_admin);
        emit CoAdminRemoved(address(this), _admin);
        
        // Ajustar las aprobaciones requeridas si es necesario
        if (requiredApprovals > coAdminCount + 1) {
            requiredApprovals = coAdminCount + 1;
            emit RequiredApprovalsChanged(requiredApprovals);
        }
    }
    
    /**
     * @dev Cambia el número de aprobaciones requeridas
     * @param _requiredApprovals Nuevo número de aprobaciones requeridas
     */
    function setRequiredApprovals(uint256 _requiredApprovals) external onlyOwner {
        uint256 totalAdmins = coAdminCount + 1; // +1 por el owner
        require(_requiredApprovals > 0 && _requiredApprovals <= totalAdmins, "MultiSigVault: invalid approvals");
        
        requiredApprovals = _requiredApprovals;
        emit RequiredApprovalsChanged(_requiredApprovals);
    }
    
    /**
     * @dev Crea una propuesta de retiro
     * @param _recipient Destinatario de los fondos
     * @param _amount Cantidad a retirar
     */
    function proposeWithdrawal(address payable _recipient, uint256 _amount) external onlyAdmin nonReentrant returns (uint256) {
        require(_recipient != address(0), "MultiSigVault: invalid recipient");
        require(_amount > 0 && _amount <= address(this).balance, "MultiSigVault: invalid amount");
        
        uint256 proposalId = proposalCount++;
        WithdrawalProposal storage proposal = withdrawalProposals[proposalId];
        
        proposal.recipient = _recipient;
        proposal.amount = _amount;
        proposal.executed = false;
        proposal.cancelled = false;
        
        // El creador de la propuesta la aprueba automáticamente
        proposal.hasApproved[msg.sender] = true;
        proposal.approvals = 1;
        
        emit ProposalCreated(proposalId, _recipient, _amount);
        emit ProposalApproved(proposalId, msg.sender);
        
        // Emitir evento global
        emit WithdrawalProposed(address(this), proposalId, msg.sender, _recipient, _amount);
        emit WithdrawalApproved(address(this), proposalId, msg.sender);
        
        return proposalId;
    }
    
    /**
     * @dev Aprueba una propuesta de retiro existente
     * @param _proposalId ID de la propuesta
     */
    function approveWithdrawal(uint256 _proposalId) external onlyAdmin nonReentrant {
        WithdrawalProposal storage proposal = withdrawalProposals[_proposalId];
        
        require(!proposal.executed, "MultiSigVault: already executed");
        require(!proposal.cancelled, "MultiSigVault: already cancelled");
        require(!proposal.hasApproved[msg.sender], "MultiSigVault: already approved");
        
        proposal.hasApproved[msg.sender] = true;
        proposal.approvals++;
        
        emit ProposalApproved(_proposalId, msg.sender);
        emit WithdrawalApproved(address(this), _proposalId, msg.sender);
        
        // Ejecutar automáticamente si alcanzó las aprobaciones requeridas
        if (proposal.approvals >= requiredApprovals) {
            _executeProposal(_proposalId);
        }
    }
    
    /**
     * @dev Cancela una propuesta de retiro
     * @param _proposalId ID de la propuesta
     */
    function cancelWithdrawal(uint256 _proposalId) external nonReentrant {
        WithdrawalProposal storage proposal = withdrawalProposals[_proposalId];
        
        require(!proposal.executed, "MultiSigVault: already executed");
        require(!proposal.cancelled, "MultiSigVault: already cancelled");
        
        // Solo el owner o el creador de la propuesta pueden cancelarla
        require(msg.sender == owner(), "MultiSigVault: not authorized");
        
        proposal.cancelled = true;
        
        emit ProposalCancelled(_proposalId);
        emit WithdrawalRejected(address(this), _proposalId, msg.sender);
    }
    
    /**
     * @dev Ejecuta una propuesta aprobada
     * @param _proposalId ID de la propuesta
     */
    function executeWithdrawal(uint256 _proposalId) external onlyAdmin nonReentrant {
        require(withdrawalProposals[_proposalId].approvals >= requiredApprovals, 
                "MultiSigVault: insufficient approvals");
        _executeProposal(_proposalId);
    }
    
    /**
     * @dev Ejecuta internamente una propuesta
     * @param _proposalId ID de la propuesta
     */
    function _executeProposal(uint256 _proposalId) internal {
        WithdrawalProposal storage proposal = withdrawalProposals[_proposalId];
        
        require(!proposal.executed, "MultiSigVault: already executed");
        require(!proposal.cancelled, "MultiSigVault: already cancelled");
        require(proposal.approvals >= requiredApprovals, "MultiSigVault: insufficient approvals");
        require(proposal.amount <= address(this).balance, "MultiSigVault: insufficient balance");
        
        proposal.executed = true;
        
        address payable recipient = payable(proposal.recipient);
        uint256 amount = proposal.amount;
        
        _executeWithdrawal(recipient, amount);
        
        emit ProposalExecuted(_proposalId);
        emit WithdrawalExecuted(address(this), _proposalId, recipient, amount);
        emit VaultWithdrawal(address(this), recipient, amount, address(this).balance);
    }
    
    /**
     * @dev La función withdraw es sobreescrita pero revierte
     * Se debe usar el flujo de propuestas para retiros
     */
    function withdraw(address payable _recipient, uint256 _amount) external override {
        revert("MultiSigVault: use proposeWithdrawal instead");
    }
    
    /**
     * @dev Verifica si una dirección es administrador
     * @param _admin Dirección a verificar
     */
    function isAdmin(address _admin) external view returns (bool) {
        return (_admin == owner() || coAdmins[_admin]);
    }
    
    /**
     * @dev Obtiene información de una propuesta
     * @param _proposalId ID de la propuesta
     */
    function getProposalInfo(uint256 _proposalId) external view returns (
        address recipient,
        uint256 amount,
        uint256 approvals,
        bool executed,
        bool cancelled
    ) {
        WithdrawalProposal storage proposal = withdrawalProposals[_proposalId];
        
        return (
            proposal.recipient,
            proposal.amount,
            proposal.approvals,
            proposal.executed,
            proposal.cancelled
        );
    }
    
    /**
     * @dev Verifica si un administrador ha aprobado una propuesta
     * @param _proposalId ID de la propuesta
     * @param _admin Dirección del administrador
     */
    function hasApproved(uint256 _proposalId, address _admin) external view returns (bool) {
        return withdrawalProposals[_proposalId].hasApproved[_admin];
    }
}