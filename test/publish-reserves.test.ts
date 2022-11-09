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

    //TODO: deploy l1 & l2 tokens & bridges mocks for testing

    const l2AggregatorFactory = await starknet.getContractFactory(
      "contracts/starknet/l2Aggregator"
    );

    l2Aggregator = await l2AggregatorFactory.deploy({
      admin: l2user.starknetContract.address,
    });

    l1AggregatorFactory = await ethers.getContractFactory(
      "l1Aggregator",
      admin
    );
    selector = getSelectorFromName("post_data");
    console.log("selector:", selector);

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
    await l1Aggregator.connect(l1_user).approveStarknetBridge(0, 0);
  });

  it("approve token pairs on l2 aggregator", async () => {
    //set_token_pairs(..,..)
  });

  it("check publish data", async () => {
    // expect it to fail  with is Not Signer
    await l1Aggregator.connect(l1_user).sendData("l1Token.address");

    // flush message to l2
    const flushL1Response = await starknet.devnet.flush();
    const flushL1Messages = flushL1Response.consumed_messages.from_l1;
    // check assertion
    expect(flushL1Response.consumed_messages.from_l2).to.be.empty;
    expect(flushL1Messages).to.have.a.lengthOf(2);

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

    let result = await l2Aggregator.call("latest_reserves", { asset: "..." });

    expect(result).to.be.eq({
      value: { low: collateral, high: 0n },
      block_number: blockNumber,
    });
  });
});

function expectAddressEquality(actual: string, expected: string) {
  expect(adaptAddress(actual)).to.equal(adaptAddress(expected));
}

function adaptAddress(address: string) {
  return "0x" + BigInt(address).toString(16);
}
