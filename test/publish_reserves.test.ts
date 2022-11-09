import { expect } from "chai";
import hre, { ethers, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";
import { Contract, ContractFactory } from "ethers";
import { Account } from "hardhat/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { getSelectorFromName } from "starknet/dist/utils/hash";
import { uintFromParts } from "./utils";

describe("test contracts interaction", function () {
  let l1Aggregator: Contract;
  let l2Aggregator: StarknetContract;
  let l1AggregatorFactory: ContractFactory;
  let l1TokenFactory: ContractFactory;
  let l2user: Account;
  let selector: string;
  let l2Token: StarknetContract;
  let l1Token: Contract;
  let mockStarknetMessagingAddress: string;
  let admin: SignerWithAddress;
  let l1_user: SignerWithAddress;
  const l2DaiBridgeMock =
    "0x079f0c4439d5b9d37c62c343625cdf7497a706635740d9ce2dcd8a6255c0b606";
  const l1DaiBridgeMock = "0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5";
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

    const l2TokenFactory = await starknet.getContractFactory(
      "contracts/starknet/mocks/mock_token"
    );

    l2Token = await l2TokenFactory.deploy({
      name: 1n,
      symbol: 1n,
      decimals: 1n,
      initial_supply: { low: BigInt(100000 * 10 ** 18), high: 0n },
      recipient: BigInt(l2DaiBridgeMock),
    });

    const l2AggregatorFactory = await starknet.getContractFactory(
      "contracts/starknet/l2Aggregator"
    );

    l2Aggregator = await l2AggregatorFactory.deploy({
      _admin: BigInt(l2user.starknetContract.address),
    });

    l1AggregatorFactory = await ethers.getContractFactory(
      "L1Aggregator",
      admin
    );

    l1TokenFactory = await ethers.getContractFactory("MockToken", admin);
    l1Token = await l1TokenFactory.deploy(l1DaiBridgeMock);

    //selector = getSelectorFromName("post_data");

    l1Aggregator = await l1AggregatorFactory.deploy(
      mockStarknetMessagingAddress,
      BigInt(l2Aggregator.address)
    );
    await l1Aggregator.deployed();
  });

  it("check deployment data", async () => {
    expect(await l1Aggregator.l2Aggregator()).to.be.eq(
      BigInt(l2Aggregator.address)
    );
  });

  it("add Starknet bridges", async () => {
    await l1Aggregator
      .connect(admin)
      .approveStarknetBridge(l1Token.address, l1DaiBridgeMock);
  });

  it("approve token pairs on l2 aggregator & set l1 aggregator", async () => {
    await l2user.invoke(l2Aggregator, "set_token_pairs", {
      l1_asset: BigInt(l1Token.address),
      l2_asset: BigInt(l2Token.address),
    });

    await l2user.invoke(l2Aggregator, "set_l1_aggregator", {
      _l1_aggregator: BigInt(l1Aggregator.address),
    });
  });

  it("check publish data", async () => {
    await l1Aggregator.connect(l1_user).sendData(l1Token.address);

    // flush message to l2
    const flushL1Response = await starknet.devnet.flush();
    const flushL1Messages = flushL1Response.consumed_messages.from_l1;
    // check assertion
    expect(flushL1Response.consumed_messages.from_l2).to.be.empty;
    expect(flushL1Messages).to.have.a.lengthOf(1);

    expectAddressEquality(
      flushL1Messages[0].args.from_address,
      l1Aggregator.address
    );
    expectAddressEquality(
      flushL1Messages[0].address,
      mockStarknetMessagingAddress
    );

    const collateral = uintFromParts(
      flushL1Messages[0].args.payload[1],
      flushL1Messages[0].args.payload[2]
    );
    const blockNumber = uintFromParts(
      flushL1Messages[0].args.payload[3],
      flushL1Messages[0].args.payload[4]
    );

    let { data } = await l2Aggregator.call("get_latest_reserves", {
      asset: BigInt(l2Token.address),
    });

    expect(data).to.deep.eq({
      value: { low: collateral, high: 0n },
      block_number: { low: blockNumber, high: 0n },
    });
  });
});

function expectAddressEquality(actual: string, expected: string) {
  expect(adaptAddress(actual)).to.equal(adaptAddress(expected));
}

function adaptAddress(address: string) {
  return "0x" + BigInt(address).toString(16);
}
