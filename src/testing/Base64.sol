// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

library Base64 {
    bytes private constant _BASE64_URL_CHARS =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function decode(string memory input) internal pure returns (bytes memory) {
        bytes memory data = bytes(input);
        uint256 len = data.length;

        require(len % 4 == 0, "Invalid input length");

        uint256 decodedLen = (len / 4) * 3;
        if (data[len - 1] == "=") decodedLen--; // Padding characters are optional
        if (data[len - 2] == "=") decodedLen--; // Padding characters are optional

        bytes memory decoded = new bytes(decodedLen);

        uint256 j = 0;
        uint256 pad = 0;
        for (uint256 i = 0; i < len; i += 4) {
            uint256 accumulator = 0;
            for (uint256 k = 0; k < 4; k++) {
                if (data[i + k] == "=") {
                    pad++;
                    accumulator <<= 6;
                } else {
                    uint256 index = _getBase64CharIndex(data[i + k]);
                    require(index < 64, "Invalid character");
                    accumulator = (accumulator << 6) | index;
                }
            }

            decoded[j++] = bytes1(uint8((accumulator >> 16) & 0xFF));
            if (pad < 2)
                decoded[j++] = bytes1(uint8((accumulator >> 8) & 0xFF));
            if (pad < 1) decoded[j++] = bytes1(uint8(accumulator & 0xFF));
        }

        return decoded;
    }

    function _getBase64CharIndex(bytes1 char) private pure returns (uint256) {
        for (uint256 i = 0; i < 64; i++) {
            if (_BASE64_URL_CHARS[i] == char) return i;
        }
        revert("Character not in Base64 character set");
    }
}
