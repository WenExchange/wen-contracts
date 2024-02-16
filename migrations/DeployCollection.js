const { sign } = require("crypto");
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

  const [signer] = await hre.ethers.getSigners();
  const signerAddr = signer.address;

  let tx;

  let collection = await hre.ethers.deployContract("MockERC721");
  await collection.waitForDeployment();

  tx = await collection
    .connect(signer)
    .safeMint(
      signerAddr,
      "https://ipfs.io/ipfs/QmZcH4YvBVVRJtdn4RdbaqgspFU8gH6P9vomDpBVpAL3u4"
    );
  await tx.wait();

  tx = await collection
    .connect(signer)
    .safeMint(
      signerAddr,
      "https://ipfs.io/ipfs/QmZcH4YvBVVRJtdn4RdbaqgspFU8gH6P9vomDpBVpAL3u4"
    );
  await tx.wait();

  tx = await collection
    .connect(signer)
    .safeMint(
      signerAddr,
      "https://ipfs.io/ipfs/QmZcH4YvBVVRJtdn4RdbaqgspFU8gH6P9vomDpBVpAL3u4"
    );
  await tx.wait();

  tx = await collection
    .connect(signer)
    .safeMint(
      "0xc138b0459DD44543f03C47F476F35c173a3F4071",
      "https://ipfs.io/ipfs/QmZcH4YvBVVRJtdn4RdbaqgspFU8gH6P9vomDpBVpAL3u4"
    );
  await tx.wait();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
