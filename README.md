# Starknet Bridges Proof of Reserves (POC)

 ⚠️ This codebase has not been audited, might contain bugs and should not be used in production. ⚠️
 
# Introduction

With the massive adoption of crypto and activity generally related to the financial market (trading, lending, swapping, borrowing) users are eager to know if the assets they have on the platforms are not just numbers without values. Proof of Reserve comes with the ambition to allow transparency since point-in-time attestation can be manipulated and cash flow analysis. PoR allows users to conduct audit on digital assets reserves while custodians (exchange, DeFi protocol) gain the trust of users. Another advantage worth mentioning is that PoR is also an appealing prospect for regulators as this self-regulating measure is in line with their overarching vision for the industry.

# ****Our Solution****

We propose two solutions each with its own drawbacks and advantages.

## First system architecture (permissionless)

How it works:

1- A user call ``sendData()`` on l1 aggregator providing the ``address`` of the asset to be proved.

2- The l1 aggregator gets the address of the bridge holding the provided assets, and fetches its balance. A payload with the block number, the returned balance is then sent to the Starknet messaging contract to be bridged over to Starknet.

3- The l2 aggregator receives the payload and caches the collateral & block number. 



![por_perm](https://user-images.githubusercontent.com/37840702/201185181-628fd09d-a8f9-489e-8f0b-88e5863e440a.png)


## System components

The main components of the system can be broken down into the bridge oracles, aggregators (both on Ethereum & Starknet) & Starknet Oracles.


**Mainnet Aggregator**

Allows us to list all known Starknet bridges, compute their balances and send the reserves to Starknet. It's basically our gateway through which we send reserves audits to Starknet in a transparent and permissionless way. Supports both ERC20 tokens and Ether balances.


**Starknet Aggregator**

Keeps track of all the rounds & answers received from mainnet aggregator on the reserves of each known asset held by the known Starknet bridges on mainnet. 
 

To call the aggreagtor Dapp contracts need to call the main two functions:


```get_latest_reserves``` : returns block number & the asset reserves value


```get_latest_supply``` : returns  block number & the asset total supply value


Example of usage: 

```Cairo
let (reserves,_)=IStarknetAggregator.get_latest_reserves(AGGREGATOR_ADDRESS, ASSET_ADDRESS);
let (supply,_)=IStarknetAggregator.get_latest_supply(AGGREGATOR_ADDRESS, ASSET_ADDRESS);

 let (le) = uint256_le(supply, reserves);
        if (le == TRUE) {
  //mint your tokens on starknet
 
        } else {
        //revert
        
        }

```

**Starknet & Mainnet Maintainers**

Bots that would keep triggering the reporting of assets supply & resrves to the l2 & l1 aggregator.


## Second system architecture (not permissionless)

![por](https://user-images.githubusercontent.com/37840702/199752841-beccc187-c90b-49b4-821e-725db3a1bb33.png)

DAI Oracle as an example:

![dai oracle](https://user-images.githubusercontent.com/37840702/200176615-6d1f5b88-84b8-49bf-8358-08167df470c7.png)

The Ethereum<>Starknet oracles are responsible for the feeds on the balance of collateralized assets held on Starknet bridges. A storage proof is provided to the aggregator, the storage value for the balance of each of the underlying asset is then computed and the total reserves/collateral value is sent the Starknet Aggregator. 



# TO DO

- [ ] Add governance contracts
- [ ] Explore how to incentivize maintainers
- [ ] Explore integration with Starknet oracles
- [ ] Explore how to optimize external calls on l1 aggregator



## Get started

**Clone this repo**

```git clone https://github.com/joshualyguessennd/ProofReserve-Starknet```

# Environnment 

**Install Node 16**


```
nvm install 16
nvm use 16
```

**Install**
```
cd ProofReserve-Starknet
python -m venv .venv
source .venv/bin/activate
pip install cairo-lang
pip install starknet-devnet
yarn
```

**run tests**
first run both networks for ethereum and starknet
```
yarn testnet:l1
yarn testnet:l2
```
compile code
```
yarn compile:l1
yarn compile:l2
```
run test
```
yarn test
```

# Environnment (with Docker)

Build the image and run `sleep 9999` command.
```
docker compose up --build
```

Run a terminal where you start testnet-l1
```
docker exec -ti $(docker ps -f name=playground -q) bash
yarn testnet:l1
```

Run a terminal where you start testnet-l1
```
docker exec -ti $(docker ps -f name=playground -q) bash
yarn testnet:l2
```

Run a terminal where you run your tests
```
docker exec -ti $(docker ps -f name=playground -q) bash
yarn test
```
