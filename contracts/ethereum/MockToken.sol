// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20("MockToken", "MT") {
    constructor(address recipient) {
        _mint(recipient, 100_000e18);
    }
}
