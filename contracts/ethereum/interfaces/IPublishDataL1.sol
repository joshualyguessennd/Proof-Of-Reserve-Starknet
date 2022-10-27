// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

interface IPublishDataL1 {
    function publishData() external;

    function sendBatchTransaction() external;
}
