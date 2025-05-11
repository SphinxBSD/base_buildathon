const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { ethers } = require("hardhat");
const { VaultFactoryModule } = require("./00_VaultsFactory");

module.exports = buildModule("DeployVaultsModule", (m) => { // <-- Quitamos async
  const { vaultFactory } = m.useModule(VaultFactoryModule);
  
  const owner = m.getAccount(0); // Síncrono
  const targetAmount = ethers.parseEther("10"); // Síncrono

  const singleOwnerVaultTx = m.call(vaultFactory, "createSingleOwnerVault", [
    owner,
    "Mi Primera Bóveda",
    "Una bóveda de prueba para almacenar ETH",
    "Personal",
    "ipfs://QmExample",
    true,
    targetAmount
  ]);

  const singleOwnerVaultAddress = m.getEventArgument(
    singleOwnerVaultTx,
    "VaultCreated",
    "vault",
    0
  );
  
  const singleOwnerVault = m.contractAt("SingleOwnerVault", singleOwnerVaultAddress);
  
  const depositValue = ethers.parseEther("1");
  m.call(singleOwnerVault, "deposit", [], {
    value: depositValue
  });
  
  return { 
    vaultFactory,
    singleOwnerVault,
    singleOwnerVaultAddress
  };
});