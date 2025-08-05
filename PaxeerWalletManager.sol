// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title PaxeerWalletManager
 * @dev Manages wallet sessions and auto-connect functionality for Paxeer ecosystem
 */
contract PaxeerWalletManager is ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    constructor() Ownable(msg.sender) {}

    struct WalletSession {
        address wallet;
        uint256 sessionId;
        uint256 expiryTime;
        bool isActive;
        string[] connectedDapps;
        mapping(string => bool) dappAccess;
    }

    struct DappInfo {
        string name;
        string domain;
        address owner;
        bool isVerified;
        bool isActive;
    }

    // Events
    event SessionCreated(address indexed wallet, uint256 indexed sessionId, uint256 expiryTime);
    event DappConnected(address indexed wallet, string indexed dappId, uint256 sessionId);
    event DappRegistered(string indexed dappId, address indexed owner, string domain);
    event SessionExtended(address indexed wallet, uint256 sessionId, uint256 newExpiry);
    event WalletDisconnected(address indexed wallet, uint256 sessionId);

    // State variables
    mapping(address => WalletSession) public walletSessions;
    mapping(string => DappInfo) public registeredDapps;
    mapping(address => uint256) public walletNonces;
    
    uint256 public defaultSessionDuration = 24 hours;
    uint256 public maxSessionDuration = 7 days;
    uint256 private _sessionCounter;

    modifier validSession(address wallet) {
        require(
            walletSessions[wallet].isActive && 
            walletSessions[wallet].expiryTime > block.timestamp,
            "Invalid or expired session"
        );
        _;
    }

    modifier onlyVerifiedDapp(string memory dappId) {
        require(registeredDapps[dappId].isVerified, "Dapp not verified");
        require(registeredDapps[dappId].isActive, "Dapp not active");
        _;
    }

    /**
     * @dev Register a new dApp in the ecosystem
     */
    function registerDapp(
        string memory dappId,
        string memory name,
        string memory domain,
        address dappOwner
    ) external onlyOwner {
        require(bytes(dappId).length > 0, "Invalid dApp ID");
        require(!registeredDapps[dappId].isActive, "Dapp already registered");

        registeredDapps[dappId] = DappInfo({
            name: name,
            domain: domain,
            owner: dappOwner,
            isVerified: true,
            isActive: true
        });

        emit DappRegistered(dappId, dappOwner, domain);
    }

    /**
     * @dev Create a new wallet session
     */
    function createSession(
        uint256 duration,
        bytes memory signature
    ) external nonReentrant {
        require(duration <= maxSessionDuration, "Duration too long");
        
        uint256 sessionDuration = duration > 0 ? duration : defaultSessionDuration;
        uint256 expiryTime = block.timestamp + sessionDuration;
        
        // Verify signature to ensure wallet ownership
        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,
            walletNonces[msg.sender],
            expiryTime,
            block.chainid
        ));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        address signer = ethSignedMessageHash.recover(signature);
        require(signer == msg.sender, "Invalid signature");

        // Increment nonce to prevent replay attacks
        walletNonces[msg.sender]++;
        _sessionCounter++;

        // Create or update session
        WalletSession storage session = walletSessions[msg.sender];
        session.wallet = msg.sender;
        session.sessionId = _sessionCounter;
        session.expiryTime = expiryTime;
        session.isActive = true;
        
        // Clear previous dApp connections
        for (uint i = 0; i < session.connectedDapps.length; i++) {
            session.dappAccess[session.connectedDapps[i]] = false;
        }
        delete session.connectedDapps;

        emit SessionCreated(msg.sender, _sessionCounter, expiryTime);
    }

    /**
     * @dev Connect wallet to a dApp (auto-connect if session exists)
     */
    function connectToDapp(
        string memory dappId,
        address wallet
    ) external validSession(wallet) onlyVerifiedDapp(dappId) returns (bool) {
        WalletSession storage session = walletSessions[wallet];
        
        if (!session.dappAccess[dappId]) {
            session.dappAccess[dappId] = true;
            session.connectedDapps.push(dappId);
        }

        emit DappConnected(wallet, dappId, session.sessionId);
        return true;
    }

    /**
     * @dev Check if wallet can auto-connect to dApp
     */
    function canAutoConnect(
        address wallet,
        string memory dappId
    ) external view returns (bool) {
        WalletSession storage session = walletSessions[wallet];
        
        return session.isActive &&
               session.expiryTime > block.timestamp &&
               registeredDapps[dappId].isVerified &&
               registeredDapps[dappId].isActive;
    }

    /**
     * @dev Get wallet session info
     */
    function getSessionInfo(address wallet) external view returns (
        uint256 sessionId,
        uint256 expiryTime,
        bool isActive,
        string[] memory connectedDapps
    ) {
        WalletSession storage session = walletSessions[wallet];
        return (
            session.sessionId,
            session.expiryTime,
            session.isActive && session.expiryTime > block.timestamp,
            session.connectedDapps
        );
    }

    /**
     * @dev Extend session duration
     */
    function extendSession(
        uint256 additionalDuration
    ) external validSession(msg.sender) {
        require(additionalDuration > 0, "Invalid duration");
        
        WalletSession storage session = walletSessions[msg.sender];
        uint256 newExpiry = session.expiryTime + additionalDuration;
        require(newExpiry <= block.timestamp + maxSessionDuration, "Extension too long");
        
        session.expiryTime = newExpiry;
        emit SessionExtended(msg.sender, session.sessionId, newExpiry);
    }

    /**
     * @dev Disconnect wallet and end session
     */
    function disconnectWallet() external {
        WalletSession storage session = walletSessions[msg.sender];
        require(session.isActive, "No active session");
        
        session.isActive = false;
        emit WalletDisconnected(msg.sender, session.sessionId);
    }

    /**
     * @dev Execute transaction on behalf of connected wallet (for sponsored transactions)
     */
    function executeTransaction(
        address target,
        bytes calldata data,
        string memory dappId
    ) external validSession(msg.sender) onlyVerifiedDapp(dappId) returns (bool success, bytes memory result) {
        require(walletSessions[msg.sender].dappAccess[dappId], "Dapp not connected");
        
        (success, result) = target.call(data);
        require(success, "Transaction failed");
    }

    /**
     * @dev Admin functions
     */
    function setSessionDuration(uint256 duration) external onlyOwner {
        require(duration <= maxSessionDuration, "Duration too long");
        defaultSessionDuration = duration;
    }

    function setMaxSessionDuration(uint256 duration) external onlyOwner {
        maxSessionDuration = duration;
    }

    function deactivateDapp(string memory dappId) external onlyOwner {
        registeredDapps[dappId].isActive = false;
    }

    function reactivateDapp(string memory dappId) external onlyOwner {
        registeredDapps[dappId].isActive = true;
    }
}
