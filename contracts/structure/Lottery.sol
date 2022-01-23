//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../const/LotteryStatus.sol";

struct Lottery {
    LotteryStatus status;
    uint256 startTime;
    uint256 endTime;
    uint256 ticketPrice;
    uint256 firstTicketId;
    uint256 lastTicketId;
    mapping (uint8 => uint256) winningCnt;
    uint256[7] prizeDivision;
    uint8[6] finalNumber;
    uint256 totalPrize;
}