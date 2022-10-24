import { expect } from "chai";
import hre, { ethers, starknet } from "hardhat";
import { StarknetContract, HardhatUserConfig } from "hardhat/types";
import config from "../hardhat.config";
import { Contract, ContractFactory } from "ethers";
import { Account } from "hardhat/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { getSelectorFromName } from "starknet/dist/utils/hash";

const ASSET_SYMBOL = 10703902247957299200n;
const ASSET_NAME = 4627187504670310400n;
const ADDRESS_ACCOUNT = "0x0000000000000000000000000300000000000000";
const BALANCE = 4412482n;
const PUBLIC_KEY = 761466874539515783303110363281120649054760260892n
const R = "0x6df1fd74c3334fa829febec3cb439bc8fa5e0702bf50260074355e21ac2d365a";
const S = "0x000c65760f5886d4947a60caa12e6db8e43b11a7b063541dcc5e938cdd687ea3";
const V = 0;

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
      "contracts/starknet/proof_reserve"
    );

    l2Contract = await l2ContractFactory.deploy({
      admin: l2user.starknetContract.address,
      publisher: BigInt(761466874539515783303110363281120649054760260892n),
    });

    l1ContractFactory = await ethers.getContractFactory("PublishDataL1", admin);
    selector = getSelectorFromName("post_data");
    l1Contract = await l1ContractFactory.deploy(
      mockStarknetMessagingAddress,
      BigInt(l2Contract.address),
      BigInt(selector)
    );
    await l1Contract.deployed();
  });

  it("check deployment data", async () => {
    const _selector = await l1Contract.SELECTOR();

    expect(_selector).to.be.eq(BigInt(selector));
    expect(await l1Contract.l2Contract()).to.be.eq(BigInt(l2Contract.address));
    expect(await l1Contract.countPublishers()).to.be.eq(0);
    // wrong access
    expect(l1Contract.connect(l1_user).addNewPublisher(admin.address)).to
      .rejected;

    await l1Contract.connect(admin).addNewPublisher(admin.address);
    expect(await l1Contract.countPublishers()).to.be.eq(1);
  });

  it("check publish data", async () => {
    await l1Contract.connect(admin).addNewPublisher(admin.address);
    // expect it to fail  with is Not Signer
    expect(
      l1Contract
        .connect(l1_user)
        .publishData(
          BigInt(ASSET_SYMBOL),
          BigInt(ASSET_NAME),
          ADDRESS_ACCOUNT,
          BigInt(BALANCE),
          R,
          S,
          V
        )
    ).to.rejected;

    console.log(l1Contract.address);


    // add l1 contract as publisher
    await l2user.invoke(l2Contract, "add_publisher", {
      new_publisher: l1Contract.address,
    });

    await l1Contract
      .connect(admin)
      .publishData(
        BigInt(ASSET_SYMBOL),
        BigInt(ASSET_NAME),
        ADDRESS_ACCOUNT,
        BigInt(BALANCE),
        BigInt(PUBLIC_KEY),
        R,
        S,
        V
      );

    await l1Contract.connect(admin).addNewKeeper(admin.address);

    await l1Contract.connect(admin).sendBatchTransaction();

    // flush message to l2
    const flushL1Response = await starknet.devnet.flush();
    const flushL1Messages = flushL1Response.consumed_messages.from_l1;
    // check assertion
    expect(flushL1Response.consumed_messages.from_l2).to.be.empty;
    expect(flushL1Messages).to.have.a.lengthOf(2);

    expectAddressEquality(flushL1Messages[0].args.from_address, l1Contract.address);
    expectAddressEquality(
      flushL1Messages[0].address,
      mockStarknetMessagingAddress
    );
    // // verify root hash
    const timestamp = BigInt(flushL1Messages[0].args.payload[4]);
    const address_account_felt = BigInt(flushL1Messages[0].args.payload[2]);

    let root = await l2Contract.call("get_root", {
      public_key: address_account_felt,
      asset: BigInt(ASSET_NAME),
      balance: BigInt(BALANCE),
      timestamp: timestamp,
    });
    let result = await l2Contract.call("verify_balance", {
      leaf: 0,
      merkle_root: root.res,
      proof: [
        address_account_felt,
        BigInt(ASSET_NAME),
        BigInt(BALANCE),
        timestamp,
      ],
    });

    expect(BigInt(1)).to.be.eq(result.res);
  });
});

function expectAddressEquality(actual: string, expected: string) {
  expect(adaptAddress(actual)).to.equal(adaptAddress(expected));
}

function adaptAddress(address: string) {
  return "0x" + BigInt(address).toString(16);
}