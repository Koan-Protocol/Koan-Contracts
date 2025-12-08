// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IKoanPlayLottery} from "./interfaces/IKoanPlayLottery.sol";

contract RandomNumberGenerator is VRFConsumerBaseV2Plus {
    using SafeERC20 for IERC20;

    address public admin;

    uint256 public latestLotteryId;

    // Your subscription ID.
    uint256 public sSubscriptionId =
        107501249889980620307102052039419643184716714136476626081377165000830916800746;

    address public koanPlayLottery;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/vrf/v2-5/supported-networks#configurations
    bytes32 public sKeyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 40,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 public callbackGasLimit = 40000;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // For this example, retrieve 1 random value in one request.
    // Cannot exceed VRFCoordinatorV2_5.MAX_NUM_WORDS.
    uint32 public numWords = 1;

    uint256 public latestRequestId;
    uint32 public randomResult;
    uint256 public fee;

    // Modifier to restrict functions to admin only
    modifier isAdmin() {
        _isAdmin();
        _;
    }

    // Modifier to restrict functions to admin only
    modifier isLotteryContract() {
        _isLotteryContract();
        _;
    }

    function _isAdmin() internal view {
        require(msg.sender == admin, "Caller is not the admin");
    }

    function _isLotteryContract() internal view {
        require(
            msg.sender == koanPlayLottery ||
                msg.sender ==
                IKoanPlayLottery(koanPlayLottery).operatorAddress(),
            "Caller is not the koanPlayLottery"
        );
    }

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        admin = msg.sender;
        sKeyHash = _keyHash;
    }

    function getLotteryWinningNumber() external {
        require(msg.sender == koanPlayLottery, "Only koanPlayLottery");
        require(sKeyHash != bytes32(0), "Must have valid key hash");

        // Will revert if subscription is not set and funded.
        latestRequestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: sKeyHash,
                subId: sSubscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    /**
     * @notice Set the address for the koanPlayLottery
     * @param _koanPlayLottery: address of the koanPlayLottery contract
     */
    function setLotteryAddress(address _koanPlayLottery) external onlyOwner {
        koanPlayLottery = _koanPlayLottery;
    }

    /**
     * @notice It allows the admin to withdraw tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function withdrawTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }

    /**
     * @notice Change the s_keyHash
     * @param _keyHash: new s_keyHash
     */
    function setKeyHash(bytes32 _keyHash) external isAdmin {
        sKeyHash = _keyHash;
    }

    /**
     * @notice Change the VRF subscription ID
     * @param _subscriptionId New subscription ID
     */
    function setSubscriptionId(uint256 _subscriptionId) external isAdmin {
        sSubscriptionId = _subscriptionId;
    }

    /**
     * @notice Update the VRF callback gas limit
     * @param _callbackGasLimit New callback gas limit
     */
    function setCallbackGasLimit(uint32 _callbackGasLimit) external isAdmin {
        require(_callbackGasLimit > 0, "Invalid gas limit");
        callbackGasLimit = _callbackGasLimit;
    }

    /**
     * @notice View latestLotteryId
     */

    function viewLatestLotteryId() external view returns (uint256) {
        return latestLotteryId;
    }

    /**
     * @notice View random result
     */
    function viewRandomResult() external view returns (uint32) {
        return randomResult;
    }

    function setLatestLotteryId(
        uint256 _latestLotteryId
    ) external isLotteryContract {
        latestLotteryId = _latestLotteryId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        require(latestRequestId == requestId, "Wrong requestId");
        randomResult = uint32(1000000 + (randomWords[0] % 1000000));
    }
}
