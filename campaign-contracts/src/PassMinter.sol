// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PriceFeed} from "./utils/PriceFeed.sol";

// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract KoanProtocolPass1155 is
    ERC1155,
    Ownable,
    ERC1155Pausable,
    ERC1155Burnable,
    ERC1155Supply
{
    // AggregatorV3Interface internal dataFeed;
    address public dataFeed;
    uint256 MINT_PRICE_USD = 50_000_000; //$0.5= 50_000_000/10e8

    mapping(uint256 => bool) public validIds;
    mapping(address => mapping(uint256 => bool)) public hasMintId;
    mapping(uint256 => string) public eventNames;
    uint256 public nextEventId;

    event EventCreated(uint256 indexed id, string name, uint256 timestamp);
    event PassMinted(
        address indexed minter,
        address indexed recipient,
        uint256 indexed id,
        string name,
        uint256 amount,
        uint256 pricePaid
    );

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {
        dataFeed = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;
        // dataFeed = AggregatorV3Interface(
        //     0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1
        // );
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Owner creates new event type with a human-readable name
    function addEvent(
        string memory eventName
    ) external onlyOwner returns (uint256) {
        nextEventId++;
        eventNames[nextEventId] = eventName;
        validIds[nextEventId] = true;

        emit EventCreated(nextEventId, eventName, block.timestamp);
        return nextEventId;
    }

    function mint(
        address account,
        uint256 id,
        bytes memory data
    ) public payable {
        uint256 requiredETH = PriceFeed.getETHAmountFromUSD(
            dataFeed,
            MINT_PRICE_USD
        );
        // uint256 requiredETH = getMintPriceETHAmount();
        require(msg.value >= requiredETH, "Insufficient ETH sent");

        require(validIds[id], "Invalid or inactive event");

        require(!hasMintId[msg.sender][id], "You can mint a pass only Once");

        (bool success, ) = payable(owner()).call{value: requiredETH}("");
        require(success, "Payment failed");

        _mint(account, id, 1, data);

        hasMintId[msg.sender][id] = true;

        // Refund excess ETH if any
        if (msg.value > requiredETH) {
            payable(msg.sender).transfer(msg.value - requiredETH);
        }

        emit PassMinted(
            msg.sender,
            account,
            id,
            eventNames[id],
            1,
            requiredETH
        );
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._update(from, to, ids, values);
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
