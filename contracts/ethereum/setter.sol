// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "./interfaces/Interface.sol";

contract Setter {
    address public starkNet;
    uint256 public l2Contract;
    uint256 PUBLISH_SELECTOR;

    constructor(
        uint256 _l2Contract,
        address _starknet,
        uint256 selector
    ) {
        starkNet = _starknet;
        l2Contract = _l2Contract;
        PUBLISH_SELECTOR = selector;
    }

    function set(uint256 _x) public {
        uint256[] memory payload = new uint256[](1);
        payload[0] = _x;

        IStarknetMessaging(starkNet).sendMessageToL2(
            l2Contract,
            PUBLISH_SELECTOR,
            payload
        );
    }
}
