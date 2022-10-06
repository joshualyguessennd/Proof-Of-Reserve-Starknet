import chai, { expect } from "chai";
import hre, { ethers, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";

describe("test starknet contract", function () {
    it("check setters", async () => {
        const { l2Contract, l2user } = await setupTest();
        const address_owner = await l2Contract.call("get_admin");
        expect(BigInt(l2user.address)).to.be.eq(address_owner.admin);
        const isPublisher = await l2Contract.call("is_publisher", { address: BigInt(761466874539515783303110363281120649054760260892n) });
        expect(BigInt(1)).to.be.eq(isPublisher.res);
        const isNotPublisher = await l2Contract.call("is_publisher", { address: BigInt(761466874539) });
        expect(BigInt(0)).to.be.eq(isNotPublisher.res);
    })

    it("add new publisher", async () => {
        const { l2Contract, l2user, l2user1 } = await setupTest();
        // expect tx to revert with non admin setter
        expect(l2user1.invoke(l2Contract, "add_publisher", { new_publisher: l2user1.starknetContract.address })).to.rejected;
        await l2user.invoke(l2Contract, "add_publisher", { new_publisher: l2user1.starknetContract.address })
        const isPublisher = await l2Contract.call("is_publisher", { address: BigInt(l2user1.starknetContract.address) });
        expect(BigInt(1)).to.be.eq(isPublisher.res);
    })

    it("test verify signature", async () => {
        const { l2Contract, l2user, l2user1 } = await setupTest();

        await l2user.invoke(l2Contract, "add_publisher", { new_publisher: l2user1.starknetContract.address })
        // expect it to fail  with unauthorized publisher
        expect(l2user1.invoke(l2Contract, "post_data_l2", {
            asset_sym: 0, asset_name: 0,
            address_owner: 0,
            balance: 0,
            r_low: 0,
            r_high: 0,
            s_low: 0,
            s_high: 0,
            v: 0,
            public_key: BigInt(0n)
        })).to.rejected;
        // expect it to fail with invalid signature
        expect(l2user1.invoke(l2Contract, "post_data_l2", {
            asset_sym: 0, asset_name: 0,
            address_owner: 0,
            balance: 0,
            r_low: 0,
            r_high: 0,
            s_low: 0,
            s_high: 0,
            v: 0,
            public_key: BigInt(761466874539515783303110363281120649054760260892n)
        })).to.rejected;
        await l2user1.invoke(l2Contract, "post_data_l2", {
            asset_sym: BigInt(10703902247957299200n),
            asset_name: BigInt(4627187504670310400n),
            address_owner: BigInt(216172782113783808n),
            timestamp: BigInt(122344n),
            balance: BigInt(4412482n),
            r_low: BigInt(332795217045463323013001404630688413274n),
            r_high: BigInt(146142335783970907433265090013769735112n),
            s_low: BigInt(303370686640270218425857983888853860003n),
            s_high: BigInt(64365439344860771410702511821974968n),
            v: BigInt(0),
            public_key: BigInt(761466874539515783303110363281120649054760260892n)

        })
        let root = await l2Contract.call("get_root", { public_key: BigInt(216172782113783808n), asset: BigInt(4627187504670310400n), balance: BigInt(4412482n), timestamp: BigInt(122344n) });
        console.log("the root is", root.res);
        // verify root
        let result = await l2Contract.call("verify_balance", { leaf: 0, merkle_root: root.res, proof: [BigInt(216172782113783808n), BigInt(4627187504670310400n), BigInt(4412482n), BigInt(122344n)] })
        // verify the root is valid
        expect(BigInt(1)).to.be.eq(result.res);
        // // verfify the root is wrong
        let result_1 = await l2Contract.call("verify_balance", { leaf: 0, merkle_root: root.res, proof: [BigInt(216172782113783808n), BigInt(4627187504670310400n), BigInt(441248200n), BigInt(12244n)] })
        expect(BigInt(0)).to.be.eq(result_1.res);
    })



    async function setupTest() {
        const l2user = await starknet.deployAccount("OpenZeppelin");
        const l2user1 = await starknet.deployAccount("OpenZeppelin");
        const l2ContractFactory = await starknet.getContractFactory(
            "contracts/starknet/ProofReserve"
        );
        let l2Contract: StarknetContract;
        l2Contract = await l2ContractFactory.deploy({ admin: l2user.starknetContract.address, publisher: BigInt(761466874539515783303110363281120649054760260892n) });

        return {
            l2Contract: l2Contract as any,
            l2user: l2user as any,
            l2user1: l2user1 as any
        }
    }
})