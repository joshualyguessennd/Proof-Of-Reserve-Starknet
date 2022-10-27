// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "./interfaces/IPublishDataL1.sol";
import "./errors.sol";

contract Keeper {
    address public registryContract;
    address public owner;
    uint256 public cooldown;
    uint256 public lastTimeStamp;

    event CooldownSet(uint256 coolDown);
    event RegistryContractSet(address indexed registry);

    constructor(uint256 _cooldown, address registry) {
        cooldown = _cooldown;
        registryContract = registry;
        owner = msg.sender;
    }

    function setCoolDown(uint256 _cooldown) public onlyOwner {
        cooldown = _cooldown;
        emit CooldownSet(_cooldown);
    }

    function setRegistryContract(address _registryContract) public onlyOwner {
        registryContract = _registryContract;
        emit RegistryContractSet(_registryContract);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > cooldown;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external {
        address l1Contract = abi.decode(performData, (address));
        lastTimeStamp = block.timestamp;
        IPublishDataL1(l1Contract).sendBatchTransaction();
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }
}
