// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract ERC721AEnumerable is ERC721AUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private holders;

    function __ERC721AEnumerable_init(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        __ERC721A_init(name_, symbol_);
    }

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal _ownedTokensIndex;

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < ERC721AUpgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function tokenIdsOfOwner(address owner) public view virtual returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](ERC721AUpgradeable.balanceOf(owner));
        for(uint256 i = 0; i < ERC721AUpgradeable.balanceOf(owner); ++i){
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    function getHoldersCount() public view returns (uint256) {
        return holders.length();
    }

    function getAllHolders() public view returns (address[] memory) {
        uint256 length = holders.length();
        address[] memory holdersArray = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            holdersArray[i] = holders.at(i);
        }

        return holdersArray;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        uint256 tokenId = startTokenId;
        if (from == to) {return;}

        //If it's mint
        if (from == address(0)) {
            uint256 length = ERC721AUpgradeable.balanceOf(to);

            if (length == 0) holders.add(to);
            
            for(uint256 i = _nextTokenId(); i < _nextTokenId() + quantity; ++i){
                _ownedTokens[to][length] = i;
                _ownedTokensIndex[i] = length;
                length++;
            }

        } 

        // If it's burn
        if (to == address(0)) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
            if (ERC721AUpgradeable.balanceOf(from) == 1) holders.remove(from);
        }

        // If it's a transfer
        if (from != address(0) && to != address(0)) {
            if (ERC721AUpgradeable.balanceOf(to) == 0) holders.add(to);

            _removeTokenFromOwnerEnumeration(from, tokenId);
            _addTokenToOwnerEnumeration(to, tokenId);

            if (ERC721AUpgradeable.balanceOf(from) == 1) holders.remove(from);
            _emitTransfer(from, to, quantity);
        }
    }


    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        uint256 length = ERC721AUpgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) internal {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721AUpgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _emitTransfer(address from, address to, uint256 quantity) internal virtual {}

}