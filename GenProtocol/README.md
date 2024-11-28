# Personalized Treatment Protocol Management Smart Contract

## Overview
This smart contract implements a decentralized system for managing personalized medical treatment protocols based on genetic markers. It enables medical professionals to create, verify, and manage treatment protocols while tracking patient outcomes and treatment effectiveness.

## Key Features
- Protocol creation and management with multi-signature verification
- Patient treatment tracking with historical records
- Automated effectiveness scoring system
- Protocol versioning and updates
- Medical professional registration and authorization
- Comprehensive event logging
- Privacy-focused data management

## Contract Structure

### Constants
- `CONTRACT_OWNER`: Initial contract deployer
- `MAX_VERIFIERS`: Maximum number of medical professionals that can verify a protocol (5)
- `MIN_SCORE` and `MAX_SCORE`: Bounds for outcome scoring (0-100)

### Data Maps
1. `medical-professionals`
   - Tracks registered medical professionals
   - Stores specialty and verification activity
   - Manages authorization status

2. `treatment-protocols`
   - Stores protocol details and metadata
   - Tracks effectiveness scores
   - Manages verification status
   - Records protocol versions

3. `patient-treatments`
   - Maintains patient treatment history
   - Tracks current protocol assignments
   - Stores outcome scores
   - Links genetic markers

4. `protocol-versions`
   - Manages protocol version history
   - Tracks current version numbers
   - Maintains upgrade paths

## Core Functions

### Administrative Functions
```clarity
(register-medical-professional (practitioner principal) (specialty (string-utf8 64)))
```
- Registers new medical professionals
- Only callable by contract administrator
- Records specialty and sets initial verification count

### Protocol Management
```clarity
(create-protocol (genetic-marker (string-utf8 32)) (treatment-details (string-utf8 256)))
```
- Creates new treatment protocols
- Requires medical professional authorization
- Initializes effectiveness tracking

```clarity
(verify-protocol (protocol-id uint))
```
- Enables protocol verification by medical professionals
- Prevents duplicate verifications
- Updates protocol status

### Treatment Management
```clarity
(start-treatment (patient principal) (protocol-id uint) (genetic-marker (string-utf8 32)))
```
- Initiates patient treatment
- Requires verified protocol
- Updates patient history

```clarity
(record-treatment-outcome (patient principal) (protocol-id uint) (outcome-score uint))
```
- Records treatment outcomes
- Updates effectiveness scores
- Maintains treatment history

### Version Control
```clarity
(create-protocol-version (base-protocol-id uint) (treatment-details (string-utf8 256)))
```
- Creates new protocol versions
- Maintains version history
- Preserves relationship with base protocol

## Error Codes
- `ERR_NOT_AUTHORIZED (u100)`: Unauthorized access attempt
- `ERR_NOT_FOUND (u101)`: Requested data not found
- `ERR_INVALID_SCORE (u102)`: Score outside valid range
- `ERR_ALREADY_VERIFIED (u103)`: Duplicate verification attempt

## Security Considerations

### Access Control
- Only registered medical professionals can create/verify protocols
- Multi-signature verification requirement
- Administrator-only professional registration

### Data Integrity
- Input validation for all function calls
- Immutable treatment history
- Version control for protocol updates

### Privacy
- Patient data stored using principal addresses
- Limited access to sensitive information
- Event logging with minimal personal data

## Usage Examples

### Registering a Medical Professional
```clarity
(contract-call? .treatment-protocol register-medical-professional 
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
    "Oncology")
```

### Creating a Protocol
```clarity
(contract-call? .treatment-protocol create-protocol 
    "BRCA1-positive" 
    "Combined PARP inhibitor therapy with...")
```

### Starting Treatment
```clarity
(contract-call? .treatment-protocol start-treatment
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
    u1
    "BRCA1-positive")
```

## Events
The contract emits events for:
- Protocol creation and updates
- Treatment initiation
- Outcome recording
- Version changes
- Professional registration

## Integration Guidelines

### Prerequisites
- Clarity-compatible blockchain environment
- Medical professional registration system
- Patient data management system

### Deployment Steps
1. Deploy contract
2. Register initial administrator
3. Register medical professionals
4. Create initial protocols
5. Implement verification process

### Best Practices
- Always verify protocols before patient assignment
- Regularly update effectiveness scores
- Maintain detailed treatment records
- Follow versioning protocols for updates

## Testing
Recommended test scenarios:
1. Professional registration flow
2. Protocol creation and verification
3. Treatment initiation and tracking
4. Outcome recording and scoring
5. Version management
6. Error handling and access control

## Limitations and Considerations
- Maximum 5 verifiers per protocol
- Treatment history limited to 20 entries
- Protocol versions limited to 10 per base protocol
- String length limitations for markers and details

## Future Enhancements
- Enhanced privacy features
- Extended outcome metrics
- Advanced protocol matching
- Automated effectiveness analysis
- Cross-protocol comparison tools