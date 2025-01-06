# Setting Up Validator

This document describes how to setup a validatory

## Intro

### What is a validator?

Native is based on CometBFT that relies on a set of validators to secure the network. The role of validators is to run a full node and participate in consensus by broadcasting votes that contain cryptographic signatures signed by the validator's private key. Validators commit new blocks in the blockchain and receive revenue in exchange for their work. Validators must also participate in governance by voting on proposals. Validators are weighted according to their total stake.

Native is secured by a Proof Of Stake consensus. In order for a validator to be active (participate in the network consensus and be applicable for validator rewards), validator needs to have sufficient amount of delegated tokens. The staked tokens can be self-delegated directly by the validator or delegated to the validator by other token holders. The active validator set is limited to an amount that changes over time.

Any user in the system can declare their intention to become a validator by sending a `create-validator` transaction to become validator candidates.

The weight (consensus voting power) of a validator determines whether they are an active validator.

### What is a delegator?

Delegators are ATOM holders who cannot, or do not want to, run a validator themselves. Token holders can delegate their tokens to a validator and obtain a part of their revenue in exchange. For details on how revenue is distributed, see ["What is the incentive to stake"](https://hub.cosmos.network/main/validators/validator-faq#what-is-the-incentive-to-stake) and ["What are validators commission"](https://hub.cosmos.network/main/validators/validator-faq#what-is-a-validator-commission).

Because delegators share revenue with their validators, they also share risks. If a validator misbehaves, each of their delegators are partially slashed in proportion to their delegated stake. This penalty is one of the reasons why delegators must perform due diligence on validators before delegating. Spreading their stake over multiple validators is another layer of protection.

Delegators play a critical role in the system, as they are responsible for choosing validators. Being a delegator is not a passive role. Delegators must actively monitor the actions of their validators and participate in governance.

## Becoming a Validator

Any participant in the network can signal that they want to become a validator by sending a `create-validator` transaction, where they must fill out the following parameters:

- Validator's `PubKey`: The private key associated with this Tendermint/CometBFT PubKey is used to sign prevotes and precommits.
- Validator's Address: Application level address that is used to publicly identify your validator. The private key associated with this address is used to delegate, unbond, claim rewards, and participate in governance.
- Validator's name (moniker)
- Validator's website (Optional)
- Validator's description (Optional)
- Initial commission rate: The commission rate on block rewards and fees charged to delegators.
- Maximum commission: The maximum commission rate that this validator can charge. This parameter is fixed and cannot be changed after the create-validator transaction is processed.
- Commission max change rate: The maximum daily increase of the validator commission. This parameter is fixed cannot be changed after the create-validator transaction is processed.

After a validator is created, token holders can delegate their tokens to them, effectively adding stake to the validator's pool. The total stake of an address is the combination of amount of tokens bonded by delegators and amount of tokens self-bonded by the validator.

From all validator candidates that signaled themselves, `N` (N is the limit specified by the chain consensus) validators with the most total stake are the designated validators. If a validator's total stake falls below the top `N`, then that validator loses its validator privileges. The validator cannot participate in consensus or generate rewards until the stake is high enough to be in the top `N`. Over time, the maximum number of validators may be increased via on-chain governance proposal.

### How to join testnet or mainnet

1. Correctly setup the validator (see "Setting up validator node" section below).
1. Use the latest node version:
   - [Binaries](https://github.com/gonative-cc/network-docs/releases).
1. Join Discord and sync your node. Instructions are in the [network-info.md](./network-info.md). Make sure you are in the testnet / mainnet group.
1. Have enough token delegation to your validator to get into the active validator set (see the section above).

### What are the different states a validator can be in?

A validator is in one of the following states:

- `in validator set`: Validator is in the active set and participates in consensus. The validator is earning rewards and can be slashed for misbehavior.
- `jailed`: Validator misbehaved and is in jail, i.e. outside of the validator set.
  - If the jailing is due to being offline for too long (i.e. having missed more than 95% out of the last 10,000 blocks), the validator can send an `unjail` transaction in order to re-enter the validator set.
  - If the jailing is due to double signing, the validator cannot unjail.
- `unbonded`: Validator is not in the active set, and therefore not signing blocks. The validator cannot be slashed and does not earn any reward. It is still possible to delegate ATOM to an unbonded validator. Undelegating from an unbonded validator is immediate, meaning that the tokens are not subject to the unbonding period.

## Setting up a validator node

### 1. Get Binary

- Download from the [releases page](https://github.com/gonative-cc/gonative/releases) and put it your bin directory (usually somewhere in you PATH, eg /usr/local/bin)
- [Build](https://github.com/gonative-cc/gonative/blob/master/README.md#build) yourself
  - follow the latest [Release Notes](https://github.com/gonative-cc/gonative/blob/master/RELEASE_NOTES.md).
- TODO: Use our released docker [gonative](https://github.com/gonative-cc/gonative/pkgs/container/gonative) container.

Make sure you have correct libwasm according to the latest Release Notes or the [compatibility matrix](https://github.com/gonative-cc/gonative#release-compatibility-matrix). See more in the [libwasm](#libwasmvm) section below.

You can run `gonative version` to see if the binary is accessible and works.

### 2. Initialize chain directory

1. Select your gonative chain directory, default: `~/.gonative`
1. Copy the chain directory to your chain directory:

   - [testnet chain directory](./testnet)

1. Choose your moniker (your validator nickname) end edit `config/config.toml` by setting:

   ```toml
   moniker = "moniker name"
   ```

### 3. Setup account

In order to produce a blocks you have to have a validator account that will sign the proposed blocks. Let's list the account you have:

```sh
gonative keys list --home ~/.gonative --keyring-backend <backend>
```

You can if you use a file based backend, you can use `--keyring-dir` to specify a separate directory where they account keys will be stored. Otherwise the keys will be in the `--home` directory.
To see available parameters run `goantive keys -h` or check the [keyring documentation](https://docs.cosmos.network/v0.52/user/run-node/keyring).

If you don't have any account, you need to add one:

```sh
gonative keys add <your account name> --home ~/.gonative
```

For an institutional ready setup we recommend using [Key Management Systems](https://hub.cosmos.network/main/validators/kms).

### 4. Sync Options

There are few ways how to download and sync the chain with the network:

1. Full consensus sync: start from genesis and execute all blocks. It's very slow and depends on an access to a validator that can provide all blocks from the genesis. NOTE: many validators prune old blocks, and only keep "n" latest ones (eg last few weeks).

2. block-sync (default): downloads blocks from genesis and verifies against the merkle tree of validators, without re-executing all transactions in every blocks. [Details](https://docs.cometbft.com/v1.0/explanation/core/block-sync). NOTE: as with the full consensus sync, it requies access to a validator with all blocks.

3. state-sync: instead of downloading all blocks, select a recent block that we trust to be part of the valid chain and set `trust_height` and `trust_hash` in the `config.toml` file. The ode will download state at that height or near the that height. Once download it will sync with the chain head using the block-sync method. This leads to drastically shorter times for joining a network.

4. quick-sync: download trusted snapshot of a chain at recent height, unpack it to your chain home directory, and then continue. NOTE: quick-sync provides a full snapshot without validator confidential data. Download and unpack it to a temporal directory to not overwrite your config.

See Cosmos Hub [sync documentation](https://hub.cosmos.network/main/hub-tutorials/join-mainnet#sync-options) about more information about syncinc options.

See the [network](./network-info.md) documentation for information about state-sync and quick-sync providers.

### 5. Configuration

Once you choose your sync option, make sure you update the config (app.toml, client.toml and config.toml files) based on your preference. You MUST set non-zero min gas prices in app.toml:

```toml
# <chain-home-directory>/config/app.toml
minimum-gas-prices = "0.08untiv"
```

#### Seeds & Peers

Upon startup the node will need to connect to peers. If there are specific nodes a node operator is interested in setting as seeds or as persistent peers, this can be configured `<chain-home-directory>/config/config.toml`.

```toml
# Comma separated list of seed nodes to connect to
seeds = "<seed node id 1>@<seed node address 1>:26656,<seed node id 2>@<seed node address 2>:26656"

# Comma separated list of nodes to keep persistent connections to
persistent_peers = "<node id 1>@<node address 1>:26656,<node id 2>@<node address 2>:26656"
```

Node operators can optionally download the Quicksync address book.

See the [network](./network-info.md) documentation for information about seeds and persistent_peers values.

#### Other options

See Cosmos Hub [configuration documentation](https://hub.cosmos.network/main/hub-tutorials/join-mainnet#pruning-of-state) about state pruning options, REST and GRPC config.

### 6. Firewall and Production tips

See Cosmos SDK [running a production node docs](https://docs.cosmos.network/main/user/run-node/run-production).

## Start a node

```sh
gonative start --home <chain directory>
```

You can skip `--home` parameter if you are using the default value (~/.gonative).

## Handling chain upgrades

Native includes a powerful governance proposal that allows chain upgrades. Some upgrades are state breaking and require coordinated upgrade to perform upgrade to avoid forks. Once upgrade is triggered, the chain will halt and request validator to perform an upgrade.

See the Cosmos Hub [chain upgrades guide](https://hub.cosmos.network/main/hub-tutorials/live-upgrade-tutorial) for more details.

### Automate upgrades with Cosmovisor

Cosmovisor automates chain upgrades and acts as a supervisor to keep running a chain in case of a process crash.
It monitors the governance module for incoming chain upgrade proposals. If it sees a proposal that gets approved, `cosmovisor` can automatically download the new binary, stop the current one, switch from the old binary to the new one, and finally restart the node with the new binary.

- [Docs](https://github.com/cosmos/cosmos-sdk/tree/main/tools/cosmovisor)
- See the Cosmos Hub [guide](https://hub.cosmos.network/main/hub-tutorials/join-mainnet#cosmovisor).
  recommended setting - [systemd cosmovisor service file](./systemd/cosmovisord.service) (or [systemd gonative service file](./systemd/gonatived.service) if you don't use cosmovisor)

Use the following commands to enable systemd service:

```sh
sudo systemctl daemon-reload
sudo systemctl enable cosmovisord  # or gonatived service
sudo systemctl start cosmovisord
```

To check logs you can use this command

```sh
journalctl -u gonative -f
```

### libwasmvm

Currently, CosmWasm is not integrated, and libwasmvm is not needed.

<!--
When you build the binary from source on the server machine you probably don't need any change. Building from source automatically link the `libwasmvm.$(uname -m).so` created as a part of the build process.

However when you download a binary from GitHub, or from another source, make sure you have the required version of `libwasmvm.<cpu_arch>.so` (should be in your lib directory, e.g.: `/usr/local/lib/`). You can get it:

- from your build machine: copy the libwasmvm.so file:
  ```sh
  scp $GOPATH/pkg/mod/github.com/!cosm!wasm/wasmvm@<version>/internal/api/libwasmvm.$(uname -m).so <remote_host>:/<lib/path>
  ```
- or download from CosmWasm GitHub `wget https://raw.githubusercontent.com/CosmWasm/wasmvm/v<version>/internal/api/libwasmvm.$(uname -m).so -O /lib/libwasmvm.$(uname -m).so`

You don't need to do anything if you are using our Docker image.

NOTE: If use Cosmovisor with auto-download binaries, rather than building from source in the machine where you run your node, you have to download the respective `libwasmvm` into your machine.

See [Release Compatibility Matrix](https://github.com/gonative-cc/gonative#release-compatibility-matrix).

**To test if the libwasm is linked correctly, run `gonative version`.**

-->

## Hardware requirements

Min hardware requirements to run a node.

### Testnet

- 4GB RAM
- 50GB SSD
- 2 vCPU
