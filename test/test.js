const { MockERC721, makeERC721 } = require("./Utils/Wen");

const {
  expectAlmostEqualMantissa,
  expectRevert,
  expectEvent,
  bnMantissa,
  BN,
  expectEqual,
  time,
} = require("./Utils/JS");
const { MAX_INT256 } = require("@openzeppelin/test-helpers/src/constants");

// 0. Mint NFT
// 1. List NFT
// 2. Buy NFT

contract("Mint NFT", function (accounts) {
  let root = accounts[0];
  let minter = accounts[1];
  const tokenURI = "sample";
  let NFTContract;

  describe("test", () => {
    before(async () => {
      NFTContract = await makeERC721();
    });

    it("test mint", async () => {
      let receipt = await NFTContract.safeMint(minter, tokenURI, {
        from: root,
      });
      expectEvent(receipt, "NewMint", {
        tokenId: new BN(1),
        owner: minter,
      });
    });
  });
});

// describe("Token contract", function () {
//   it("Deployment should assign the total supply of tokens to the owner", async function () {
//     const [owner] = await ethers.getSigners();
//     console.log(owner.address);

//     const hardhatToken = await ethers.deployContract("Token");

//     const ownerBalance = await hardhatToken.balanceOf(owner.address);
//     expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
//   });
// });
