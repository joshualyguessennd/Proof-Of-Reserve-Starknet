import chai, { expect } from "chai";
import hre, { ethers, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";
import { CONST_OBJECT } from "./constants";


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
            publisher: BigInt(CONST_OBJECT.PUBLIC_KEY),
        });
    });

    it("check setters", async () => {
        const address_owner = await l2Contract.call("get_admin");
        expect(BigInt(l2user.address)).to.be.eq(address_owner.admin);
        const isPublisher = await l2Contract.call("is_publisher", {
            address: BigInt(CONST_OBJECT.PUBLIC_KEY),
        });
        expect(BigInt(1)).to.be.eq(isPublisher.res);
        const isNotPublisher = await l2Contract.call("is_publisher", {
            address: BigInt(CONST_OBJECT.FAKE_PUBLISHER),
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
                public_key: BigInt(CONST_OBJECT.PUBLIC_KEY),
            })
        ).to.rejected;
        await l2user1.invoke(l2Contract, "post_data_l2", {
            asset_sym: BigInt(CONST_OBJECT.ASSET_SYMBOL),
            asset_name: BigInt(CONST_OBJECT.ASSET_NAME),
            address_owner: BigInt(CONST_OBJECT.ADDRESS_ACCOUNT_INT),
            timestamp: BigInt(CONST_OBJECT.TIMESTAMP),
            balance: BigInt(CONST_OBJECT.BALANCE),
            r_low: BigInt(CONST_OBJECT.R_LOW),
            r_high: BigInt(CONST_OBJECT.R_HIGH),
            s_low: BigInt(CONST_OBJECT.S_LOW),
            s_high: BigInt(CONST_OBJECT.S_HIGH),
            v: CONST_OBJECT.V,
            public_key: BigInt(CONST_OBJECT.PUBLIC_KEY),
        });
        let root = await l2Contract.call("get_root", {
            public_key: BigInt(CONST_OBJECT.ADDRESS_ACCOUNT_INT),
            asset: BigInt(CONST_OBJECT.ASSET_NAME),
            balance: BigInt(CONST_OBJECT.BALANCE),
            timestamp: BigInt(CONST_OBJECT.TIMESTAMP),
        });
        console.log("the root is", root.res);
        // verify root
        let result = await l2Contract.call("verify_balance", {
            leaf: 0,
            merkle_root: root.res,
            proof: [
                BigInt(CONST_OBJECT.ADDRESS_ACCOUNT_INT),
                BigInt(CONST_OBJECT.ASSET_NAME),
                BigInt(CONST_OBJECT.BALANCE),
                BigInt(CONST_OBJECT.TIMESTAMP),
            ],
        });
        // verify the root is valid
        expect(BigInt(1)).to.be.eq(result.res);
        // // verify the root is wrong
        let result_1 = await l2Contract.call("verify_balance", {
            leaf: 0,
            merkle_root: root.res,
            proof: [
                BigInt(CONST_OBJECT.ADDRESS_ACCOUNT_INT),
                BigInt(CONST_OBJECT.ASSET_NAME),
                BigInt(CONST_OBJECT.WRONG_TIMESTAMP),
                BigInt(CONST_OBJECT.TIMESTAMP),
            ],
        });
        expect(BigInt(0)).to.be.eq(result_1.res);
    });
});
