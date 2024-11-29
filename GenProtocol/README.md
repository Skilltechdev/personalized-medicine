# Simplified Treatment Protocol Management Smart Contract

This smart contract is designed for the management of personalized treatment protocols in a healthcare setting. It facilitates the registration of medical professionals, creation and management of treatment protocols, and tracking of patient treatments and outcomes. The contract aims to simplify the process of managing medical treatments by ensuring that protocols are verified, treatments are tracked, and medical professionals can record treatment outcomes efficiently.

This smart contract allows the following functionalities:
- **Registering medical professionals**: Only authorized individuals can register medical professionals.
- **Creating treatment protocols**: Medical professionals can create new treatment protocols and link them to genetic markers and treatment details.
- **Verifying protocols**: A protocol must be verified before it can be used to treat patients.
- **Starting treatments**: Medical professionals can start treatment for a patient, linking the treatment to a protocol.
- **Recording treatment outcomes**: Medical professionals can record the outcome of a treatment and update the protocol’s effectiveness score.
- **Tracking patient treatments**: The contract tracks the protocols a patient has been assigned to and the status of their treatment.
- **Read-only access**: Anyone can query the details of treatment protocols and a patient’s treatment history.

## Constants

The contract uses the following constants:

- `CONTRACT_OWNER`: The owner of the contract (set to the sender of the transaction).
- `ERR_NOT_AUTHORIZED`: Error code `u100`, triggered when an unauthorized user attempts to perform an action.
- `ERR_NOT_FOUND`: Error code `u101`, triggered when a requested protocol or treatment record is not found.
- `ERR_INVALID_SCORE`: Error code `u102`, triggered when an invalid treatment outcome score is provided.
- `ERR_INVALID_INPUT`: Error code `u103`, triggered when an invalid input is provided.
- `MAX_SCORE`: The maximum valid treatment outcome score (`u100`).

## Data Variables

These are the primary variables used to store the contract's data:

- `protocol-counter`: A counter that increments with each new treatment protocol created.
- `admin`: The principal of the contract owner, responsible for administrative actions.

## Data Maps

The contract uses the following data maps to store information:

- **`medical-professionals`**: A map that associates a principal (medical professional) with their status (`is-active`) and specialty.
  - Key: `principal`
  - Value: `{ is-active: bool, specialty: string-utf8 64 }`
  
- **`treatment-protocols`**: A map that stores the details of each treatment protocol, including genetic markers, treatment details, the creator, effectiveness score, total patients, and status.
  - Key: `{ protocol-id: uint }`
  - Value: `{ genetic-marker: string-utf8 32, treatment-details: string-utf8 256, creator: principal, effectiveness-score: uint, total-patients: uint, status: string-utf8 16 }`

- **`patient-treatments`**: A map that stores the current treatment protocol for each patient, including the protocol ID, treatment start block, and genetic marker.
  - Key: `{ patient: principal }`
  - Value: `{ current-protocol: uint, treatment-start: uint, genetic-marker: string-utf8 32 }`

## Functions

### Helper Functions

- **`validate-string-length`**: Validates that a given string input does not exceed a specified maximum length.
    - Parameters: 
      - `input`: The string to validate.
      - `max-len`: The maximum length allowed.
    - Returns: Boolean indicating if the string length is valid.

- **`is-medical-professional`**: Checks whether a given principal is a registered medical professional.
    - Parameters: 
      - `practitioner`: The principal to check.
    - Returns: Boolean indicating if the principal is a medical professional.

### Administrative Functions

- **`register-medical-professional`**: Registers a new medical professional by storing their active status and specialty.
    - Parameters: 
      - `practitioner`: The principal (medical professional) to register.
      - `specialty`: The medical professional's specialty (e.g., cardiology, dermatology).
    - Restrictions: Only the contract owner can call this function.
    - Returns: `true` on success, otherwise an error.

### Protocol Management Functions

- **`create-protocol`**: Creates a new treatment protocol, linking it to a genetic marker and treatment details.
    - Parameters: 
      - `genetic-marker`: The genetic marker that identifies the protocol.
      - `treatment-details`: A description of the treatment protocol.
    - Restrictions: Only registered medical professionals can create protocols.
    - Returns: The `protocol-id` of the newly created protocol.

- **`verify-protocol`**: Verifies an existing protocol, allowing it to be used in treatment.
    - Parameters:
      - `protocol-id`: The ID of the protocol to verify.
    - Restrictions: Only the creator of the protocol can verify it.
    - Returns: `true` on success, otherwise an error.

- **`start-treatment`**: Begins treatment for a patient using a specific protocol.
    - Parameters: 
      - `patient`: The principal (patient) to treat.
      - `protocol-id`: The ID of the protocol to use.
      - `genetic-marker`: The genetic marker to use for treatment.
    - Restrictions: The protocol must be verified before treatment can start.
    - Returns: `true` on success, otherwise an error.

- **`record-treatment-outcome`**: Records the outcome score of a treatment for a specific patient.
    - Parameters:
      - `patient`: The principal (patient) receiving treatment.
      - `protocol-id`: The ID of the protocol used.
      - `outcome-score`: The outcome score of the treatment (between 0 and 100).
    - Restrictions: Only medical professionals can record treatment outcomes.
    - Returns: `true` on success, otherwise an error.

### Read-Only Functions

- **`get-protocol-details`**: Retrieves the details of a specific treatment protocol.
    - Parameters: 
      - `protocol-id`: The ID of the protocol.
    - Returns: The details of the protocol or an error if not found.

- **`get-patient-history`**: Retrieves the treatment history of a specific patient.
    - Parameters: 
      - `patient`: The principal (patient) whose history is to be retrieved.
    - Returns: The patient's treatment history or an error if not found.

## Error Codes

- **`ERR_NOT_AUTHORIZED (u100)`**: Raised when an unauthorized principal attempts to perform an action.
- **`ERR_NOT_FOUND (u101)`**: Raised when a protocol or treatment record is not found.
- **`ERR_INVALID_SCORE (u102)`**: Raised when an invalid outcome score is provided for treatment (score must be between 0 and 100).
- **`ERR_INVALID_INPUT (u103)`**: Raised when invalid input is provided (e.g., incorrect string length or invalid parameters).

## Deployment and Usage

1. **Deploying the contract**: Deploy this contract on a compatible blockchain platform.
2. **Interacting with the contract**:
   - Use the appropriate functions to register medical professionals, create treatment protocols, start treatments, and record outcomes.
   - Ensure that only authorized medical professionals can perform certain actions, such as creating protocols or recording outcomes.
   - Query protocols and patient histories using the read-only functions.

This contract is designed to be a simple, secure, and efficient solution for managing personalized treatment protocols in a healthcare environment, ensuring that only authorized professionals can interact with treatment data.