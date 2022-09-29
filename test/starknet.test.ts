import chai, { expect } from "chai";
import hre, { ethers, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";

describe("test starknet contract", function () {
    it("check address", async () => {
        const { l2Contract, l2user } = await setupTest();
        console.log(l2Contract.address);
    })

})



async function setupTest() {
    const l2user = await starknet.deployAccount("OpenZeppelin");
    const l2ContractFactory = await starknet.getContractFactory(
        "contracts/starknet/ProofReserve"
    );
    let l2Contract: StarknetContract;
    l2Contract = await l2ContractFactory.deploy({ admin: l2user.starknetContract.address, publisher: 761466874539515783303110363281120649054760260892n });

    return {
        l2Contract: l2Contract as any,
        l2user: l2user as any
    }
}