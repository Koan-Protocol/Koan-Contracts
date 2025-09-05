// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
contract KoanProfile is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenIds;

    error TransferFailed();
    error InvalidPriceFeed();
    error StalePriceData();

    mapping(address => uint256) public userCurrentPFP;
    string private baseTokenURI;
    address public feeCollector;

    AggregatorV3Interface internal priceFeed;

    uint256 public constant MINT_FEE_USD = 50_000_000;
    uint256 public constant PRICE_STALENESS_THRESHOLD = 3600;

    event PFUpdated(address indexed user, uint256 tokenId);

    constructor(
        address _priceFeed,
        string memory _baseTokenURI,
        address _feeCollector
    ) ERC721("KoanProfile", "KPF") Ownable(msg.sender) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        baseTokenURI = _baseTokenURI;
        feeCollector = _feeCollector;
    }

    function mintPFP() public payable returns (uint256) {
        require(balanceOf(msg.sender) == 0, "User already owns a token");

        uint256 mintFee = _calculateMintAmount();
        require(msg.value >= mintFee, "Insufficient ETH for $0.50 fee");



        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        _safeMint(msg.sender, newTokenId);

        userCurrentPFP[msg.sender] = newTokenId;
        emit PFUpdated(msg.sender, newTokenId);

        (bool success, ) = payable(feeCollector).call{value: mintFee}("");
        if (!success) revert TransferFailed();

        if (msg.value > mintFee) {
            (bool refundSuccess, ) = payable(msg.sender).call{
                value: msg.value - mintFee
            }("");
            if (!refundSuccess) revert TransferFailed();
        }

        return newTokenId;
    }

    function setProfilePicture(uint256 tokenId) external {
        _setProfilePicture(tokenId);
    }

    function getUserPFP(address user) public view returns (uint256) {
        return userCurrentPFP[user];
    }

    function calculateMintAmount() public view returns (uint256) {
        return _calculateMintAmount();
    }

    function _setProfilePicture(uint256 tokenId) private returns (bool) {
        require(_ownerOf(tokenId) == msg.sender, "you are not owner");
        userCurrentPFP[msg.sender] = tokenId;
        emit PFUpdated(msg.sender, tokenId);
        return true;
    }


    function _calculateMintAmount() private view returns (uint256) {
        (
            uint80 roundId,
            int256 ethUsdPrice,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        if (ethUsdPrice <= 0) revert InvalidPriceFeed();
        if (updatedAt == 0) revert InvalidPriceFeed();
        if (block.timestamp - updatedAt > PRICE_STALENESS_THRESHOLD)
            revert StalePriceData();
        if (roundId != answeredInRound) revert InvalidPriceFeed();

        return (MINT_FEE_USD * 10 ** 18) / uint256(ethUsdPrice);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return string(abi.encodePacked(baseTokenURI, _toString(tokenId)));
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
