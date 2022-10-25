import { solidity } from "ethereum-waffle";
import chai, { expect } from "chai";
import { simpleDeploy } from "@makerdao/hardhat-utils";
import hre, { ethers, network, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig, Account } from "hardhat/types";
import { Contract, ContractFactory } from "ethers";
import config from "../hardhat.config";
import { getSelectorFromName } from "starknet/dist/utils/hash";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Setter", function () {
    let l1Contract: Contract;
    let l2Contract: StarknetContract;
    let l1ContractFactory: ContractFactory;
    let l2User: Account;
    let selector: string;
    let mockStarknetMessagingAddress: string;
    let admin: SignerWithAddress;

    before(async () => {
        [admin] = await hre.ethers.getSigners();
        // const starkNetFake = await smock.fake(interface);
        l2User = await starknet.deployAccount("OpenZeppelin");

        const networkUrl =
            (config as HardhatUserConfig).networks?.l1_testnet?.url ||
            "http://localhost:8545";

        mockStarknetMessagingAddress = (
            await starknet.devnet.loadL1MessagingContract(networkUrl)
        ).address;

        const l2ContractFactory = await starknet.getContractFactory(
            "contracts/starknet/setter"
        );
        l2Contract = await l2ContractFactory.deploy({});

        selector = getSelectorFromName("set_data");

        l1ContractFactory = await ethers.getContractFactory("Setter", admin);

        l1Contract = await l1ContractFactory.deploy(
            BigInt(l2Contract.address),
            mockStarknetMessagingAddress,
            BigInt(selector)
        );
        await l1Contract.deployed();

        await l2User.invoke(l2Contract, "set_l1", { l1_address: l1Contract.address });
    })
    it("data are corrects", async () => {
        expect(await l1Contract.starkNet()).to.be.eq(
            mockStarknetMessagingAddress
        );
        expect(await l1Contract.l2Contract()).to.be.eq(BigInt(l2Contract.address));
    });

    it("publish_data", async () => {
        const tx = await l1Contract.connect(admin).set(2n);
        const flushL1Response = await starknet.devnet.flush();
        const data = await l2Contract.call("read_x", {})
        expect(data.res).to.be.eq(2n);
        const flushL1Messages = flushL1Response.consumed_messages.from_l1;
        expect(flushL1Response.consumed_messages.from_l2).to.be.empty;
        expect(flushL1Messages).to.have.a.lengthOf(1);
    });
});

