<p align="center">
  <a href="https://codesandbox.io">
    <img src="https://i.ibb.co/xLNBqMw/Group-39489.png" height="170px">
  </a>
</p>

&nbsp;

## Core Contract Details

- ### [Wen Trade Pool V1](https://github.com/WenExchange/wen-contracts/tree/main/contracts/WenCore/WenTradePool)

- ### [Wen Gas Station V1](https://github.com/WenExchange/wen-contracts/tree/main/contracts/WenCore/WenGasStation)

- ### [Wen Staking V1](https://github.com/WenExchange/wen-contracts/tree/main/contracts/WenCore/WenStaking)

## Other Wen Exchnage repositories

Wen Exchange consists of several code base, some of which are open
sourced.

- [Wen Bot](https://github.com/WenExchange/wen-bot): Wen Exchange Bot that harvest Blast native Yields.
- [Wen Interface](https://github.com/WenExchange/wen-interface): Interface of Wen
- Wen Builder Tool: To be public soon.

## Documentation

You can find our documentation on our
[docs](https://docs.wen.exchange)

## If you want to test contracts

1. Install dependencies

<code> npm i</code>

2. Change sample.hardhat.config.js file to hadhat.config.js

Change [YOUR_PRIVATE_KEY] section to your private key.

3. Compile Smart Contracts

<code>npx hardhat compile</code>

4. Deploy Smart contracts on blast testnet.

You Should have testnet ETH on your account to deploy on the testnet.

<code>npx hardhat run --network blast_sepolia migrations/DeployMarketplace.js
</code>

## Thanks

Thanks to [Blast](https://blast.io/en) for providing the infrastructure for innovation.
