"use strict";

const { dfn, bnMantissa, BN, expectEqual } = require("./JS");
const {
  encodeParameters,
  etherBalance,
  etherUnsigned,
  address,
  encode,
  encodePacked,
} = require("./Ethereum");
const { hexlify, keccak256, toUtf8Bytes } = require("ethers");

// 1. [TEST]
const MockERC721 = artifacts.require("MockERC721");

async function makeERC721(opts = {}) {
  return await MockERC721.new();
}

module.exports = {
  MockERC721,
  makeERC721,
};
