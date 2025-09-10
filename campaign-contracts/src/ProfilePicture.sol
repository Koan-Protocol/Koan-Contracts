// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PriceFeed} from "./utils/PriceFeed.sol";

contract KoanProfile is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Pausable,
    Ownable,
    ERC721Burnable
{
    using Strings for uint256;
    // AggregatorV3Interface internal dataFeed;
    address public dataFeed;
    uint256 MINT_PRICE_USD = 50_000_000; //$0.5= 50_000_000/10e8

    uint256 private _nextTokenId;
    mapping(address => uint256) public userCurrentPFP;

    event PFUpdated(address indexed user, uint256 tokenId);

    constructor(
        address initialOwner
    ) ERC721("KoanprotocolProfileAvatars", "KPPA") Ownable(initialOwner) {
        dataFeed = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;

        // dataFeed = AggregatorV3Interface(
        //     0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1
        // );
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(
        address to,
        string memory uri
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        return tokenId;
    }

    function mint(string memory uri) public payable returns (uint256) {
        uint256 requiredETH = PriceFeed.getETHAmountFromUSD(
            dataFeed,
            MINT_PRICE_USD
        );
        require(msg.value >= requiredETH, "Insufficient ETH sent");

        (bool success, ) = payable(owner()).call{value: requiredETH}("");
        require(success, "Payment failed");

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        userCurrentPFP[msg.sender] = tokenId;

        // Refund excess ETH if any
        if (msg.value > requiredETH) {
            payable(msg.sender).transfer(msg.value - requiredETH);
        }

        return tokenId;
    }

    function withdrawERC20(
        address tokenAddress,
        uint256 amount
    ) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        require(balance > 0, "No tokens to withdraw");
        require(amount <= balance, "Insufficient token balance");

        bool success = token.transfer(owner(), amount);
        require(success, "Token transfer failed");
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Function to withdraw ALL ERC20 tokens of a specific type
    function withdrawAllERC20(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        require(balance > 0, "No tokens to withdraw");

        bool success = token.transfer(owner(), balance);
        require(success, "Token transfer failed");
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function _setProfilePicture(uint256 tokenId) private returns (bool) {
        require(_ownerOf(tokenId) == msg.sender, "you are not owner");
        userCurrentPFP[msg.sender] = tokenId;
        emit PFUpdated(msg.sender, tokenId);
        return true;
    }

    function setProfilePicture(uint256 tokenId) external {
        _setProfilePicture(tokenId);
    }

    function getUserPFP(address user) public view returns (uint256) {
        return userCurrentPFP[user];
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        return PriceFeed.getLatestPrice(dataFeed);
    }

    function getMintPriceETHAmount() public view returns (uint256) {
        int256 price = PriceFeed.getLatestPrice(dataFeed);
        require(price > 0, "Invalid price from oracle");

        uint256 ethAmount = (MINT_PRICE_USD * 1 ether) / uint256(price);

        return ethAmount;
    }
}
