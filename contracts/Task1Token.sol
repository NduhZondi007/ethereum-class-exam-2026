// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./ERC20.sol";

// =============================================================================
// TASK 1. One thing to fill in.
// You deploy this contract twice, once for token A and once for token B.
// =============================================================================

contract ExamToken is ERC20 {
    constructor(string memory name_, string memory symbol_, uint256 initialSupply_)
        ERC20(name_, symbol_, 18)
    {
        // TODO 1.1 --------------------------------------------------------
        // Give the whole initial supply to whoever deploys this token.
        _mint(msg.sender, initialSupply_);
    }
}
