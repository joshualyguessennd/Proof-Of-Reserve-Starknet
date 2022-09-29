import chai, { expect } from "chai";
import hre, { ethers, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";

describe("test starknet contract", function () {
    it("check setters", async () => {
        const { l2Contract, l2user } = await setupTest();
        const address_owner = await l2Contract.call("get_admin");
        expect(BigInt(l2user.address)).to.be.eq(address_owner.admin);
        const isPublisher = await l2Contract.call("isPublisher", { address: BigInt(761466874539515783303110363281120649054760260892) });
        expect(BigInt(1)).to.be.eq(isPublisher.res);
        const isNotPublisher = await l2Contract.call("isPublisher", { address: BigInt(761466874539) });
        expect(BigInt(0)).to.be.eq(isNotPublisher.res);
    })

})



async function setupTest() {
    const l2user = await starknet.deployAccount("OpenZeppelin");
    const l2ContractFactory = await starknet.getContractFactory(
        "contracts/starknet/ProofReserve"
    );
    let l2Contract: StarknetContract;
    l2Contract = await l2ContractFactory.deploy({ admin: l2user.starknetContract.address, publisher: BigInt(761466874539515783303110363281120649054760260892) });

    return {
        l2Contract: l2Contract as any,
        l2user: l2user as any
    }
}