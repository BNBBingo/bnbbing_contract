//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

struct Ticket {
    bool claimed;
    uint8[6] ticketNumber;
    uint256 lotteryId;
}