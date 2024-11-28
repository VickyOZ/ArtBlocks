# Stacks Voting Contract

## Overview

This is a robust voting contract implemented in Clarity for the Stacks blockchain. The contract provides a flexible and secure mechanism for creating, managing, and participating in proposals with built-in governance features.

## Features

- **Proposal Creation**: Only contract owner can create proposals
- **Flexible Voting Duration**: Customizable voting periods
- **Vote Tracking**: Prevents multiple votes per user
- **Automatic Proposal Closure**: Proposals automatically close after specified duration
- **Detailed Proposal Metadata**: Tracks proposal creator, timestamp, and voting details

## Contract Functions

### Proposal Management

- `create-proposal`: Create a new proposal
  - Parameters: 
    - `title`: Proposal title (max 50 characters)
    - `description`: Proposal description (max 500 characters)
    - `custom-duration`: Optional custom voting duration

- `close-proposal`: Manually close a proposal (owner-only)
- `set-default-voting-duration`: Update default voting period (owner-only)

### Voting

- `vote`: Cast a vote on an active proposal
  - Prevents multiple votes
  - Tracks vote timestamp
  - Updates proposal vote count

### Read-Only Functions

- `get-proposal-details`: Retrieve comprehensive proposal information
- `get-proposal-count`: Get total number of proposals
- `has-voted`: Check if a user has voted on a specific proposal

## Error Handling

The contract includes several error constants for different scenarios:
- `ERR_NOT_AUTHORIZED`: Unauthorized access attempt
- `ERR_ALREADY_VOTED`: Attempt to vote multiple times
- `ERR_INVALID_PROPOSAL`: Invalid proposal ID
- `ERR_VOTING_CLOSED`: Voting period has ended
- `ERR_INVALID_INPUT`: Invalid input parameters

## Default Parameters

- Default Voting Duration: 7 days (604,800 seconds)
- Maximum Proposal Title Length: 50 characters
- Maximum Proposal Description Length: 500 characters

## Usage Example

```clarity
;; Create a proposal
(create-proposal 
  "Community Funding" 
  "Proposal to allocate funds for community projects"
  (some u604800) ;; Optional custom duration
)

;; Vote on a proposal
(vote u1) ;; Vote on proposal with ID 1

;; Get proposal details
(get-proposal-details u1)
```

## Security Considerations

- Only the contract owner can create proposals
- Prevents multiple votes from the same user
- Automatic proposal closure after voting period
- Input validation for proposal creation

## Installation

1. Ensure you have a Stacks-compatible wallet
2. Deploy the contract to the Stacks blockchain
3. Interact with the contract using a Stacks-compatible interface

## Contributing

Contributions are welcome! Please submit pull requests or open issues on the project repository.

