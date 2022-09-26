import { solidity } from "ethereum-waffle";
import chai, { expect } from "chai";
import { simpleDeploy } from "@makerdao/hardhat-utils";
import hre, { network, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";

describe("Setter", function () {
    it("data are corrects", async () => {
        const { l1Contract, l2Contract, mockStarknetMessagingAddress } = await setupTest();
        console.log("message contract", await l1Contract.starkNet());
        expect(await l1Contract.starkNet()).to.be.eq(
            mockStarknetMessagingAddress
        );
        expect(await l1Contract.l2Contract()).to.be.eq(BigInt(l2Contract.address));
    });

    it("publish_data", async () => {
        // await starknet.devnet.loadL1MessagingContract()
        const { l1Contract, l2Contract, admin } = await setupTest();
        console.log("l2 contract is: ", l2Contract.address);
        console.log("l1 contract is:", l1Contract.address);
        // const tx_test = await l1Contract.getCancellationDelay();
        const tx = await l1Contract.connect(admin).set(admin.address, 2);
        // const flushL1Response = await starknet.devnet.flush();
        // const receipt = await tx.wait();

        // const loggedEvent = receipt.events.filter(
        //     (x: any) => x.event == "LogMessageToL2"
        // );

        // const flushL1Response = await starknet.devnet.flush();
        // await starknet.devnet.flush();
        // console.log(tx);
        // const data = await l2Contract.call("read_x", {})
        // console.log(data)

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
    const l2user = await starknet.deployAccount("OpenZeppelin");

    const networkUrl =
        (config as HardhatUserConfig).networks?.l1_testnet?.url ||
        "http://localhost:8545";

    const mockStarknetMessagingAddress = (
        await starknet.devnet.loadL1MessagingContract(networkUrl)
    ).address;
    let l2Contract: StarknetContract;

    const l2ContractFactory = await starknet.getContractFactory(
        "contracts/starknet/setter"
    );
    l2Contract = await l2ContractFactory.deploy();

    // const l2Contract = 31415;
    const l1Contract = await simpleDeploy("Setter", [
        BigInt(l2Contract.address),
        mockStarknetMessagingAddress,
    ]);

    console.log("messaging address is", mockStarknetMessagingAddress);

    await l2user.invoke(l2Contract, "set_l1", { l1_address: l1Contract.address });
    return {
        l1Contract: l1Contract as any,
        l2Contract: l2Contract as any,
        mockStarknetMessagingAddress: mockStarknetMessagingAddress as any,
        // starkNetFake: starkNetFake as any,
        admin: admin as any,
    };
}