import { solidity } from "ethereum-waffle";
import chai, { expect } from "chai";
import { simpleDeploy } from "@makerdao/hardhat-utils";
import hre, { starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";

chai.use(solidity);

describe("L1Contract", function () {
    it("data are corrects", async () => {
        const { l1Contract, l2Contract, mockStarknetMessagingAddress } = await setupTest();
        expect(await l1Contract.starkNet()).to.be.eq(
            mockStarknetMessagingAddress
        );
        expect(await l1Contract.l2Contract()).to.be.eq(BigInt(l2Contract.address));
    });

    it("publish_data", async () => {
        const { l1Contract, l2Contract, admin } = await setupTest();
        console.log("l2 contract is: ", l2Contract.address);
        const tx = await l1Contract.connect(admin).publishFromL1();
        await starknet.devnet.flush();
        console.log(tx);
        // const flushL1Messages = flushL1Response.consumed_messages.from_l1;
        // expect(flushL1Response.consumed_messages.from_l2).to.be.empty;
        // expect(flushL1Messages).to.have.a.lengthOf(1);
        // const counter = await l2Contract.call("get_counter", {});
        // console.log(counter.res);
    });
});

async function setupTest() {
    const [admin] = await hre.ethers.getSigners();
    // const starkNetFake = await smock.fake(interface);

    const networkUrl =
        (config as HardhatUserConfig).networks?.l1_testnet?.url ||
        "http://localhost:8545";

    const mockStarknetMessagingAddress = (
        await starknet.devnet.loadL1MessagingContract(networkUrl)
    ).address;
    let l2Contract: StarknetContract;

    const l2ContractFactory = await starknet.getContractFactory(
        "contracts/starknet/ProofReserve"
    );
    l2Contract = await l2ContractFactory.deploy();

    // const l2Contract = 31415;
    const l1Contract = await simpleDeploy("L1_CONTRACT", [
        BigInt(l2Contract.address),
        mockStarknetMessagingAddress,
    ]);
    return {
        l1Contract: l1Contract as any,
        l2Contract: l2Contract as any,
        mockStarknetMessagingAddress: mockStarknetMessagingAddress as any,
        // starkNetFake: starkNetFake as any,
        admin: admin as any,
    };
}
