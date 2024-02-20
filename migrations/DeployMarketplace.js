const hre = require("hardhat");

async function main() {
  const [signer, operator] = await hre.ethers.getSigners();
  const signerAddr = signer.address;
  const operatorAddr = operator.address;
  const blastAddress = "0x4300000000000000000000000000000000000002";

  let impl;
  let tx;

  let WenExchange;
  let WenGasStation;
  let RoyaltieManager;

  // ========== 1. Deploy All Contract ===========
  // Upgradeable

  //   RoyaltieManager = await hre.ethers.deployContract("RoyaltiesManager");
  //   await RoyaltieManager.waitForDeployment();

  RoyaltieManager = await hre.ethers.getContractAt(
    "RoyaltiesManager",
    "0x43A3BA7488C8D3b965BfdB75Dbe2A029D4E88228"
  );

  WenGasStation = await hre.ethers.getContractAt(
    "WenGasStationV1",
    "0xE1178f7eD637e70B551596e48c651CAF3394c247"
  );

  WenExchange = await hre.ethers.getContractAt(
    "WenExchangeV1",
    "0x6041ACd8c201BECB47bBA8cb2337BE241ed53e5f"
  );

  // WenExchange = await hre.ethers.deployContract("WenExchangeV1", [
  //   signerAddr,
  //   operatorAddr,
  //   "0xd44cDe3AC1B0Ea355E6e41Ff938B6FaB4624ECb6",
  //   RoyaltieManager.target,
  //   0,
  //   0,
  //   "0xE4e5f726677A159B69e0159f464693E430227811",
  //   blastAddress,
  // ]);
  // await WenExchange.waitForDeployment();

  console.log("WenExchange Address: >>>", WenExchange.target);
  console.log("RoyaltieManager Address: >>>", RoyaltieManager.target);

  // ========== 2. SetInitial Info Upgradeable Contract ===========

  // 3-1. Gas Station: setInitialInfo, add Fee giver (including ownself), add Fee Receiver, set Operator
  console.log("setInitialInfo - start");

  // Delete past one
  tx = await WenGasStation.connect(signer).removeFeeGiver(
    "0xFdc27371A04d9C4B632a0B0378Bc471f556FCAb2"
  );
  await tx.wait();
  // Add new one
  tx = await WenGasStation.connect(signer).addFeeGiver(WenExchange.target);
  await tx.wait();

  tx = await WenExchange.connect(signer).setBlastGovernor(WenGasStation.target);
  await tx.wait();
  console.log("setInitialInfo - End All");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
