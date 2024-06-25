const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("SwapModule", (m) => {
  const swap = m.contract("Swap", [unlockTime], {
    value: lockedAmount,
  });

  return { swap };
});
