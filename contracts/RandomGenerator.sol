//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interface/IRandomGenerator.sol";

contract RandomGenerator is IRandomGenerator {
    /**
     * @dev generate random seed value
     * @return uint256 return random seed value
     */
    function rand() private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            (
                uint256(keccak256(abi.encodePacked(block.coinbase))) /
                block.timestamp
            ) + block.gaslimit + 
            (
                uint256(keccak256(abi.encodePacked(msg.sender))) /
                block.timestamp
            ) + block.number
        )));

        return seed;
    }

    /**
     * @dev generate random 6 values
     * Every random values are different each other and in the range of [0~32]
     * @return 
     */
    function generateWiningNumber() 
    external override view returns(uint8[6] memory) {
        uint256 seed = rand();
        
        uint8 cnt = 0;
        uint8[] memory set = new uint8[](32);

        for (uint8 i = 0; i < 32; i++) {
            set[i] = i + 1;
        }

        uint8[6] memory ret;

        while (cnt < 6) {
            uint256 index = seed % (32 - cnt);

            ret[cnt] = set[index];
            set[index] = set[31 - cnt];

            seed = seed / (32 - cnt);
            cnt++;
        }

        return ret;
    }
}