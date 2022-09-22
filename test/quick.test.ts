import { Contract, ContractFactory } from "ethers";
import { solidity } from "ethereum-waffle";
import chai, { expect } from "chai";
import hre, { ethers, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);

describe("L1Contract", function () {
  let l1Contract: Contract;
  let admin: SignerWithAddress;
  let l2Contract: StarknetContract;
  let l1ContractFactory: ContractFactory;

  it("data are corrects", async () => {
    [admin] = await hre.ethers.getSigners();

    const networkUrl =
      (config as HardhatUserConfig).networks?.l1_testnet?.url ||
      "http://localhost:8545";

    const mockStarknetMessagingAddress = (
      await starknet.devnet.loadL1MessagingContract(networkUrl)
    ).address;

    const l2ContractFactory = await starknet.getContractFactory(
      "contracts/starknet/ProofReserve"
    );
    l2Contract = await l2ContractFactory.deploy();

    l1ContractFactory = await ethers.getContractFactory("L1_CONTRACT", admin);

    l1Contract = await l1ContractFactory.deploy(
      BigInt(l2Contract.address),
      mockStarknetMessagingAddress
    );

    expect(await l1Contract.starkNet()).to.be.eq(mockStarknetMessagingAddress);
    expect(await l1Contract.l2Contract()).to.be.eq(BigInt(l2Contract.address));
  });

  it("publish_data", async () => {
    // it should revert invalid data
    const tx = await l1Contract.connect(admin).publishFromL1(10703902247957299200n, 4627187504670310400n, admin.address, 4412482, 332795217045, 3033706866402);
    const receipt = await tx.wait();

    const loggedEvent = receipt.events.filter(
      (x: any) => x.event == "LogMessageToL2"
    );

    const flushL1Response = await starknet.devnet.flush();

    const flushL1Messages = flushL1Response.consumed_messages.from_l1;
    expect(flushL1Response.consumed_messages.from_l2).to.be.empty;
    expect(flushL1Messages).to.have.a.lengthOf(1);
  });
});
