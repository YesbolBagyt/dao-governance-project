## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
## Token Distribution

Total Supply: **1,000,000 GTK**

- **Team (Vesting):** 40% = 400,000 GTK  
- **Treasury:** 30% = 300,000 GTK  
- **Community Airdrop:** 20% = 200,000 GTK  
- **Liquidity:** 10% = 100,000 GTK  

## Governance Execution Log

1. Deploy GovernanceToken.
2. Deploy TimelockController with 2-day delay.
3. Deploy MyGovernor with token and timelock.
4. Grant PROPOSER_ROLE to Governor.
5. Set executor role for Timelock.
6. Delegate voting power.
7. Create proposal.
8. Move blocks to voting start.
9. Cast vote.
10. Move blocks to voting end.
11. Queue proposal in Timelock.
12. Wait 2-day timelock delay.
13. Execute proposal.
14. Verify result.