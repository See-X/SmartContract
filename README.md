# SeeX-EIP2535


## Background

The `SeeX-EIP2535` is an EIP-2535 base smart contract framework that currently includes `PMApp` and `TokenUnlockerApp` contracts.

The `PMApp` is an exchange protocol that facilitates atomic swaps between `Conditional ERC1155 NFT Token` assets and an ERC20 collateral asset.

It is intended to be used in a hybrid-decentralized exchange model wherein there is an operator that provides offchain matching services while settlement happens on-chain, non-custodially.

The `TokenUnlockerApp` is a contract that provide users to invest/refund, stake/unstake, vote for proposal for our `SeeX DAO`.

## Documentation

This project introduces the core smart contracts for the PMApp and TokenUnlocker applications, built on the EIP-2535 diamond standard. The contracts include:

1. Diamond proxy and facet infrastructure
2. Core functionality facets (AccessControl, ERC1155, EIP712, Pausable, etc.)
3. PMApp with order matching, market management, and admin features
4. TokenUnlockerApp with staking, voting, vault management, and token distribution

The implementation follows best practices for upgradeable contracts and includes comprehensive storage layouts, interfaces, and base contracts to support the diamond pattern. Key features include:

- Role-based access control
- EIP-712 signed messages
- Pausable functionality
- ERC1155 token standard support
- Custom token transfer quote management
- Diamond loupe and cut functionality

The contracts are designed to be modular, upgradeable, and gas-efficient while maintaining security through extensive use of modifiers, reentrancy guards, and delegate call protections.

## Audit

These contracts have been audited by QuillAudits and the report is available [here](https://www.quillaudits.com/leaderboard/SeeX).

## Deployments

### Avalanche Network C-Chain

| Contract          | Address                                                                           |
| ---------------- | --------------------------------------------------------------------------------- |
| TokenUnlockerApp | []()|
| SESToken         | []()|
