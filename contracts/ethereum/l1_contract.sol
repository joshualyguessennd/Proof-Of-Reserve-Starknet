// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

interface IStarknetMessagingEvents {
    // This event needs to be compatible with the one defined in Output.sol.
    event LogMessageToL1(
        uint256 indexed fromAddress,
        address indexed toAddress,
        uint256[] payload
    );

    // An event that is raised when a message is sent from L1 to L2.
    event LogMessageToL2(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L2 to L1 is consumed.
    event ConsumedMessageToL1(
        uint256 indexed fromAddress,
        address indexed toAddress,
        uint256[] payload
    );

    // An event that is raised when a message from L1 to L2 is consumed.
    event ConsumedMessageToL2(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L1 to L2 Cancellation is started.
    event MessageToL2CancellationStarted(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L1 to L2 is canceled.
    event MessageToL2Canceled(
        address indexed fromAddress,
        uint256 indexed toAddress,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );
}

interface IStarknetMessaging is IStarknetMessagingEvents {
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

    /**
     *@dev publish data to layer 2
     *@param symbol, symbol of asset (exple DAI, WETH)
     *@param name, name of asset(Ether etc)
     *@param owner, address of account who owns the asset
     *@param balance, balance of asset
     *@param r,
     *@param s,
     */

    function publishFromL1(
        uint256 symbol,
        uint256 name,
        address owner,
        uint256 balance,
        uint256 r,
        uint256 s
    ) public {
        uint256[] memory payload = new uint256[](11);
        payload[0] = uint256(uint160(address(this)));
        payload[1] = symbol;
        payload[2] = name;
        payload[3] = uint256(uint160(owner));
        payload[4] = balance;
        (payload[5], payload[6]) = toSplitUint(r);
        (payload[7], payload[8]) = toSplitUint(s);
        payload[9] = 0; //v
        payload[10] = uint256(uint160(address(this)));

        IStarknetMessaging(starkNet).sendMessageToL2(
            l2Contract,
            PUBLISH_SELECTOR,
            payload
        );
    }

    // split uint to low and high part
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
