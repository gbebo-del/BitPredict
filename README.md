# BitPredict - Decentralized Bitcoin Price Prediction Markets

## Overview

BitPredict is a Clarity smart contract enabling trustless BTC/USD price speculation markets on Stacks L2. The protocol combines Bitcoin settlement security with Layer 2 scalability, featuring automated market resolution and anti-manipulation mechanisms through Bitcoin-finalized blocks.

## Key Features

- **Bitcoin-Native Settlement**: Direct price speculation anchored to BTC value
- **Enterprise-Grade Throughput**: Optimized for high-frequency trading via Stacks L2
- **Dynamic Reward Engine**: Automated profit distribution with protocol fee capture
- **Oracle-Protected Markets**: Price resolution through authorized oracle nodes
- **Capital Efficiency**: Pooled liquidity model with minimized slippage

## Contract Architecture

### Core Components

1. **Market Structure**

```clarity
{
    opening-price: uint,      // Initial BTC price in satoshis
    closing-price: uint,      // Final resolved BTC price
    bull-commitment: uint,    // Total long positions (STX)
    bear-commitment: uint,    // Total short positions (STX)
    activation-block: uint,   // Market start height
    expiration-block: uint,   // Market end height
    resolution-status: bool   // Settlement status
}
```

2. **Position Management**

```clarity
{
    direction: "bull"|"bear", // Market position direction
    amount: uint,             // STX committed
    claimed: bool             // Reward claim status
}
```

## Core Functions

### 1. Market Creation (`create-market`)

- **Purpose**: Initialize new prediction market
- **Parameters**:
  - `opening-price`: Initial BTC/USD price (sats)
  - `activation-block`: Market start block
  - `expiration-block`: Market end block

```bash
clarinet console> (contract-call? .bitpredict create-market u65000 u15000 u18000)
```

### 2. Position Taking (`take-position`)

- **Requirements**:
  - Minimum stake: Configurable (default 1 STX)
  - Active market window
- **Directions**: "bull" (long) or "bear" (short)

```bash
clarinet console> (contract-call? .bitpredict take-position u0 "bull" u1000000)
```

### 3. Market Resolution (`settle-market`)

- **Oracle Requirements**:
  - Called by authorized oracle address
  - After expiration block
- **Sets**: Final closing price and resolution status

```bash
clarinet console> (contract-call? .bitpredict settle-market u0 u68000)
```

### 4. Reward Claiming (`claim-rewards`)

- **Calculation**:
  ```
  gross_reward = (position_amount / winning_pool) * total_commitment
  protocol_fee = gross_reward * 2%
  net_payout = gross_reward - protocol_fee
  ```

```bash
clarinet console> (contract-call? .bitpredict claim-rewards u0)
```

## Administrative Functions

### 1. Oracle Management (`update-oracle`)

```bash
clarinet console> (contract-call? .bitpredict update-oracle 'STNEWORACLE)
```

### 2. Stake Configuration (`adjust-stake`)

```bash
clarinet console> (contract-call? .bitpredict adjust-stake u500000)
```

## Query Interface

### 1. Market Data Retrieval

```bash
clarinet console> (contract-call? .bitpredict get-market-data u0)
```

### 2. Position Status Check

```bash
clarinet console> (contract-call? .bitpredict get-user-position u0 'STUSER)
```

## Error Codes

| Code | Description                  |
| ---- | ---------------------------- |
| 100  | Owner-only function          |
| 101  | Invalid parameter            |
| 102  | Resource not found           |
| 103  | Market inactive/closed       |
| 104  | Invalid prediction direction |
| 105  | Insufficient balance         |
| 106  | Rewards already claimed      |

## Security Model

1. **Oracle Protection**

   - Market resolution restricted to pre-authorized oracle
   - Final settlement price immutable once set

2. **Capital Safeguards**

   - Funds held in contract escrow until resolution
   - STX transfers via Clarity's built-in security

3. **Temporal Controls**
   - Block-height based market windows
   - No late positions accepted
