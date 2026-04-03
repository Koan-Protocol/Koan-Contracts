// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {PriceFeed} from "./utils/PriceFeed.sol";

// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract KoanProtocolPass1155 is
    ERC1155,
    Ownable,
    ReentrancyGuard,
    ERC1155Pausable,
    ERC1155Burnable,
    ERC1155Supply
{
    // AggregatorV3Interface internal dataFeed;
    address public dataFeed;
    address public operatorAddress;
    uint256 public mintPriceUsd = 50_000_000; //$0.5= 50_000_000/10e8

    mapping(uint256 => bool) public validIds;
    mapping(address => mapping(uint256 => bool)) public hasMintId;
    mapping(uint256 => string) public eventNames;
    mapping(address => mapping(uint256 => bool)) public canMint;
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
    event OperatorAddressUpdated(address newOperator);
    event MintPriceUpdated(uint256 oldPrice, uint256 newPrice);

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {
        // ETH / USD - BASEMAINNET CHAINLINK
        dataFeed = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
    }

    // User Functions
    function mint(address account, uint256 id) public payable nonReentrant {
        require(
            canMint[msg.sender][id],
            "Address not authorized to mint this ID"
        );
        bytes memory data = abi.encodePacked("Pass", msg.sender, id);
        uint256 requiredEth = PriceFeed.getEthAmountFromUsd(
            dataFeed,
            mintPriceUsd
        );
        // uint256 requiredEth = getMintPriceEthAmount();
        require(msg.value >= requiredEth, "Insufficient ETH sent");

        require(validIds[id], "Invalid or inactive event");

        require(!hasMintId[msg.sender][id], "You can mint a pass only Once");

        (bool success, ) = payable(owner()).call{value: requiredEth}("");
        require(success, "Payment failed");

        _mint(account, id, 1, data);

        hasMintId[msg.sender][id] = true;

        // Refund excess ETH if any
        if (msg.value > requiredEth) {
            payable(msg.sender).transfer(msg.value - requiredEth);
        }

        emit PassMinted(
            msg.sender,
            account,
            id,
            eventNames[id],
            1,
            requiredEth
        );
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        return PriceFeed.getLatestPrice(dataFeed);
    }

    function getMintPriceEthAmount() public view returns (uint256) {
        int256 price = PriceFeed.getLatestPrice(dataFeed);
        require(price > 0, "Invalid price from oracle");

        uint256 ethAmount = (mintPriceUsd * 1 ether) / uint256(price);

        return ethAmount;
    }

    // Admin Functions
    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function updateDataFeed(address newDataFeed) external onlyOwner {
        dataFeed = newDataFeed;
    }

    function setOperatorAddress(address _operatorAddress) public onlyOwner {
        operatorAddress = _operatorAddress;
        emit OperatorAddressUpdated(_operatorAddress);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addEvent(
        string memory eventName
    ) external onlyOwner returns (uint256) {
        nextEventId++;
        eventNames[nextEventId] = eventName;
        validIds[nextEventId] = true;

        emit EventCreated(nextEventId, eventName, block.timestamp);
        return nextEventId;
    }

    function updateMintPriceUsd(uint256 newPrice) public onlyOwner {
        uint256 oldPrice = mintPriceUsd;
        mintPriceUsd = newPrice;
        emit MintPriceUpdated(oldPrice, newPrice);
    }

    function setCanMint(
        address user,
        uint256 id,
        bool _canMint
    ) external onlyOwner {
        require(validIds[id], "Invalid event ID");
        canMint[user][id] = _canMint;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    // Required Overrides
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
