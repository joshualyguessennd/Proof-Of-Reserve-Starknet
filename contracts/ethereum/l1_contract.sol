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

    function messageCancellationDelay() external returns (uint256);

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
    address public owner;
    address public keeper;
    uint256 public l2Contract;
    uint256 public countPublishers;

    // selector
    uint256 constant PUBLISH_SELECTOR =
        1140936987664331448615618258224699152095025896606603785909108379971040460607;

    struct DataInfo {
        address sender;
        uint256[] payload;
    }

    DataInfo[] public datas;
    address[] public publishers;

    mapping(address => DataInfo) public data;
    mapping(address => bool) public isAllowed;
    mapping(uint256 => address) public addressId;

    error NotOwner();
    error NotKeeper();
    error IsNotPublisher();
    event NewPublisher(address publisher);
    event MessageSentToLayer2();

    constructor(uint256 _l2Contract, address _starknet) {
        starkNet = _starknet;
        l2Contract = _l2Contract;
        owner = msg.sender;
    }

    function addNewPublisher(address _publisher) external onlyOwner {
        isAllowed[_publisher] = true;
        addressId[countPublishers] = _publisher;
        unchecked {
            countPublishers++;
        }
        emit NewPublisher(_publisher);
    }

    /**
     *@param asset_symbol symbol of asset
     *@param asset_name name of the asset
     *@param _account address that owns the asset
     *@param account_balance amount of asset address owns
     */
    function publishData(
        int256 asset_symbol,
        int256 asset_name,
        address _account,
        uint256 account_balance,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        if (isAllowed[msg.sender] != true) {
            revert IsNotPublisher();
        }
        uint256[] memory payload = new uint256[](10);
        uint256 sym = uint256(asset_symbol);
        uint256 asset = uint256(asset_name);
        uint256 address_account = uint256(uint160(_account));
        uint256 _r = uint256(r);
        uint256 _s = uint256(s);
        // send payload
        payload[0] = sym;
        payload[1] = asset;
        payload[2] = address_account;
        payload[3] = account_balance;
        (payload[4], payload[5]) = toSplitUint(_r);
        (payload[6], payload[7]) = toSplitUint(_s);
        // v
        payload[8] = v;
        payload[9] = uint256(uint160(address(msg.sender)));
        // store the data for the next round
        data[msg.sender] = DataInfo(msg.sender, payload);
    }

    /**
     *@dev this function sends the current data to the layer 2 and is called only by the keeper
     */
    function sendBatchTransaction() external onlyKeeper {
        uint256 i;
        for (i; i < countPublishers; i++) {
            address _publisher = addressId[i];
            uint256[] memory _payload = data[_publisher].payload;
            IStarknetMessaging(starkNet).sendMessageToL2(
                l2Contract,
                PUBLISH_SELECTOR,
                _payload
            );
        }
        emit MessageSentToLayer2();
    }

    /**
     *@notice split uint
     */
    function toSplitUint(uint256 value)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 low = value & ((1 << 128) - 1);
        uint256 high = value >> 128;
        return (low, high);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyKeeper() {
        if (msg.sender != keeper) {
            revert NotKeeper();
        }
        _;
    }
}
