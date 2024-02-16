const hre = require("hardhat");

async function main() {
  /**
   * 1. Deploy list
   * - Wen ETH Gas Station
   * - wenETH Token
   * - Wen Trade Pool
   * - Wen Exchange
   * - Wen Staking
   * - Wen User Safe
   * - Wen Treasury
   *
   * 2. Set Initial Info
   *
   * 3. Set Operators, Governors
   *
   * 4. [Only For Test] Mint NFT Collection
   */

  const [signer, operator] = await hre.ethers.getSigners();

  //   await hre.run("verify:verify", {
  //     address: "0x59539282fbb60B9A706136Cf201BBeAf8Bce3406",
  //     contract: "contracts/UUPSProxy.sol:UUPSProxy",
  //     constructorArguments: ["0xB57722AD12A1DCf3B9686AD0188BD216235a8EA6", "0x"],
  //   });

  await hre.run("verify:verify", {
    address: "0xB57722AD12A1DCf3B9686AD0188BD216235a8EA6",
    contract: "contracts/WenUserSafeV1.sol:WenUserSafeV1",
    constructorArguments: [],
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
