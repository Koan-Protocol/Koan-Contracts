# KoanProtocol DEX

Welcome to **KoanProtocol** — a next-generation DEX built on Uniswap V3's concentrated liquidity model. KoanProtocol enables efficient swaps, custom liquidity positions, and advanced DeFi strategies.

## ✨ What is KoanProtocol?

A Uniswap V3-style DEX with:

- **Concentrated Liquidity**: LPs choose price ranges for capital efficiency.
- **Composable Core & Periphery**: Modular contracts for flexibility and security.
- **Advanced Swaps**: Low slippage, high capital efficiency.

---

## 🗂️ Folder Structure

```
Koan-Contracts-V1/
│
├── amm-v3-core/         # Core protocol contracts (pools, factory, logic)
│   └── contracts/
│       ├── UniswapV3Factory.sol
│       ├── UniswapV3Pool.sol
│       └── ...
│
├── amm-v3-periphery/    # Periphery contracts (user-facing, helpers)
│   └── contracts/
│       ├── NonfungiblePositionManager.sol
│       ├── SwapRouter.sol
│       ├── lens/
│       │   ├── Quoter.sol
│       │   └── QuoterV2.sol
│       └── ...
│
└── ...
```

---

## 🧩 Core Contracts (`amm-v3-core`)

- **UniswapV3Factory.sol**: Deploys and tracks all pools.
- **UniswapV3Pool.sol**: The heart of the DEX — manages swaps, liquidity, and fees.
- **Libraries & Interfaces**: Math, callbacks, and pool logic.

## 🛠️ Periphery Contracts (`amm-v3-periphery`)

- **NonfungiblePositionManager.sol**: Mint, manage, and burn LP NFT positions.
- **SwapRouter.sol**: Route and execute token swaps.
- **Quoter.sol / QuoterV2.sol**: Get swap quotes off-chain.
- **Other Helpers**: Liquidity management, multicall, self-permit, etc.

---

## 🚀 Quick Start

1. Clone the repo
2. Install dependencies in each package
3. Deploy core, then periphery contracts

---

## 📚 Learn More

- Inspired by [Uniswap V3](https://uniswap.org/whitepaper-v3.pdf)
- Modular, gas-optimized, and open for innovation

---

_Build, swap, and LP with precision — the Koan way._
