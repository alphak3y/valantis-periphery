![Valantis](img/Valantis_Banner.png)

## Valantis Protocol: Periphery

This repo contains the periphery smart contracts required to interact with Valantis Universal and Sovereign Pools. Currently only contains `ValantisSwapRouter`.

`ValantisSwapRouter` supports:

- Swaps between any two tokens, as long as they are routed through Valantis [Universal Pools](https://github.com/ValantisLabs/valantis-core/blob/main/src/pools/UniversalPool.sol) or [Sovereign Pools](https://docs.valantis.xyz/sovereign-pool-subpages).
- Intent based swaps using [Permit2](https://github.com/Uniswap/permit2), allowing for fees to be charged at the source.
- Batched swaps.

## Documentation

https://docs.valantis.xyz/

## Usage

### Install

```shell
$ git clone git@github.com:ValantisLabs/valantis-periphery.git
```

```shell
$ forge install && yarn install
```

### Test

```shell
$ forge test
```
