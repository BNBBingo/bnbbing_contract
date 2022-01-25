//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./role/CoOperateRole.sol";
import "./role/CallerRole.sol";
import "./structure/Lottery.sol";
import "./structure/Ticket.sol";
import "./const/LotteryStatus.sol";
import "./interface/IRandomGenerator.sol";

contract BNBbingo is CoOperateRole, CallerRole, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public ticketPrice;

    uint256 public currentLotteryId = 0;
    mapping (uint256 => Lottery) public lotteries;
    
    uint256 public currentTicketId = 0;
    mapping (uint256 => Ticket) public tickets;

    uint256[] public prizeDivision = [1, 2, 10, 17, 25, 40];
    uint256 public systemDivision = 5;

    mapping (uint8 => mapping (bytes => uint256)) public brackets;

    address public randomGenerator;

    uint256 public currentPrize = 0;

    modifier roundStopped() {
        require(
            lotteries[currentLotteryId].status == LotteryStatus.CLOSE,
            "Round is not closed"
        );
        _;
    }

    modifier roundClaimable() {
        require(
            lotteries[currentLotteryId].status == LotteryStatus.CLAIMABLE,
            "Round is not claimable"
        );
        _;
    }

    modifier roundStarted() {
        require(
            lotteries[currentLotteryId].status == LotteryStatus.OPEN,
            "Round is not started"
        );
        _;
    }

    /**
     * @dev Event of ticket buy
     * @param buyer ticket buyer
     * @param ticketId ticket id
     */
    event BuyTicket(address indexed buyer, uint256 indexed ticketId, uint8[6] indexed ticketNums);

    /**
     * @dev Event of starting round
     * @param round round id
     */
    event RoundStarted(uint256 indexed round);

    /**
     * @dev Event of Claiming round
     * @param round round id
     */
    event RoundClaimed(uint256 indexed round);

    /**
     * @dev Event of Claiming ticket
     * @param ticketId ticket id
     */
    event ClaimTicket(uint256 indexed ticketId);
    
    constructor(
        address aAddress,
        address bAddress,
        uint256 _ticketPrice,
        address generator
    ) CoOperateRole(aAddress, bAddress) {
        ticketPrice = _ticketPrice;

        randomGenerator = generator;
    }

    /**
     * @dev set ticket price
     * @param price ticket price
     */
    function setTicketPrice(uint256 price) public onlyOwner {
        require(price != 0, "Ticket price can't be zero");

        ticketPrice = price;
    }

    /**
     * @dev set PrizeDivision rate;
     * @param divisions division rates;
     */
    function setPrizeDivision(uint256[6] calldata divisions) 
    public onlyOwner 
    {
        uint256 divisionSum = 
            divisions[0] + divisions[1] + divisions[2] +
            divisions[3] + divisions[4] + divisions[5];
        
        require(divisionSum < 100, "Percentage overflow");
        
        prizeDivision[0] = divisions[0];
        prizeDivision[1] = divisions[1];
        prizeDivision[2] = divisions[2];
        prizeDivision[3] = divisions[3];
        prizeDivision[4] = divisions[4];
        prizeDivision[5] = divisions[5];
        systemDivision = 100 - divisionSum;
    }

    /**
     * @dev stop the round
     */
    function forceStopRound() public onlyOwner roundStarted {
        require(
            lotteries[currentLotteryId].firstTicketId == 0,
            "Bought ticket exists"
        );

        lotteries[currentLotteryId].status = LotteryStatus.CLOSE;
    }

    /**
     * @dev start the round
     */
    function startRound() public onlyOwner roundClaimable {
        currentLotteryId++;

        lotteries[currentLotteryId].status = LotteryStatus.OPEN;
        lotteries[currentLotteryId].startTime = block.timestamp;
        lotteries[currentLotteryId].ticketPrice = ticketPrice;
        lotteries[currentLotteryId].prizeDivision = 
            [
                prizeDivision[0],
                prizeDivision[1],
                prizeDivision[2],
                prizeDivision[3],
                prizeDivision[4],
                prizeDivision[5],
                systemDivision
            ];
        
        emit RoundStarted(currentLotteryId);
    }

    function buyTicket(uint8[6] memory numbers) 
    public payable roundStarted nonReentrant 
    {
        require(
            msg.value == lotteries[currentLotteryId].ticketPrice,
            "Incorrect ticket price"
        );

        require(
            (
                numbers[0] < numbers[1] &&
                numbers[1] < numbers[2] &&
                numbers[2] < numbers[3] &&
                numbers[4] < numbers[5]
            ),
            "Not sorted"
        );

        for (uint8 i1 = 0; i1 < 6; i1++) {
            for (uint8 i2 = i1 + 1; i2 < 6; i2++) {
                for (uint8 i3 = i2 + 1; i3 < 6; i3++) {
                    for (uint8 i4 = i3 + 1; i4 < 6; i4++) {
                        for (uint8 i5 = i4 + 1; i5 < 6; i5++) {
                            for (uint8 i6 = i5 + 1; i6 < 6; i6++) {
                                brackets[6][
                                    abi.encodePacked(
                                        numbers[i1],
                                        numbers[i2],
                                        numbers[i3],
                                        numbers[i4],
                                        numbers[i5],
                                        numbers[i6]
                                    )
                                ]++;
                            }
                            brackets[5][
                                abi.encodePacked(
                                    numbers[i1],
                                    numbers[i2],
                                    numbers[i3],
                                    numbers[i4],
                                    numbers[i5]
                                )
                            ]++;
                        }
                        brackets[4][
                            abi.encodePacked(
                                numbers[i1],
                                numbers[i2],
                                numbers[i3],
                                numbers[i4]
                            )
                        ]++;
                    }
                    brackets[3][
                        abi.encodePacked(numbers[i1], numbers[i2], numbers[i3])
                    ]++;
                }
                brackets[2][
                    abi.encodePacked(numbers[i1], numbers[i2])
                ]++;
            }
            brackets[1][
                abi.encodePacked(numbers[i1])
            ]++;
        }

        currentTicketId++;

        tickets[currentTicketId] = Ticket({
            claimed: false,
            ticketNumber: numbers,
            lotteryId: currentLotteryId,
            buyer: msg.sender
        });

        if (lotteries[currentLotteryId].firstTicketId == 0) {
            lotteries[currentLotteryId].firstTicketId = currentTicketId;
        }

        lotteries[currentLotteryId].lastTicketId = currentTicketId;

        currentPrize += ticketPrice;

        emit BuyTicket(msg.sender, currentTicketId, numbers);
    }

    /**
     * @dev stop the round
     */
    function stopRound() public onlyOwner roundStarted {
        uint8[6] memory winningNumber = 
            IRandomGenerator(randomGenerator).generateWiningNumber();

        lotteries[currentLotteryId].status = LotteryStatus.CLOSE;
        lotteries[currentLotteryId].finalNumber = winningNumber;
        lotteries[currentLotteryId].endTime = block.timestamp;
    }

    /**
     * @dev calculate winning ticket and prizes
     */
    function drawClaimableRound() public onlyOwner roundStopped {
        uint8[6] memory winningNumber = lotteries[currentLotteryId].finalNumber;

        for (uint8 i1 = 0; i1 < 6; i1++) {
            for (uint8 i2 = i1 + 1; i2 < 6; i2++) {
                for (uint8 i3 = i2 + 1; i3 < 6; i3++) {
                    for (uint8 i4 = i3 + 1; i4 < 6; i4++) {
                        for (uint8 i5 = i4 + 1; i5 < 6; i5++) {
                            for (uint8 i6 = i5 + 1; i6 < 6; i6++) {
                                lotteries[currentLotteryId].winningCnt[6] += 
                                    brackets[6][
                                        abi.encodePacked(
                                            winningNumber[i1],
                                            winningNumber[i2],
                                            winningNumber[i3],
                                            winningNumber[i4],
                                            winningNumber[i5],
                                            winningNumber[i6]
                                        )
                                    ];
                            }
                            lotteries[currentLotteryId].winningCnt[5] += 
                                brackets[5][
                                    abi.encodePacked(
                                        winningNumber[i1],
                                        winningNumber[i2],
                                        winningNumber[i3],
                                        winningNumber[i4],
                                        winningNumber[i5]
                                    )
                                ];
                        }
                        lotteries[currentLotteryId].winningCnt[4] += 
                            brackets[4][
                                abi.encodePacked(
                                    winningNumber[i1],
                                    winningNumber[i2],
                                    winningNumber[i3],
                                    winningNumber[i4]
                                )
                            ];
                    }
                    lotteries[currentLotteryId].winningCnt[3] += 
                        brackets[3][
                            abi.encodePacked(
                                winningNumber[i1],
                                winningNumber[i2],
                                winningNumber[i3]
                            )
                        ];
                }
                lotteries[currentLotteryId].winningCnt[2] += 
                    brackets[2][
                        abi.encodePacked(
                            winningNumber[i1],
                            winningNumber[i2]
                        )
                    ];
            }
            lotteries[currentLotteryId].winningCnt[1] += 
                brackets[1][abi.encodePacked(winningNumber[i1])];
        }

        lotteries[currentLotteryId].winningCnt[5] -= 
            lotteries[currentLotteryId].winningCnt[6] * 6;
        lotteries[currentLotteryId].winningCnt[4] -= 
            lotteries[currentLotteryId].winningCnt[6] * 15 + 
            lotteries[currentLotteryId].winningCnt[5] * 5;
        
        lotteries[currentLotteryId].winningCnt[3] -=
            lotteries[currentLotteryId].winningCnt[6] * 20 +
            lotteries[currentLotteryId].winningCnt[5] * 10 +
            lotteries[currentLotteryId].winningCnt[4] * 4;

        lotteries[currentLotteryId].winningCnt[2] -=
            lotteries[currentLotteryId].winningCnt[6] * 15 +
            lotteries[currentLotteryId].winningCnt[5] * 10 +
            lotteries[currentLotteryId].winningCnt[4] * 6 +
            lotteries[currentLotteryId].winningCnt[3] * 3;

        lotteries[currentLotteryId].winningCnt[1] -=
            lotteries[currentLotteryId].winningCnt[6] * 6 +
            lotteries[currentLotteryId].winningCnt[5] * 5 +
            lotteries[currentLotteryId].winningCnt[4] * 4 +
            lotteries[currentLotteryId].winningCnt[3] * 3 +
            lotteries[currentLotteryId].winningCnt[2] * 2;
        
        lotteries[currentLotteryId].totalPrize = currentPrize;
        
        currentPrize = 0;
        for (uint8 i = 1; i <= 6; i++) {
            if (lotteries[currentLotteryId].winningCnt[i] == 0) {
                currentPrize += 
                    lotteries[currentLotteryId].totalPrize
                    .mul(lotteries[currentLotteryId].prizeDivision[i - 1])
                    .div(100);
            }
        }

        lotteries[currentLotteryId].status = LotteryStatus.CLAIMABLE;

        emit RoundClaimed(currentLotteryId);
    }

    /**
     * @dev get prize with ticket
     * @param ticketId the ticket id
     */
    function claimTicket(uint256 ticketId) public {
        require(tickets[ticketId].buyer == msg.sender, "Not ticket owner");
        require(!tickets[ticketId].claimed, "The ticket was already claimed");
        uint256 prize = getPrize(ticketId);
        require(prize != 0, "The ticket with no prize");
        tickets[ticketId].claimed = true;
        payable(msg.sender).transfer(prize);

        emit ClaimTicket(ticketId);
    }

    /**
     * @dev calculate prize with ticket
     * @param ticketId the ticket id
     */
    function getPrize(uint256 ticketId) public view returns (uint256) {
        require(tickets[ticketId].lotteryId != 0, "Not exist ticket");      
        require(
            (
                tickets[ticketId].lotteryId < currentLotteryId ||
                lotteries[currentLotteryId].status == LotteryStatus.CLAIMABLE
            ),
            "Not claimable yet"
        );

        Lottery storage lottery = lotteries[tickets[ticketId].lotteryId];
        uint8[6] memory winningNumber = lottery.finalNumber;
        uint8[6] memory ticketNumber = tickets[ticketId].ticketNumber;
        uint8 winningCnt = 0;

        for (uint8 i = 0; i < 6; i++) {
            for (uint8 j = 0; j < 6; j++) {
                if (winningNumber[j] == 0) {
                    continue;
                }

                if (ticketNumber[i] == winningNumber[j]) {
                    winningCnt++;
                    winningNumber[j] = 0;
                    break;
                }
            }
        }

        uint256 totalPrize = 
            lottery.ticketPrice.mul(
                lottery.lastTicketId.sub(lottery.firstTicketId).add(1)
            );
        uint256 prize = 
            totalPrize.mul(lottery.prizeDivision[winningCnt - 1])
            .div(100).div(lottery.winningCnt[winningCnt]);

        return prize;
    }

    /**
     * @dev Return winning number of lottery round
     * @param roundId Round ID
     */
    function getLotteryFinalNumber(uint256 roundId) public view returns(uint8[6] memory) {
        return lotteries[roundId].finalNumber;
    }

    /**
     * @dev Return winning cnt of lottery
     * @param roundId Round ID
     * @param equalNumbers index of lottery winning Cnt
     */
    function getLotteryWinningCnt(uint256 roundId, uint8 equalNumbers)
    public view returns(uint256) {
        return lotteries[roundId].winningCnt[equalNumbers];
    }

    /**
     * @dev Return price division of lottery round
     * @param roundId Round ID
     */
    function getLotteryPrizeDivision(uint256 roundId) public view returns(uint256[7] memory) {
        return lotteries[roundId].prizeDivision;
    }
}