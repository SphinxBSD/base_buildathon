// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title VaultEvents
 * @dev Contrato para centralizar los eventos emitidos por los vaults
 * Facilita el indexado con TheGraph
 */
contract VaultEvents {
    // Eventos para la creación y gestión de vaults
    event VaultCreated(
        address indexed vaultAddress,
        address indexed owner,
        string name,
        string description,
        string category,
        string imageURI,
        bool isPublic,
        uint256 targetAmount,
        uint8 vaultType
    );
    
    event VaultFunded(
        address indexed vaultAddress,
        uint256 amount,
        uint256 currentTotal,
        uint256 targetAmount,
        bool targetReached
    );
    
    event VaultWithdrawal(
        address indexed vaultAddress,
        address indexed recipient,
        uint256 amount,
        uint256 remainingBalance
    );
    
    // Eventos específicos para vaults con multisig
    event CoAdminAdded(
        address indexed vaultAddress,
        address indexed coAdmin
    );
    
    event CoAdminRemoved(
        address indexed vaultAddress,
        address indexed coAdmin
    );
    
    event WithdrawalProposed(
        address indexed vaultAddress,
        uint256 indexed proposalId,
        address indexed proposer,
        address recipient,
        uint256 amount
    );
    
    event WithdrawalApproved(
        address indexed vaultAddress,
        uint256 indexed proposalId,
        address indexed approver
    );
    
    event WithdrawalRejected(
        address indexed vaultAddress,
        uint256 indexed proposalId,
        address indexed rejecter
    );
    
    event WithdrawalExecuted(
        address indexed vaultAddress,
        uint256 indexed proposalId,
        address recipient,
        uint256 amount
    );
    
    // Eventos para vaults con timelock
    event TimelockSet(
        address indexed vaultAddress,
        uint256 durationInSeconds
    );
    
    event TimelockWithdrawalScheduled(
        address indexed vaultAddress,
        uint256 indexed operationId,
        address recipient,
        uint256 amount,
        uint256 executeAfter
    );
    
    event TimelockWithdrawalExecuted(
        address indexed vaultAddress,
        uint256 indexed operationId
    );
    
    event TimelockWithdrawalCancelled(
        address indexed vaultAddress,
        uint256 indexed operationId
    );
    
    // Eventos para integración con DeFi
    event FundsInvested(
        address indexed vaultAddress,
        address indexed protocol,
        uint256 amount
    );
    
    event InvestmentRedeemed(
        address indexed vaultAddress,
        address indexed protocol,
        uint256 amount,
        uint256 profit
    );
    
    // Eventos para objetivos de financiación
    event TargetReached(
        address indexed vaultAddress,
        uint256 targetAmount,
        uint256 timestamp
    );
    
    event TargetAmountUpdated(
        address indexed vaultAddress,
        uint256 previousTarget,
        uint256 newTarget
    );
}