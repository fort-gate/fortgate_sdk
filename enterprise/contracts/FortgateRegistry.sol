// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FortgateRegistry
 * @author Fortgate Engineering
 * @notice Gestiona el Registro Global de Identidades (Nullifiers) y Alertas de Fraude.
 * @dev Optimizado para Monad: Minimiza escrituras en storage y usa eventos para indexación.
 */
contract FortgateRegistry {
    
    enum IdentityStatus { Unseen, Verified, Revoked, Fraud }

    struct IdentityRecord {
        IdentityStatus status;
        uint64 timestamp;
        address reporter; 
    }

    mapping(bytes32 => IdentityRecord) public registry;
    mapping(address => bool) public authorizedInstitutions;
    address public immutable owner;

    event IdentityRegistered(bytes32 indexed nullifier, address indexed institution);
    event FraudFlagged(bytes32 indexed nullifier, address indexed reporter);
    event IdentityRevoked(bytes32 indexed nullifier, address indexed reporter);

    modifier onlyAuthorized() {
        require(authorizedInstitutions[msg.sender], "Fortgate: Not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Fortgate: Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedInstitutions[msg.sender] = true;
    }

    function authorizeInstitution(address _institution) external onlyOwner {
        authorizedInstitutions[_institution] = true;
    }

    function registerIdentity(bytes32 _nullifier) external onlyAuthorized {
        require(registry[_nullifier].status == IdentityStatus.Unseen, "Fortgate: Already registered");
        registry[_nullifier] = IdentityRecord({
            status: IdentityStatus.Verified,
            timestamp: uint64(block.timestamp),
            reporter: msg.sender
        });
        emit IdentityRegistered(_nullifier, msg.sender);
    }

    function flagFraud(bytes32 _nullifier) external onlyAuthorized {
        registry[_nullifier].status = IdentityStatus.Fraud;
        registry[_nullifier].reporter = msg.sender;
        registry[_nullifier].timestamp = uint64(block.timestamp);
        emit FraudFlagged(_nullifier, msg.sender);
    }

    function checkIdentity(bytes32 _nullifier) external view returns (IdentityStatus, uint64) {
        IdentityRecord memory record = registry[_nullifier];
        return (record.status, record.timestamp);
    }
}
