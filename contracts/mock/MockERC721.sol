// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721Enumerable {

    constructor() ERC721("PASS", "PASS") {
    }

    function mint(address to, uint256 tokenId) external returns (bool) {
        _mint(to, tokenId);
        return true;
    }
}