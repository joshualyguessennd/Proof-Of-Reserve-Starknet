// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "./interfaces/Interface.sol";

contract Setter {
    address public starkNet;
    uint256 public l2Contract;
    uint256 PUBLISH_SELECTOR =
        1140936987664331448615618258224699152095025896606603785909108379971040460607;

    constructor(uint256 _l2Contract, address _starknet) {
        starkNet = _starknet;
        l2Contract = _l2Contract;
    }

    function set(uint256 _x) public returns (bool) {
        uint256[] memory payload = new uint256[](1);
        payload[0] = _x;

        // IStarknetMessaging(starkNet).sendMessageToL2(
        //     l2Contract,
        //     PUBLISH_SELECTOR,
        //     payload
        // );
        (bool success, bytes memory data) = starkNet.call(
            abi.encodeWithSignature(
                "sendMessageToL2(uint256, uint256, uint256[])",
                l2Contract,
                PUBLISH_SELECTOR,
                payload
            )
        );
        return success;
    }
}
