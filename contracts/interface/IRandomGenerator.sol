//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract IRandomGenerator {
    /**
     * @dev generate random 6 values
     * Every random values are different each other and in the range of [0~32]
     * @return 
     */
    function generateWiningNumber() external virtual view returns(uint8[6] memory);
}