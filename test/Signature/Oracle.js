// using ethereumjs-util 7.1.3
const ethUtil = require("ethereumjs-util");

const { ethers, JsonRpcProvider } = require("ethers");

// using ethereumjs-abi 0.6.9
const abi = require("ethereumjs-abi");

// using chai 4.3.4
const chai = require("chai");

let blockNum;

const getBlock = async () => {
  const provider = new JsonRpcProvider("http://localhost:8545");
  const blockNumber = await provider.getBlockNumber();

  blockNum = blockNumber.toString();
};

const typedData = {
  types: {
    EIP712Domain: [
      { name: "name", type: "string" },
      { name: "version", type: "string" },
      { name: "chainId", type: "uint256" },
      { name: "verifyingContract", type: "address" },
    ],
    Order: [
      { name: "trader", type: "address" },
      { name: "collection", type: "address" },
      { name: "listingsRoot", type: "bytes32" },
      { name: "numberOfListings", type: "uint256" },
      { name: "expirationTime", type: "uint256" },
      { name: "assetType", type: "uint8" },
      { name: "makerFee", type: "FeeRate" },
      { name: "salt", type: "uint256" },
    ],
    FeeRate: [
      { name: "recipient", type: "address" },
      { name: "rate", type: "uint16" },
    ],
    // 기타 필요한 구조체 타입을 여기 추가합니다.
  },
  primaryType: "Order",
  domain: {
    name: "Wen Exchange",
    version: "1",
    chainId: 1,
    verifyingContract: "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC",
  },
  message: {
    trader: "0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826",
    collection: "0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826",
    listingsRoot:
      "0xbb0a0ffa60a3c7bac37c1a23f6023e5702824a3f76e803295421ee48014a7651", // bytes32 형식의 해시 값
    numberOfListings: 2, // 이 예시에서는 5개의 리스팅이 있다고 가정
    expirationTime: 1908018751, // 유닉스 타임스탬프 형식의 만료 시간
    assetType: 0, // ERC721을 나타내는 0
    makerFee: {
      recipient: "1708018751",
      rate: 50, // 예를 들어, 수수료율이 5%라면 500
    },
    salt: "243042865251503736682743067031439481707", // 랜덤 솔트 값
  },
};

const types = typedData.types;

// Recursively finds all the dependencies of a type
function dependencies(primaryType, found = []) {
  if (found.includes(primaryType)) {
    return found;
  }
  if (types[primaryType] === undefined) {
    return found;
  }
  found.push(primaryType);
  for (let field of types[primaryType]) {
    for (let dep of dependencies(field.type, found)) {
      if (!found.includes(dep)) {
        found.push(dep);
      }
    }
  }
  return found;
}

function encodeType(primaryType) {
  // Get dependencies primary first, then alphabetical
  let deps = dependencies(primaryType);
  deps = deps.filter((t) => t != primaryType);
  deps = [primaryType].concat(deps.sort());

  // Format as a string with fields
  let result = "";
  for (let type of deps) {
    result += `${type}(${types[type]
      .map(({ name, type }) => `${type} ${name}`)
      .join(",")})`;
  }
  return result;
}

function typeHash(primaryType) {
  return ethUtil.keccakFromString(encodeType(primaryType), 256);
}

function encodeData(primaryType, data) {
  let encTypes = [];
  let encValues = [];

  // Add typehash
  encTypes.push("bytes32");
  encValues.push(typeHash(primaryType));

  // Add field contents
  for (let field of types[primaryType]) {
    let value = data[field.name];
    if (field.type == "string" || field.type == "bytes") {
      encTypes.push("bytes32");
      value = ethUtil.keccakFromString(value, 256);
      encValues.push(value);
    } else if (types[field.type] !== undefined) {
      encTypes.push("bytes32");
      value = ethUtil.keccak256(encodeData(field.type, value));
      encValues.push(value);
    } else if (field.type.lastIndexOf("]") === field.type.length - 1) {
      let baseType = field.type.slice(0, -2); // Remove the "[]" from type
      encTypes.push("bytes32");

      let arrayValues = value.map(
        (item) =>
          types[baseType] !== undefined
            ? ethUtil.keccak256(encodeData(baseType, item)) // If it's a struct array
            : item // If it's a value type array
      );

      // Concatenate all encoded array values then hash
      let concatenatedArrayValues = Buffer.concat(arrayValues);
      let arrayHash = ethUtil.keccak256(concatenatedArrayValues);

      encValues.push(arrayHash);
    } else {
      encTypes.push(field.type);
      encValues.push(value);
    }
  }

  return abi.rawEncode(encTypes, encValues);
}

