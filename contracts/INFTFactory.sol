// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTFactory {

    function getProtocolFeeMultiplier() external view returns (uint256);

    function getProtocolFeeReceiver() external view returns (address);

    function recordOwnedNFTs(address _owner, address _nft) external;

    function emitMint(address _ERC721Address, address _owner, uint256 _quantity) external;

    function emitBurn(address _ERC721Address, address _owner, uint256 _quantity) external;

    function emitTransfer(address _ERC721Address, address _from, address _to, uint256 _quantity) external;

    function isHasDiscountNFT(address _user) external view returns (bool);

}