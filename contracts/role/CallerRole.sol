//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";

contract CallerRole {
    modifier onlyWallet {
        require(!Address.isContract(msg.sender), "Caller is contract address");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }
}