function structHash(primaryType, data) {
  return ethUtil.keccak256(encodeData(primaryType, data));
}

function signHash() {
  return ethUtil.keccak256(
    Buffer.concat([
      //\x19\x01
      Buffer.from("1901", "hex"),
      //DomainSeparator
      structHash("EIP712Domain", typedData.domain),
      //structHash(Mail)
      structHash(typedData.primaryType, typedData.message),
    ])
  );
}

function signHashAgainWithBlockNumber() {
  const hashBuffer = signHash();

  // blockNum을 숫자로 변환합니다. 이미 문자열로 되어있으므로 parseInt를 사용합니다.
  // 그리고 그 결과를 Buffer로 변환합니다. blockNum은 uint32 형식이므로 4바이트 필요합니다.
  const blockNumberBuffer = Buffer.allocUnsafe(4); // 4바이트 버퍼 생성
  blockNumberBuffer.writeUInt32BE(parseInt(blockNum)); // Big Endian 형식으로 숫자를 버퍼에 쓰기

  // 두 버퍼(hashBuffer와 blockNumberBuffer)를 연결합니다.
  const combinedBuffer = Buffer.concat([hashBuffer, blockNumberBuffer]);

  // 연결된 버퍼를 keccak256 해시 함수에 전달하여 최종 해시를 계산합니다.
  return ethUtil.keccak256(combinedBuffer);
}

function encodePacked(params = []) {
  let types = [];
  let values = [];

  params.forEach((itemArray) => {
    types.push(itemArray[0]);
    values.push(itemArray[1]);
  });

  return ethers.solidityPacked(types, values);
}

function encodeOracleSignature(r, s, v, blockNumber, oracle) {
  const vBuffer = Buffer.alloc(1);
  vBuffer.writeUInt8(v);

  // blockNumber를 4바이트 버퍼로 변환
  const blockNumberBuffer = Buffer.alloc(4);
  blockNumberBuffer.writeUInt32BE(parseInt(blockNumber, 10));

  // 모든 버퍼를 연결
  const signatureBuffer = encodePacked([
    ["bytes32", r],
    ["bytes32", s],
    ["uint8", v],
    ["uint32", blockNumberBuffer],
    ["bytes20", oracle],
  ]);

  // 연결된 버퍼를 16진수 문자열로 변환
  return signatureBuffer;
}

// console.log(
//   "DomainSeparator: 0x" +
//     structHash("EIP712Domain", typedData.domain).toString("hex")
// );
// console.log(
//   "HashStruct: 0x" +
//     structHash(typedData.primaryType, typedData.message).toString("hex")
// );

// console.log(
//     "sign hash w blockNum: ",
//     signHashAgainWithBlockNumber().toString("hex")
//   );

const main = async () => {
  //   blockNum = await getBlock();
  blockNum = "23";

  console.log("Block number set in main function: ", blockNum);

  console.log(typedData.message);

  const privateKey = ethUtil.keccakFromString("cow", 256);
  const address = ethUtil.privateToAddress(privateKey);
  console.log("signer: 0x" + address.toString("hex"));

  const sig = ethUtil.ecsign(signHashAgainWithBlockNumber(), privateKey);
  console.log("1. (HASH) original sign hash: ", signHash().toString("hex"));
  console.log(
    "2. (SIG) Signature with BlockNumber: ",
    signHash().toString("hex")
  );

  console.log("  2-1. sig.v:" + sig.v);
  console.log("  2-2. sig.r: 0x" + sig.r.toString("hex"));
  console.log("  2-3. sig.s: 0x" + sig.s.toString("hex"));
  console.log(
    "3. Original Signature: ",
    encodePacked([
      ["bytes32", sig.r],
      ["bytes32", sig.s],
      ["uint8", sig.v],
    ])
  );

  const vBuffer = Buffer.alloc(1);
  vBuffer.writeUInt8(sig.v);

  // blockNumber를 4바이트 버퍼로 변환
  const blockNumberBuffer = Buffer.alloc(4);
  blockNumberBuffer.writeUInt32BE(blockNum);

  // 모든 버퍼를 연결
  const signatureBuffer = encodePacked([
    ["bytes32", sig.r],
    ["bytes32", sig.s],
    ["uint8", sig.v],
    ["uint32", blockNum],
    ["bytes20", address],
  ]);

  // 연결된 버퍼를 16진수 문자열로 변환

  console.log(
    "4. Oracle Signature (Original Signature + blockNumber): ",
    signatureBuffer.toString()
  );

  // 여기에서 blockNum을 사용하여 다른 함수들을 호출할 수 있습니다.
  // 예: await someOtherFunction(blockNum);
};

main().catch((error) => {
  console.error("An error occurred in the main function:", error);
});
