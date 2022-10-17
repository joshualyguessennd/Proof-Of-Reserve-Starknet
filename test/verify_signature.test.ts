import chai, { expect } from "chai";
import hre, { ethers, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";

const ASSET_SYMBOL = 10703902247957299200n;
const ASSET_NAME = 4627187504670310400n;
const ADDRESS_ACCOUNT = 216172782113783808n;
const BALANCE = 4412482n;
const TIMESTAMP = 122344n;
const R_LOW = 332795217045463323013001404630688413274n;
const R_HIGH = 146142335783970907433265090013769735112n;
const S_LOW = 303370686640270218425857983888853860003n;
const S_HIGH = 64365439344860771410702511821974968n;
const V = 0;
const PUBLIC_KEY = 761466874539515783303110363281120649054760260892n;
const WRONG_TIMESTAMP = 4412482000030n;
const FAKE_PUBLISHER = 761466874539n;

describe("test starknet contract", function () {
    let l2Contract: any;
    let l2user: any;
    let l2user1: any;

    before(async () => {
        l2user = await starknet.deployAccount("OpenZeppelin");
        l2user1 = await starknet.deployAccount("OpenZeppelin");
        const l2ContractFactory = await starknet.getContractFactory(
            "contracts/starknet/proof_reserve"
        );
        l2Contract = await l2ContractFactory.deploy({
            admin: l2user.starknetContract.address,
            publisher: BigInt(PUBLIC_KEY),
        });
    });

    it("check setters", async () => {
        const address_owner = await l2Contract.call("get_admin");
        expect(BigInt(l2user.address)).to.be.eq(address_owner.admin);
        const isPublisher = await l2Contract.call("is_publisher", {
            address: BigInt(PUBLIC_KEY),
        });
        expect(BigInt(1)).to.be.eq(isPublisher.res);
        const isNotPublisher = await l2Contract.call("is_publisher", {
            address: BigInt(FAKE_PUBLISHER),
        });
        expect(BigInt(0)).to.be.eq(isNotPublisher.res);
    });

    it("add new publisher", async () => {
        // expect tx to revert with non admin setter
        expect(
            l2user1.invoke(l2Contract, "add_publisher", {
                new_publisher: l2user1.starknetContract.address,
            })
        ).to.rejected;
        await l2user.invoke(l2Contract, "add_publisher", {
            new_publisher: l2user1.starknetContract.address,
        });
        const isPublisher = await l2Contract.call("is_publisher", {
            address: BigInt(l2user1.starknetContract.address),
        });
        expect(BigInt(1)).to.be.eq(isPublisher.res);
    });

    it("test verify signature", async () => {
        await l2user.invoke(l2Contract, "add_publisher", {
            new_publisher: l2user1.starknetContract.address,
        });
        // expect it to fail  with unauthorized publisher
        expect(
            l2user1.invoke(l2Contract, "post_data_l2", {
                asset_sym: 0,
                asset_name: 0,
                address_owner: 0,
                balance: 0,
                r_low: 0,
                r_high: 0,
                s_low: 0,
                s_high: 0,
                v: 0,
                public_key: BigInt(0n),
            })
        ).to.rejected;
        // expect it to fail with invalid signature
        expect(
            l2user1.invoke(l2Contract, "post_data_l2", {
                asset_sym: 0,
                asset_name: 0,
                address_owner: 0,
                balance: 0,
                r_low: 0,
                r_high: 0,
                s_low: 0,
                s_high: 0,
                v: 0,
                public_key: BigInt(PUBLIC_KEY),
            })
        ).to.rejected;
        await l2user1.invoke(l2Contract, "post_data_l2", {
            asset_sym: BigInt(ASSET_SYMBOL),
            asset_name: BigInt(ASSET_NAME),
            address_owner: BigInt(ADDRESS_ACCOUNT),
            timestamp: BigInt(TIMESTAMP),
            balance: BigInt(BALANCE),
            r_low: BigInt(R_LOW),
            r_high: BigInt(R_HIGH),
            s_low: BigInt(S_LOW),
            s_high: BigInt(S_HIGH),
            v: V,
            public_key: BigInt(PUBLIC_KEY),
        });
        let root = await l2Contract.call("get_root", {
            public_key: BigInt(ADDRESS_ACCOUNT),
            asset: BigInt(ASSET_NAME),
            balance: BigInt(BALANCE),
            timestamp: BigInt(TIMESTAMP),
        });
        console.log("the root is", root.res);
        // verify root
        let result = await l2Contract.call("verify_balance", {
            leaf: 0,
            merkle_root: root.res,
            proof: [
                BigInt(ADDRESS_ACCOUNT),
                BigInt(ASSET_NAME),
                BigInt(BALANCE),
                BigInt(TIMESTAMP),
            ],
        });
        // verify the root is valid
        expect(BigInt(1)).to.be.eq(result.res);
        // // verify the root is wrong
        let result_1 = await l2Contract.call("verify_balance", {
            leaf: 0,
            merkle_root: root.res,
            proof: [
                BigInt(ADDRESS_ACCOUNT),
                BigInt(ASSET_NAME),
                BigInt(WRONG_TIMESTAMP),
                BigInt(TIMESTAMP),
            ],
        });
        expect(BigInt(0)).to.be.eq(result_1.res);
    });
});
