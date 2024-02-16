// const hre = require("hardhat");

// async function main() {
//   /**
//    * 1. Deploy list
//    * - Wen ETH Gas Station
//    * - wenETH Token
//    * - Wen Trade Pool
//    * - Wen Exchange
//    * - Wen Staking
//    * - Wen User Safe
//    * - Wen Treasury
//    *
//    * 2. Set Initial Info
//    *
//    * 3. Set Operators, Governors
//    *
//    * 4. [Only For Test] Mint NFT Collection
//    */

//   const [signer, operator] = await hre.ethers.getSigners();
//   const signerAddr = signer.address;
//   const operatorAddr = operator.address;
//   //   const blastAddress = 0x4300000000000000000000000000000000000002;
//   const blastAddress = "0x9B60b777601211eA1890Cd80224478858013C8C4";

//   let impl;
//   let tx;

//   let WenExchange;
//   let wenETHToken;
//   let RoyaltieManager;
//   let WenGasStation;
//   let WenTradePool;
//   let WenStaking;
//   let WenUserSafe;
//   let WenTreasury;

//   // ========== 1. Deploy All Contract ===========
//   // Upgradeable

//   impl = await hre.ethers.deployContract("WenGasStationV1");
//   await impl.waitForDeployment();
//   impl = await hre.ethers.deployContract("UUPSProxy", [impl.target, "0x"]);
//   await impl.waitForDeployment();
//   WenGasStation = await hre.ethers.getContractAt(
//     "WenGasStationV1",
//     impl.target
//   );

//   impl = await hre.ethers.deployContract("WenTradePoolV1");
//   await impl.waitForDeployment();
//   impl = await hre.ethers.deployContract("UUPSProxy", [impl.target, "0x"]);
//   await impl.waitForDeployment();
//   WenTradePool = await hre.ethers.getContractAt("WenTradePoolV1", impl.target);

//   impl = await hre.ethers.deployContract("WenStakingV1");
//   await impl.waitForDeployment();
//   impl = await hre.ethers.deployContract("UUPSProxy", [impl.target, "0x"]);
//   await impl.waitForDeployment();
//   WenStaking = await hre.ethers.getContractAt("WenStakingV1", impl.target);

//   impl = await hre.ethers.deployContract("WenUserSafeV1");
//   await impl.waitForDeployment();
//   impl = await hre.ethers.deployContract("UUPSProxy", [impl.target, "0x"]);
//   await impl.waitForDeployment();
//   WenUserSafe = await hre.ethers.getContractAt("WenUserSafeV1", impl.target);

//   impl = await hre.ethers.deployContract("WenTreasuryV1");
//   await impl.waitForDeployment();
//   impl = await hre.ethers.deployContract("UUPSProxy", [impl.target, "0x"]);
//   await impl.waitForDeployment();
//   WenTreasury = await hre.ethers.getContractAt("WenTreasuryV1", impl.target);

//   //   // Non-Upgradeable

//   RoyaltieManager = await hre.ethers.deployContract("RoyaltiesManager");
//   await RoyaltieManager.waitForDeployment();

//   wenETHToken = await hre.ethers.deployContract("WenETHToken", [blastAddress]); // TODO: constructor 안 blast 관련 컨트렉트 주석 삭제
//   await wenETHToken.waitForDeployment();

//   WenExchange = await hre.ethers.deployContract("WenExchangeV1", [
//     // TODO: constructor 안 blast 관련 컨트렉트 주석 삭제
//     // TODO: 컨트렉트 주석 삭제
//     signerAddr,
//     operatorAddr,
//     wenETHToken.target,
//     RoyaltieManager.target,
//     0,
//     0,
//     WenTradePool.target,
//     blastAddress,
//   ]);
//   await WenExchange.waitForDeployment();

//   console.log("WenExchange Address: >>>", WenExchange.target);
//   console.log("wenETHToken Address: >>>", wenETHToken.target);
//   console.log("WenGasStation Address: >>>", WenGasStation.target);
//   console.log("WenTradePool Address: >>>", WenTradePool.target);
//   console.log("WenStaking Address: >>>", WenStaking.target);
//   console.log("WenUserSafe Address: >>>", WenUserSafe.target);
//   console.log("WenTreasury Address: >>>", WenTreasury.target);

//   // ========== 2. initialize() Upgradeable Contract ===========
//   console.log("initialize - start");
//   tx = await WenGasStation.connect(signer).initialize();
//   await tx.wait();
//   tx = await WenTradePool.connect(signer).initialize();
//   await tx.wait();
//   tx = await WenStaking.connect(signer).initialize();
//   await tx.wait();
//   tx = await WenUserSafe.connect(signer).initialize();
//   await tx.wait();
//   tx = await WenTreasury.connect(signer).initialize();
//   await tx.wait();
//   console.log("initialize - end");

//   // ========== 3. SetInitial Info Upgradeable Contract ===========

//   // 3-1. Gas Station: setInitialInfo, add Fee giver (including ownself), add Fee Receiver, set Operator

//   //   tx = await WenGasStation.connect(signer).setInitialInfo(blastAddress); //TODO: 주석 지우기
//   //   await tx.wait();

//   tx = await WenGasStation.connect(signer).addFeeGiver(wenETHToken.target);
//   await tx.wait();
//   tx = await WenGasStation.connect(signer).addFeeGiver(WenTradePool.target);
//   await tx.wait();
//   tx = await WenGasStation.connect(signer).addFeeGiver(WenExchange.target);
//   await tx.wait();
//   tx = await WenGasStation.connect(signer).addFeeGiver(WenGasStation.target);
//   await tx.wait();

//   tx = await WenGasStation.connect(signer).addFeeReceiver(
//     WenUserSafe.target,
//     7300
//   );
//   await tx.wait();
//   tx = await WenGasStation.connect(signer).addFeeReceiver(
//     WenStaking.target,
//     2000
//   );
//   await tx.wait();
//   tx = await WenGasStation.connect(signer).addFeeReceiver(
//     WenTreasury.target,
//     700
//   );
//   await tx.wait();

//   tx = await WenGasStation.connect(signer).setOperator([operatorAddr]);
//   await tx.wait();

//   // 3-2. WenETH Token: setOperator (Wen Trade Pool), setGovernor (Gas Station)
//   tx = await wenETHToken.connect(signer).setOperator([WenTradePool.target]);
//   await tx.wait();

//   //   tx = await wenETHToken.connect(signer).setBlastGovernor(WenGasStation.target); //TODO: 지우기.
//   //   await tx.wait();

//   // 3-3. WenTradePool: setInitialInfo, setGovernor (Gas Station), setOperator (Bot)

//   //   tx = await WenTradePool.connect(signer).setInitialInfo(wenETHToken.target,blastAddress); //TODO: 주석 지우기
//   //   await tx.wait();

//   //       tx = await WenTradePool.connect(signer).setBlastGovernor(WenGasStation.target); //TODO: 지우기.
//   //   await tx.wait();

//   tx = await WenTradePool.connect(signer).setOperator([operatorAddr]);
//   await tx.wait();

//   // 3-4. WenExchangeV2: setGovernor (Gas station)

//   //     tx = await WenExchange.connect(signer).setBlastGovernor(WenGasStation.target); //TODO: 지우기.
//   // await tx.wait();
// }

// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });
