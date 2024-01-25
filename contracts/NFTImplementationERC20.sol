// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AEnumerable.sol";
import {ICurve} from "./ICurve.sol";
import {INFTFactory} from "./INFTFactory.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface INFTImplementationERC20 {
    function initialize(string memory name_, string memory symbol_, address _curve, address _factory, uint256 _m, uint256 _c, uint256 _feeMultiplier, uint256 _dividendFeeMultiplier, uint256 _nftType, string memory _baseTokenURI, address _erc20) external;
    function changeURI(string memory _newURI) external;
    function balanceOf(address owner) external view returns (uint256);
}

contract NFTImplementationERC20 is ERC721AEnumerable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    uint256 public nftType;
    string public baseTokenURI;

    ICurve public curve;
    INFTFactory public factory;
    IERC20 public token;

    uint256 public m;
    uint256 public c;

    uint256 public feeMultiplier;
    uint256 public dividendFeeMultiplier;

    error BondingCurveError(ICurve.Error error);

    function initialize(string memory name_, string memory symbol_, address _curve, address _factory, uint256 _m, uint256 _c, uint256 _feeMultiplier, uint256 _dividendFeeMultiplier, uint256 _nftType, string memory _baseTokenURI, address _erc20) external initializerERC721A {
        _transferOwnership(tx.origin);
        __ERC721AEnumerable_init(name_, symbol_);
        nftType = _nftType;
        curve = ICurve(_curve);
        require(curve.validateSpotPrice(_c), "Invalid new spot price for curve");
        factory = INFTFactory(_factory);
        m = _m;
        c = _c;
        feeMultiplier = _feeMultiplier;
        dividendFeeMultiplier = _dividendFeeMultiplier;
        baseTokenURI = _baseTokenURI;
        token = IERC20(_erc20);
    }

    function getBuyCost(uint256 quantity) external view returns (uint256 inputAmount) {
        (, inputAmount, , ,) = curve.getBuyInfo(
            totalSupply(), 
            m, 
            c, 
            quantity, 
            feeMultiplier, 
            factory.getProtocolFeeMultiplier(),
            dividendFeeMultiplier
        );
        
    }

    function getSellReward(uint256 quantity) external view returns (uint256 outputAmount) {
        (, outputAmount, , ,) = curve.getSellInfo(
            totalSupply(), 
            m, 
            c, 
            quantity, 
            feeMultiplier, 
            factory.getProtocolFeeMultiplier(),
            dividendFeeMultiplier
        );
    }

    function getBuyPrice() external view returns (uint256) {
        return curve.getSpotPrice(totalSupply(), m, c);
    }

    function getSellPrice() external view returns (uint256) {
        return curve.getSellPrice(totalSupply(), m, c, feeMultiplier + factory.getProtocolFeeMultiplier() + dividendFeeMultiplier);
    }

    function buy(uint256 quantity, uint256 _inputAmount) external {
        require(quantity > 0, "Invalid quantity");
        (
            ICurve.Error error,
            uint256 inputAmount,
            uint256 tradeFee,
            uint256 protocolFee,
            uint256 dividendFee
        ) = curve.getBuyInfo(
            totalSupply(), 
            m, 
            c, 
            quantity, 
            feeMultiplier, 
            factory.getProtocolFeeMultiplier(),
            dividendFeeMultiplier
        );

        if (error != ICurve.Error.OK) {
            revert BondingCurveError(error);
        }

        require(_inputAmount >= inputAmount, "Sent too little tokens");

        token.safeTransferFrom(msg.sender, address(this), _inputAmount);
        token.safeTransfer(factory.getProtocolFeeReceiver(), protocolFee);
        token.safeTransfer(owner(), tradeFee);

        address[] memory holders = getAllHolders();
        _distributeEthers(dividendFee, holders);

        token.safeTransfer(msg.sender, _inputAmount - inputAmount);

        if (ERC721AUpgradeable.balanceOf(msg.sender) == 0) {
            factory.recordOwnedNFTs(msg.sender, address(this));
        }

        _mint(msg.sender, quantity);

        factory.emitMint(address(this), msg.sender, quantity);
    }

    function sell(uint256 quantity) external {
        require(quantity <= ERC721AUpgradeable.balanceOf(msg.sender), "quantity out of bounds");

        (
            ICurve.Error error,
            uint256 outputValue,
            uint256 tradeFee,
            uint256 protocolFee,
            uint256 dividendFee
        ) = curve.getSellInfo(
            totalSupply(), 
            m, 
            c, 
            quantity, 
            feeMultiplier, 
            factory.getProtocolFeeMultiplier(),
            dividendFeeMultiplier
        );

        if (error != ICurve.Error.OK) {
            revert BondingCurveError(error);
        }

        if (factory.isHasDiscountNFT(msg.sender)) {
            token.safeTransfer(msg.sender, outputValue + protocolFee);
        } else {
            token.safeTransfer(factory.getProtocolFeeReceiver(), protocolFee);
            token.safeTransfer(msg.sender, outputValue);
        }

        token.safeTransfer(owner(), tradeFee);

        address[] memory holders = getAllHolders();
        _distributeEthers(dividendFee, holders);

        uint256[] memory tokenIds = tokenIdsOfOwner(msg.sender);
        for(uint256 i = 0; i < quantity; ++i){
            _burn(tokenIds[i]);
        }

        factory.emitBurn(address(this), msg.sender, quantity);
    }

    function _emitTransfer(address from, address to, uint256 quantity) internal virtual override {
        super._emitTransfer(from, to, quantity);
        factory.emitTransfer(address(this), from, to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function changeURI(string memory _newURI) external {
        require(msg.sender == address(factory), "only platform can call this function");
        baseTokenURI = _newURI;
    }

    function _distributeEthers(uint256 dividendFee, address[] memory holders) internal {
        if (holders.length == 0) {
            return;
        }
        
        uint256 dividend = dividendFee / totalSupply();

        for (uint256 i = 0; i < getHoldersCount(); ++i) {
            token.safeTransfer(holders[i], dividend * ERC721AUpgradeable.balanceOf(holders[i]));
        }

    }

}