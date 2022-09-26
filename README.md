# Proof of Reserve

# Introduction

With the massive adoption of crypto and activity generally related to the financial market (trading, lending, swapping, borrowing) users are eager to know if the assets they have on the platforms are not just numbers without values. Proof of Reserve comes with the ambition to allow transparency since point-in-time attestation can be manipulated and cash flow analysis . PoR allows users to conduct audit digital assets reserves while custodians (exchange, DeFi protocol) gain the trust of users

# How it works

During Proof of Reserve, a third party takes a snapshot of the balances and generate a merkle root after passing the balance to a merkle tree, this cryptographic structure allows privacy and transparency . Kraken and Chainlink have an implementation of PoR 

**what is Merkle tree ?**
In cryptography, a hash tree or Merkle tree is a tree in which every leaf node is labelled with the cryptographic hash of a data block, and every non-leaf node is labelled with the hash of the labels of its child nodes. Hash trees allow efficient and secure verification of the contents of large data structures.

**Kraken Case**
The auditor then collects digital signatures produced by Kraken, which prove ownership over the on-chain addresses with publicly verifiable balances. Lastly, the auditor compares and verifies that these balances exceed or match the client balances represented in the Merkle tree, and therefore that the client assets are held on a full-reserve basis.

![Untitled](https://www.notion.so/image/https%3A%2F%2Fs3-us-west-2.amazonaws.com%2Fsecure.notion-static.com%2Fda765df6-fa29-4b4e-81d6-88b4b7e5cb8a%2FUntitled.png?table=block&id=c2e3703e-c447-43d9-aea5-7431a6d909f4&spaceId=703c9ac7-6b4a-4c85-a4d6-c178cba99965&width=2000&userId=dd8e8ef1-9abd-4bd5-a553-060b5655d4f9&cache=v2)

**Chainlink Case**

Chainlink provides  smart contracts with the data needed to calculate collateralization  on multi chain or backed off chain. using his decentralized oracle network , autonomous audits can be conducts and automated by anyone . while traditional implementations of PoR like kraken and centralized exchanges use collateralization of token currently on the cryptocurrency ecosystem, chainlink PoR can bring transparency to any asset that has been brought on-chain, it could be real estates, NFT etc .  

![Untitled](https://www.notion.so/image/https%3A%2F%2Fs3-us-west-2.amazonaws.com%2Fsecure.notion-static.com%2F889e6552-3ef7-4cd5-8712-f0ca54524143%2FUntitled.png?table=block&id=a5d0a4f0-5ea1-4062-8b36-0b9b4c669e01&spaceId=703c9ac7-6b4a-4c85-a4d6-c178cba99965&width=2000&userId=dd8e8ef1-9abd-4bd5-a553-060b5655d4f9&cache=v2)

# ****Shortcomings****

While PoR is adopting more and more on-chain, there are some shortcomings identifies 

• A Proof of Reserves involves proving control over on-chain funds at the point in time of the audit, but cannot prove exclusive possession of private keys that may have theoretically been duplicated by an attacker.

• The procedure cannot identify any hidden encumbrances or prove that funds had not been borrowed for purposes of passing the audit. Similarly, keys may have been lost or funds stolen since the latest audit.

• The auditor must be competent and independent to minimize the risk of duplicity on the part of the audit, or collusion amongst the parties.

while Chainlink seems to offer a more decentralized solution, it is not present in the starknet chain , a solution would be to develop a special solution with the different oracles present on starkent such as stork, point or empiric network .  Proof of Reserve is a real time audit service where user can verify digital assets reserve on-chain or off-chain, we have some questions to understand since chainlink solution is not available for starknet ,

- How decentralized are the oracles solution present on starknet ?
- Where will we select the data to feed the oracle ?

# ****Purpose of this repository****

One of the main issue when we come to data source, One of the problems that arises when it comes to using data published by a third party is the robustness and legitimacy of the information. Was the messenger and the message sent by a trusted third party?

This repository deals with the legitimacy of sources, how an authority allocated to publish information is verified following the sending of information whether from layer 1 or starknet

The function ```set_data``` and ```set_data_l2``` permit to publish data that deals with balance of an account concerning a specific assets . the message is signed following the Ethereum Signed message standard ```b'\x19Ethereum Signed Message:\n32'``` 

entity send data containing ```asset symbol```, ```asset name```, ```address```, and ```balance``` with signature , ```r```, ```s```, ```v```. If signature doesn't match , the transaction failed 


![](../../../../Downloads/IMG_0060.jpg)


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

```
docker compose up --build
docker exec -ti $(docker ps -f name=playground -q) bash
yarn test
```
