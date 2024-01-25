// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./INFTFactory.sol";

import {INFTImplementationETH} from "./NFTImplementationETH.sol";
import {INFTImplementationERC20} from "./NFTImplementationERC20.sol";

contract NFTFactory is INFTFactory, OwnableUpgradeable, UUPSUpgradeable {
    using ClonesUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    address private _implementationETH; 
    address private _implementationERC20; 
    uint256 private _protocolFeeMultiplier; 
    address private _protocolFeeReceiver; 

    mapping (address => address[]) private _createdNFTs;

    mapping (address => address[]) private _ownedNFTs;

    mapping (address => bool) private _isFactoryNFT;

    EnumerableSetUpgradeable.AddressSet private _discountNFTs;

    event CreatedNFT(address indexed owner, address indexed nft);
    event Mint(address indexed ERC721Address, address indexed owner, uint256 quantity);
    event Burn(address indexed ERC721Address, address indexed owner, uint256 quantity);
    event Transfer(address indexed _ERC721Address, address indexed _from, address indexed _to, uint256 _quantity);

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() external initializer {
        __Ownable_init();
    }

    function createNFT(string memory name_, string memory symbol_, address _curve, uint256 _m, uint256 _c, uint256 _feeMultiplier, uint256 _dividendFeeMultiplier, uint256 _nftType, string memory _baseTokenURI) external returns (address newNFT) {
        require(_nftType == 0, "Only normal NFT type can be created");
        newNFT = _implementationETH.clone();
        
        INFTImplementationETH(newNFT).initialize(name_, symbol_, _curve, address(this), _m, _c, _feeMultiplier, _dividendFeeMultiplier, _nftType, _baseTokenURI);

        _createdNFTs[msg.sender].push(newNFT);
        _isFactoryNFT[newNFT] = true;
        emit CreatedNFT(msg.sender, newNFT);
    }

    function createNFTERC20(string memory name_, string memory symbol_, address _curve, uint256 _m, uint256 _c, uint256 _feeMultiplier, uint256 _dividendFeeMultiplier, uint256 _nftType, string memory _baseTokenURI, address _erc20) external returns (address newNFT) {
        require(_nftType == 0, "Only normal NFT type can be created");
        newNFT = _implementationERC20.clone();
        
        INFTImplementationERC20(newNFT).initialize(name_, symbol_, _curve, address(this), _m, _c, _feeMultiplier, _dividendFeeMultiplier, _nftType, _baseTokenURI, _erc20);

        _createdNFTs[msg.sender].push(newNFT);
        _isFactoryNFT[newNFT] = true;
        emit CreatedNFT(msg.sender, newNFT);
    }

    function createNFTAdvanced(string memory name_, string memory symbol_, address _curve, uint256 _m, uint256 _c, uint256 _feeMultiplier, uint256 _dividendFeeMultiplier, uint256 _nftType, string memory _baseTokenURI) external returns (address newNFT) {
        require(isHasDiscountNFT(msg.sender), "Only has discount NFTs");
        newNFT = _implementationETH.clone();
        
        INFTImplementationETH(newNFT).initialize(name_, symbol_, _curve, address(this), _m, _c, _feeMultiplier, _dividendFeeMultiplier, _nftType, _baseTokenURI);

        _createdNFTs[msg.sender].push(newNFT);
        _isFactoryNFT[newNFT] = true;
        emit CreatedNFT(msg.sender, newNFT);
    }

    function createNFTERC20Advanced(string memory name_, string memory symbol_, address _curve, uint256 _m, uint256 _c, uint256 _feeMultiplier, uint256 _dividendFeeMultiplier, uint256 _nftType, string memory _baseTokenURI, address _erc20) external returns (address newNFT) {
        require(isHasDiscountNFT(msg.sender), "Only has discount NFTs");
        newNFT = _implementationERC20.clone();
        
        INFTImplementationERC20(newNFT).initialize(name_, symbol_, _curve, address(this), _m, _c, _feeMultiplier, _dividendFeeMultiplier, _nftType, _baseTokenURI, _erc20);

        _createdNFTs[msg.sender].push(newNFT);
        _isFactoryNFT[newNFT] = true;
        emit CreatedNFT(msg.sender, newNFT);
    }

    function getCreatedNFTs(address _owner) external view returns (address[] memory) {
        return _createdNFTs[_owner];
    }

    function getCreatedNFTsCount(address _owner) external view returns (uint256) {
        return _createdNFTs[_owner].length;
    }

    function getOwnedNFTsCount(address _owner) external view returns (address[] memory _nftAddress, uint256[] memory _nftCount) {
        _nftAddress = getOwnedNFTs(_owner);
        _nftCount = new uint256[](_nftAddress.length);
        for(uint256 i = 0; i < _ownedNFTs[_owner].length; i++) {
            _nftCount[i] = INFTImplementationETH(_nftAddress[i]).balanceOf(_owner);
        }
    }

    function getOwnedNFTs(address _owner) public view returns (address[] memory) {
        return _ownedNFTs[_owner];
    }

    function recordOwnedNFTs(address _owner, address _nft) external {
        _ownedNFTs[_owner].push(_nft);
    }

    function getImplementationETH() external view returns (address) {
        return _implementationETH;
    }

    function getImplementationERC20() external view returns (address) {
        return _implementationERC20;
    }

    function getProtocolFeeMultiplier() external view returns (uint256) {
        return _protocolFeeMultiplier;
    }

    function getProtocolFeeReceiver() external view returns (address) {
        return _protocolFeeReceiver;
    }

    function setImplementationETH(address __implementationETH) external onlyOwner {
        _implementationETH = __implementationETH;
    }

    function setImplementationERC20(address __implementationERC20) external onlyOwner {
        _implementationERC20 = __implementationERC20;
    }

    function setProtocolFeeMultiplier(uint256 _multiplier) external onlyOwner {
        _protocolFeeMultiplier = _multiplier;
    }

    function setProtocolFeeReceiver(address _receiver) external onlyOwner {
        _protocolFeeReceiver = _receiver;
    }

    function setAssignURI(address _nftAddress, string memory __newURI) external onlyOwner {
        INFTImplementationETH(_nftAddress).changeURI(__newURI);
    }

    function emitMint(address _ERC721Address, address _owner, uint256 _quantity) external {
        require(_isFactoryNFT[msg.sender], "not a factory created NFT");
        emit Mint(_ERC721Address, _owner, _quantity);
    }

    function emitBurn(address _ERC721Address, address _owner, uint256 _quantity) external {
        require(_isFactoryNFT[msg.sender], "not a factory created NFT");
        emit Burn(_ERC721Address, _owner, _quantity);
    }

    function emitTransfer(address _ERC721Address, address _from, address _to, uint256 _quantity) external {
        require(_isFactoryNFT[msg.sender], "not a factory created NFT");
        emit Transfer(_ERC721Address, _from, _to, _quantity);
    }
    
    function addDiscountNFT(address _nft) external onlyOwner {
        _discountNFTs.add(_nft);
    }

    function removeDiscountNFT(address _nft) external onlyOwner {
        _discountNFTs.remove(_nft);
    }

    function isHasDiscountNFT(address _user) public view returns (bool) {
        for(uint256 i = 0; i < _discountNFTs.length(); ++i) {
            if(IERC721Upgradeable(_discountNFTs.at(i)).balanceOf(_user) > 0) 
                return true;
        }
        return false;
    }

}