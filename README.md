# ArtBlocks: Collaborative NFT Platform on Stacks Blockchain

## Overview

ArtBlocks is a Clarity smart contract that enables collaborative NFT creation on the Stacks blockchain. The platform allows multiple artists to contribute to a single digital artwork with transparent royalty management.

## Key Features

- **Collaborative Artwork Creation**
  - Support for up to 5 artists per NFT
  - Precise contribution tracking
  - Flexible royalty percentage allocation

- **Secure Royalty Distribution**
  - On-chain royalty tracking
  - Automatic percentage-based splits
  - Individual artist royalty withdrawal

## Contract Functions

### Create Collaborative Artwork
```clarity
(create-collaborative-artwork 
  (artists (list 5 principal))
  (royalty-percentages (list 5 uint))
  (contribution-descriptions (list 5 (string-utf8 100)))
)
```
- Creates a unique NFT
- Validates total royalty percentage
- Stores artist contributions

### Distribute Royalties
```clarity
(distribute-royalties 
  (token-id (buff 32))
  (sale-price uint)
)
```
- Calculates and distributes royalties
- Transfers STX to contributing artists

### Withdraw Royalties
```clarity
(withdraw-royalties)
```
- Allows artists to claim accumulated royalties

## Error Handling

- `err-not-owner`: Unauthorized royalty distribution
- `err-invalid-royalties`: Incorrect royalty percentage
- `err-token-exists`: Preventing duplicate tokens

## Security Considerations

- Input validation for artist contributions
- Percentage-based royalty calculation
- Secure STX transfers
- Prevention of duplicate token minting

## Requirements

- Stacks Blockchain
- Hiro Wallet or Compatible Stacks Wallet
- Clarity Smart Contract Support

## Deployment

1. Compile the Clarity contract
2. Deploy using Stacks Web Wallet or CLI
3. Interact via Stacks-compatible interfaces

## Future Roadmap

- Enhanced metadata storage
- Cross-platform NFT integration
- Gas optimization
- Advanced collaboration tools

