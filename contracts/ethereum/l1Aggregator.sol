// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "./interfaces/IStarknetMessaging.sol";
import "./errors.sol";
import "./interfaces/IERC20.sol";

contract L1Aggregator {
    IStarknetMessaging public _messagingContract;
    address public owner;
    uint256 public l2Aggregator;
    // we assume for now a 1:1 relation between an asset and its bridge
    //TODO: an asset can be present on multiple Starknet bridges,
    //so approving all bridges where the token is collateralized should be considered in the future
    mapping(address => address[]) public bridges;
    mapping(address => mapping(uint => bool)) public assetPublishedForPeriod;

    // l1 handler function selector goes here ....
    uint256 public PUBLISH_DATA_SELECTOR = 0x10999;

    event PostedData(
        address indexed asset,
        address[] indexed bridge,
        uint256 totalCollateral,
        uint256 blockNumber
    );

    event NewBridgeApproved(address[] indexed _bridge, address indexed _asset);

    constructor(IStarknetMessaging _starknet, uint256 _l2Aggregator) {
        _messagingContract = _starknet;
        l2Aggregator = _l2Aggregator;
        owner = msg.sender;
    }

    /**
     *@param asset address
     */
    function sendData(address asset) public {
        // require(bridges[asset] != address(0), "no bridge found for the asset");
        if (bridges[asset].length == 0) revert AssetNotRegistered();
        // asset with zero address corresponds to wrapped ether on Starknet
        if (assetPublishedForPeriod[asset][block.number] == true) revert AlreadyPublished();

        uint256 availableCollateral;
        address[] memory _brigdes = bridges[asset];
        
        // loop through all bridge and get the total amount of asset
        for(uint256 i; i < _brigdes.length; i++) {
            unchecked {
                availableCollateral += asset == address(0) 
                    ? _brigdes[i].balance 
                    : IERC20(asset).balanceOf(_brigdes[i]); 
            }
            
        }

        // construct the payload to send 
        uint256[] memory payload = new uint256[](5);

        payload[0] = uint256(uint160(asset));

        (payload[1], payload[2]) = toSplitUint(availableCollateral);

        (payload[3], payload[4]) = toSplitUint(block.number);
        

        _messagingContract.sendMessageToL2(
            l2Aggregator,
            PUBLISH_DATA_SELECTOR,
            payload
        );

        assetPublishedForPeriod[asset][block.number] = true;

        emit PostedData(asset, bridges[asset], availableCollateral, block.number);
    }

    /**
    @dev add a new Ethereum <> Starknet bridge address
    @param  _asset address
    @param _bridge address[]
    */
    function approveStarknetBridge(address _asset, address[] memory _bridge)
        external
        onlyOwner
    {
        bridges[_asset] = _bridge;
        emit NewBridgeApproved(_bridge, _asset);
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
}
