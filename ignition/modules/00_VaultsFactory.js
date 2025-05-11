// ignition/modules/00_VaultsFactory.js
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

// Este módulo despliega el contrato VaultFactory y configura los tipos de bóvedas necesarios
const VaultFactoryModule = buildModule("VaultFactoryModule", async (m) => {
  // Desplegar el contrato VaultFactory
  const vaultFactory = m.contract("VaultFactory", []);
  
  // Registrar los tipos de bóvedas disponibles
  // Nota: Este paso puede ser opcional dependiendo de cómo esté implementado tu VaultFactory
  // Si tu VaultFactory ya conoce los tipos de bóvedas, puedes omitir esta parte
  try {
    const registerSingleOwnerVaultTx = m.call(vaultFactory, "registerVaultType", [
      "SingleOwnerVault",    // Nombre del contrato
      "0x00"                 // Identificador o bytecode del inicializador si es necesario
    ]);
  } catch (error) {
    // Si no existe el método registerVaultType, esto puede ser normal según tu implementación
    console.log("Nota: No se pudo registrar el tipo de bóveda. Esto puede ser normal si no se requiere registro explícito.");
  }
  
  // Retornar la instancia del contrato para que pueda ser utilizada por otros módulos
  return { vaultFactory };
});

module.exports = {
  VaultFactoryModule
};