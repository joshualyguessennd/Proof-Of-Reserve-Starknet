// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "./interfaces/Interface.sol";
import "./errors.sol";

contract L1_CONTRACT {
    address public starkNet;
    address public owner;
    address public keeper;
    address[] public publishers;
    uint256 public l2Contract;
    uint256 public countPublishers;

    // selector
    uint256 public SELECTOR;

    // data type to store the information to send for the round
    struct DataInfo {
        address sender;
        uint256[] payload;
    }

    // each publisher has a data which is updated continuously
    mapping(address => DataInfo) public data;
    mapping(address => bool) public isAllowed;
    mapping(uint256 => address) public addressId;

    event NewPublisher(address publisher);
    event MessageSentToLayer2();

    constructor(
        address _starknet,
        uint256 _l2Contract,
        uint256 _SELECTOR
    ) {
        starkNet = _starknet;
        l2Contract = _l2Contract;
        owner = msg.sender;
        SELECTOR = _SELECTOR;
    }

    /**
    @dev add a new publisher address
    @param _publisher new address allows to post data 
    */
    function addNewPublisher(address _publisher) external onlyOwner {
        isAllowed[_publisher] = true;
        addressId[countPublishers] = _publisher;
        unchecked {
            countPublishers++;
        }
        emit NewPublisher(_publisher);
    }

    /**
    @dev add a new publisher address
    @param _keeper new address allows to post data 
    */
    function addNewKeeper(address _keeper) external onlyOwner {
        keeper = _keeper;
    }

    /**
     *@param asset_symbol symbol of asset
     *@param asset_name name of the asset
     *@param _account address that owns the asset
     *@param account_balance amount of asset address owns
     */
    function publishData(
        uint256 asset_symbol,
        uint256 asset_name,
        address _account,
        uint256 account_balance,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        if (isAllowed[msg.sender] != true) {
            revert IsNotPublisher();
        }
        uint256[] memory payload = new uint256[](11);
        uint256 sym = asset_symbol;
        uint256 asset = asset_name;
        uint256 address_account = uint256(uint160(_account));
        uint256 _r = uint256(r);
        uint256 _s = uint256(s);
        // send payload
        payload[0] = sym;
        payload[1] = asset;
        payload[2] = address_account;
        payload[3] = account_balance;
        payload[4] = block.timestamp;
        (payload[5], payload[6]) = toSplitUint(_r);
        (payload[7], payload[8]) = toSplitUint(_s);
        // v
        payload[9] = v;
        payload[10] = uint256(uint160(address(msg.sender)));
        // store the data for the next round
        data[msg.sender] = DataInfo(msg.sender, payload);
    }

    /**
     *@dev this function sends the current data to the layer 2 and is called only by the keeper
     */
    function sendBatchTransaction() external onlyKeeper {
        for (uint256 i; i < countPublishers; i++) {
            address _publisher = addressId[i];
            uint256[] memory _payload = data[_publisher].payload;
            // send the data collected by all the publishers, the starknet contract will verify the signature
            // if a message is corrupted or false the transaction will failed at the starknet level
            IStarknetMessaging(starkNet).sendMessageToL2(
                l2Contract,
                SELECTOR,
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
