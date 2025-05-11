// verification/verify_contracts.js
const { run } = require("hardhat");

/**
 * Verifica un contrato en el explorador de bloques
 * @param {string} contractAddress Dirección del contrato
 * @param {Array} args Argumentos del contrato (constructor)
 */
async function verify(contractAddress, args = []) {
  console.log(`Verificando contrato en ${contractAddress}`);
  
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
    console.log("¡Contrato verificado con éxito!");
  } catch (error) {
    if (error.message.includes("Reason: Already Verified")) {
      console.log("El contrato ya está verificado");
    } else {
      console.error("Error al verificar el contrato:", error);
    }
  }
}

module.exports = { verify };
