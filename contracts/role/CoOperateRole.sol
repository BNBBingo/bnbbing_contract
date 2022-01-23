//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CoOperateRole is Ownable {
    using SafeMath for uint256;

    address private aOperatorAddress;
    address private bOperatorAddress;

    uint256 private aOperatorDivision; // 5 = 50%

    constructor(address aAddress, address bAddress) {
        aOperatorAddress = aAddress;
        bOperatorAddress = bAddress;
    }

    /**
     * @dev modifier of operator validation
     */
    modifier onlyOperator() {
        require(
            msg.sender == aOperatorAddress || msg.sender == bOperatorAddress,
            "Not operator"
        );
        _;
    }

    /**
     * @dev set A operator address
     * @param aAddress A operator address
     */
    function setAOperatorAddress(address aAddress) public {
        require(aOperatorAddress == msg.sender, "Incorrect operator");

        aOperatorAddress = aAddress;
    }

    /**
     * @dev set B operator address
     * @param bAddress B operator address
     */
    function setBOperatorAddress(address bAddress) public {
        require(bOperatorAddress == msg.sender, "Incorrect operator");

        bOperatorAddress = bAddress;
    }

    /**
     * @dev set A operator's division value
     * @param division A operator's division value
     */
    function setAOperatorDivision(uint256 division) public onlyOwner {
        require(division < 10, "Division can't be 100%");

        aOperatorDivision = division;
    }

    function withdraw(uint256 amount) public onlyOperator {
        require(amount != 0, "Amount can't be zero");

        uint256 aAmount = amount.mul(aOperatorDivision).div(10);
        uint256 bAmount = amount.sub(aAmount);

        payable(aOperatorAddress).transfer(aAmount);
        payable(bOperatorAddress).transfer(bAmount);
    }
}