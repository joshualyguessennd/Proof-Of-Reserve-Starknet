# Proof of Reserve (POC)

 ⚠️ This codebase has not been audited, might contain bugs and should not be used in production. ⚠️
 
# Introduction

With the massive adoption of crypto and activity generally related to the financial market (trading, lending, swapping, borrowing) users are eager to know if the assets they have on the platforms are not just numbers without values. Proof of Reserve comes with the ambition to allow transparency since point-in-time attestation can be manipulated and cash flow analysis. PoR allows users to conduct audit on digital assets reserves while custodians (exchange, DeFi protocol) gain the trust of users. Another advantage worth mentioning is that PoR is also an appealing prospect for regulators as this self-regulating measure is in line with their overarching vision for the industry.


 # How PoR works?
 
A Merkle root is obtained after the data has been processed via the Merkle tree by the third-party auditor during the Proof of Reserves process. The Merkle root is used to create a cryptographic fingerprint that represents the combination of the balances. In terms of cryptography, the tree's root acts as a "commitment scheme," i.e., a commitment that discloses the leaf nodes to be a part of the initial commitment. The auditors utilize this during Proof of Reserves (PoR) to confirm the balances. Several data samples are compared to the Merkle root. Auditors can detect any tampering with the data since even a little modification to the data impacts the Merkle root.

# ****Our Solution****


![por](https://user-images.githubusercontent.com/37840702/199752841-beccc187-c90b-49b4-821e-725db3a1bb33.png)




The main components of the system can be broken down into the bridge oracles, aggregators (both on Ethereum & Starknet) & Starknet Oracles.


**Starknet Aggregator**

Keeps track of all the rounds & answers received from mainnet aggregator on the reserves of each known asset. The Starknet aggregator also receives feeds from Oracles on assets total supply on Starknet. 

To call the aggreagtor Dapp contracts need to call the main two functions:


```get_latest_reserves``` : returns publisher address, timestamp & the asset resereves value


```get_latest_supply``` : returns publisher address, timestamp & the asset supply value


**Starknet Oracles**

Oracles that keep track of assets supplies on Starknet

**Ethereum<>Starknet Bridges Oracles** 
![por_oracle](https://user-images.githubusercontent.com/37840702/199755200-c35858f2-9a48-4591-a759-6b8a866b1bcd.png)

The Ethereum<>Starknet Oracles are responsible for the feeds on the balance of collateralized assets held on Starknet bridges. A storage proof is provided to the aggregator, the storage value for the balance of each of the underying asset is then computed and the total reserves/collateral value is sent the Starknet Aggregator. 


# ****Shortcomings****


While PoR is adopting more and more on-chain, there are some shortcomings identifies 

• A Proof of Reserves involves proving control over on-chain funds at the point in time of the audit, but cannot prove exclusive possession of private keys that may have theoretically been duplicated by an attacker.

• The procedure cannot identify any hidden encumbrances or prove that funds had not been borrowed for purposes of passing the audit. Similarly, keys may have been lost or funds stolen since the latest audit.

• The auditor must be competent and independent to minimize the risk of duplicity on the part of the audit, or collusion amongst the parties.

while Chainlink seems to offer a more decentralized solution, it is not present in the starknet chain, a solution would be to develop a special solution with the different oracles present on starkent such as stork, point or empiric network .  Proof of Reserve is a real time audit service where user can verify digital assets reserve on-chain or off-chain, we have some questions to understand since chainlink solution is not available for starknet ,

- How decentralized are the oracles solution present on starknet ?
- Where will we select the data to feed the oracle ?

# Roadmap

- [ ] Add governance contracts
- [ ] Build oracles




## Get started

**Clone this repo**

```git clone https://github.com/joshualyguessennd/PoR```

# Environnment 

**Install Node 16**


```
nvm install 16
nvm use 16
```

**Install**
```
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
