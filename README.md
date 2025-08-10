# PaxeerWalletManager - SSO Wallet Management System

## 🔗 Overview

PaxeerWalletManager is a revolutionary Smart Single Sign-On (SSO) system for Web3, enabling users to connect once and access all ecosystem dApps without repeated authentication.

## 📍 Deployment

**Network**: Paxeer Network (Chain ID: 80000)  
**Contract Address**: `0x23eAcfad6C0208FB13203226162e05D85859Bc52`  
**Verification**: ✅ [View on Explorer](https://paxscan.paxeer.app/address/0x23eAcfad6C0208FB13203226162e05D85859Bc52)

## 🎯 Key Features

### Session-Based Authentication
- **Cryptographic Signatures**: Secure session creation with ECDSA verification
- **Time-Based Expiration**: Configurable session durations (default: 24 hours)
- **Auto-Refresh**: Seamless session renewal for active users

### Cross-dApp Navigation
- **One-Click Access**: Connect to any registered dApp without re-authentication
- **Session Persistence**: Maintain authentication state across browser sessions
- **Domain Validation**: Secure dApp registration with domain verification

### Security Controls
- **Signature Verification**: All session operations require cryptographic proof
- **Nonce Protection**: Prevents replay attacks with incrementing nonces
- **Owner Controls**: Administrative functions for dApp management

## 🔧 Main Functions

### User Functions
```solidity
function connectToDapp(string memory dappId, address wallet) external returns (bool)
```
Connect a wallet to a specific dApp with session creation.

```solidity
function refreshSession(string memory dappId) external returns (bool)
```
Extend the current session duration for continued access.

### Query Functions
```solidity
function canAutoConnect(address wallet, string memory dappId) external view returns (bool)
```
Check if a wallet can auto-connect to a dApp based on existing session.

```solidity
function getSessionInfo(address wallet) external view returns (uint256 sessionExpiry, uint256 nonce, bool isActive, string[] memory connectedDapps)
```
Retrieve comprehensive session information for a wallet.

### Admin Functions
```solidity
function registerDapp(string memory dappId, string memory name, string memory domain) external onlyOwner
```
Register a new dApp in the ecosystem.

## 📊 Events

```solidity
event WalletConnected(address indexed wallet, string dappId, uint256 sessionExpiry);
event SessionRefreshed(address indexed wallet, uint256 newExpiry);
event DappRegistered(string indexed dappId, string name, string domain);
```

## 🚀 Integration Example

```solidity
// Deploy with zero gas fees
constructor() Ownable(msg.sender) {}

// Connect to dApp
bool success = walletManager.connectToDapp("my-dapp-id", msg.sender);

// Check auto-connect capability
bool canAutoConnect = walletManager.canAutoConnect(userAddress, "my-dapp-id");
```

## 🛡️ Security Features

- **ReentrancyGuard**: Protection against reentrancy attacks
- **Ownable Pattern**: Secure administrative access control
- **Signature Verification**: ECDSA signature validation using OpenZeppelin
- **Input Validation**: Comprehensive parameter checking

## 🌟 Registered dApps

1. **Paxeer DEX** (`paxeer-dex`) - Token trading platform
2. **Paxeer Lending** (`paxeer-lending`) - DeFi lending protocol
3. **Paxeer NFTs** (`paxeer-nft`) - NFT marketplace
4. **Paxeer DAO** (`paxeer-dao`) - Governance platform
5. **Paxeer Bridge** (`paxeer-bridge`) - Cross-chain bridge
6. **Paxeer Ecosystem** (`paxeer-ecosystem`) - Main ecosystem hub

## 🔧 Development

### Prerequisites
- Solidity ^0.8.19
- OpenZeppelin Contracts
- Hardhat development environment

### Compilation
```bash
npx hardhat compile
```

### Testing
```bash
npx hardhat test test/PaxeerWalletManager.test.js
```

### Deployment
```bash
npx hardhat run scripts/deploy-wallet-only.js --network paxeer-network
```

## 📈 Gas Optimization

- **Sponsored Transactions**: All operations use `gasPrice: 0`
- **Efficient Storage**: Optimized struct packing and storage patterns
- **Batch Operations**: Support for multiple session operations

## 🤝 Contributing

This contract is part of the larger Paxeer Ecosystem. See the main repository for contribution guidelines.

## 📄 License

MIT License - See LICENSE file for details.

---

*Revolutionary SSO for Web3 - Built with ❤️ by the Paxeer Team*
