// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

interface StarkNetLike {
    function sendMessageToL2(
        uint256 to,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    function consumeMessageFromL2(uint256 from, uint256[] calldata payload)
        external
        returns (bytes32);

    function startL1ToL2MessageCancellation(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external;

    function cancelL1ToL2Message(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function balanceOf(address account) external view returns (uint256);
}

contract L1_CONTRACT {
    address public starkNet;
    uint256 public l2Contract;

    // selector
    uint256 constant PUBLISH_SELECTOR =
        1140936987664331448615618258224699152095025896606603785909108379971040460607;

    constructor(uint256 _l2Contract, address _starknet) {
        starkNet = _starknet;
        l2Contract = _l2Contract;
    }

    function publishFromL1() public {
        uint256[] memory payload = new uint256[](11);
        payload[0] = uint256(uint160(address(this)));
        payload[1] = 10703902247957299200;
        payload[2] = 4627187504670310400;
        payload[3] = 216172782113783808;
        payload[4] = 4412482;
        payload[5] = 332795217045463323013001404630688413274;
        payload[6] = 146142335783970907433265090013769735112;
        payload[7] = 303370686640270218425857983888853860003;
        payload[8] = 64365439344860771410702511821974968;
        payload[9] = 0;
        payload[10] = 761466874539515783303110363281120649054760260892;

        StarkNetLike(starkNet).sendMessageToL2(
            l2Contract,
            PUBLISH_SELECTOR,
            payload
        );
    }

    function toSplitUint(uint256 value)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 low = value & ((1 << 128) - 1);
        uint256 high = value >> 128;
        return (low, high);
    }
}
