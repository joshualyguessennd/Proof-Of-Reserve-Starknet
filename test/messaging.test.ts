
import { expect } from "chai";
import hre, { ethers, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";
import { Contract, ContractFactory } from "ethers";
import { Account } from "hardhat/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { getSelectorFromName } from "starknet/dist/utils/hash";

describe("test contracts interaction", function () {
    let l1Contract: Contract;
    let l2Contract: StarknetContract;
    let l1ContractFactory: ContractFactory;
    let l2user: Account;
    let selector: string;
    let mockStarknetMessagingAddress: string;
    let admin: SignerWithAddress;
    let l1_user: SignerWithAddress;


    before(async () => {
        [admin, l1_user] = await hre.ethers.getSigners();
        // const starkNetFake = await smock.fake(interface);
        l2user = await starknet.deployAccount("OpenZeppelin");

        const networkUrl =
            (config as HardhatUserConfig).networks?.l1_testnet?.url ||
            "http://localhost:8545";

        mockStarknetMessagingAddress = (
            await starknet.devnet.loadL1MessagingContract(networkUrl)
        ).address;

        const l2ContractFactory = await starknet.getContractFactory(
            "contracts/starknet/ProofReserve"
        );

        l2Contract = await l2ContractFactory.deploy({ admin: l2user.starknetContract.address, publisher: BigInt(761466874539515783303110363281120649054760260892n) });

        l1ContractFactory = await ethers.getContractFactory("L1_CONTRACT", admin);
        selector = getSelectorFromName("post_data")
        l1Contract = await l1ContractFactory.deploy(
            mockStarknetMessagingAddress,
            BigInt(l2Contract.address),
            BigInt(selector)
        )
        await l1Contract.deployed();
    })

    it("check deployment data", async () => {
        const _selector = await l1Contract.SELECTOR();

        expect(_selector).to.be.eq(BigInt(selector))
        expect(await l1Contract.l2Contract()).to.be.eq(BigInt(l2Contract.address));
        expect(await l1Contract.countPublishers()).to.be.eq(0);
        // wrong access
        expect(l1Contract.connect(l1_user).addNewPublisher(admin.address)).to.rejected;

        await l1Contract.connect(admin).addNewPublisher(admin.address);
        expect(await l1Contract.countPublishers()).to.be.eq(1);

    })

    it("check publish data", async () => {

        await l1Contract.connect(admin).addNewPublisher(admin.address);
        // expect it to fail  with is Not Signer
        expect(l1Contract.connect(l1_user).publishData(
            BigInt(10703902247957299200n),
            BigInt(4627187504670310400n),
            "0x0000000000000000000000000300000000000000",
            BigInt(4412482n),
            // r 
            // BigInt(4972965992792418342039714693645413618535966722652354834878857075697447155290n),
            "0x0afe995879eb87f737664646c786c2c7fa5e0702bf50260074355e21ac2d365a",
            // s
            // BigInt(21902424048175322046620124405489474242415230961420388732556387699816693411n),
            "0x000c65760f5886d4947a60caa12e6db8e43b11a7b063541dcc5e938cdd687ea3",
            0
        )).to.rejected;

        await l1Contract.connect(admin).publishData(
            BigInt(10703902247957299200n),
            BigInt(4627187504670310400n),
            "0x0000000000000000000000000300000000000000",
            BigInt(4412482n),
            // r 
            // BigInt(4972965992792418342039714693645413618535966722652354834878857075697447155290n),
            "0x0afe995879eb87f737664646c786c2c7fa5e0702bf50260074355e21ac2d365a",
            // s
            // BigInt(21902424048175322046620124405489474242415230961420388732556387699816693411n),
            "0x000c65760f5886d4947a60caa12e6db8e43b11a7b063541dcc5e938cdd687ea3",
            0
        )

        await l1Contract.connect(admin).addNewKeeper(admin.address);

        await l1Contract.connect(admin).sendBatchTransaction();

        // error with the messaging contract
        const flushL1Response = await starknet.devnet.flush();

    })
})


// async function setupTest() {
//     const [admin, l1_user] = await hre.ethers.getSigners();
//     // const starkNetFake = await smock.fake(interface);
//     const l2user = await starknet.deployAccount("OpenZeppelin");

//     const networkUrl =
//         (config as HardhatUserConfig).networks?.l1_testnet?.url ||
//         "http://localhost:8545";

//     const mockStarknetMessagingAddress = (
//         await starknet.devnet.loadL1MessagingContract(networkUrl)
//     ).address;
//     let l2Contract: StarknetContract;

//     const l2ContractFactory = await starknet.getContractFactory(
//         "contracts/starknet/ProofReserve"
//     );

//     l2Contract = await l2ContractFactory.deploy({ admin: l2user.starknetContract.address, publisher: BigInt(761466874539515783303110363281120649054760260892n) });

//     // const l2Contract = 31415;
//     const l1Contract = await simpleDeploy("L1_CONTRACT", [
//         mockStarknetMessagingAddress,
//         BigInt(l2Contract.address),
//         BigInt(1447471469451581726846414018284835017311951023166934288557129659906920235665)
//     ]);

//     console.log("messaging address is", mockStarknetMessagingAddress);

//     // await l2user.invoke(l2Contract, "set_l1", { l1_address: l1Contract.address });
//     return {
//         l1Contract: l1Contract as any,
//         l2Contract: l2Contract as any,
//         l2user: l2user as any,
//         mockStarknetMessagingAddress: mockStarknetMessagingAddress as any,
//         // starkNetFake: starkNetFake as any,
//         admin: admin as any,
//         l1_user: l1_user as any
//     };
// }