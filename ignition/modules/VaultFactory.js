const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("VaultFactoryModule", (m) => {
    const deployer = m.getAccount(0);
    const vaultFactory = m.contract(
        "VaultFactory",
        [],
        {from: deployer}
    );

    return { vaultFactory, deployer};
});