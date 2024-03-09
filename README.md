# Smol AA [![Github Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gha]: https://github.com/0xClandestine/smol-aa/actions
[gha-badge]: https://github.com/0xClandestine/smol-aa/actions/workflows/test.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/license/unlicense
[license-badge]: https://img.shields.io/badge/License-Unlicense-blue.svg

Smol AA is a minimal viable smart account designed to offer versatile functionality including:

1. **Arbitrary and Mutable Ownership**: Provides flexibility in ownership management, allowing for changes as needed.

2. **Arbitrary Calls/Delegatecalls**: Supports executing arbitrary calls and delegatecalls, enabling similar functionalities akin to [EIP-3074](https://eips.ethereum.org/EIPS/eip-3074).
## Usage

For guidance, refer to the [Foundry Documentation](https://book.getfoundry.sh/).

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Lint

```shell
forge fmt
```

### Deploy

```shell
source .env
forge script DeploySocialRecovery --rpc-url $RPC_URL --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_KEY
```

### License

[The Unlicense](./LICENSE)