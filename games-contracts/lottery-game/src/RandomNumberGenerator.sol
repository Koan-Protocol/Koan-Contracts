// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import  "./interfaces/IKoanPlayLottery.sol";

contract RandomNumberGenerator is VRFConsumerBaseV2Plus {

    using SafeERC20 for IERC20;

    address public admin;

    uint256 public latestLotteryId;

    // Your subscription ID.
    uint256 public s_subscriptionId = 6186081890396611561502091541217131189152193495042567314668979054444665707478;

    address public koanPlayLottery;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/vrf/v2-5/supported-networks#configurations
    bytes32 public s_keyHash = 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71;

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
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

 // Modifier to restrict functions to admin only
    modifier isLotteryContract() {
        require(msg.sender == koanPlayLottery || msg.sender == IKoanPlayLottery(koanPlayLottery).operatorAddress(), "Caller is not the koanPlayLottery");
        _;
    }
   

 constructor(
        address _vrfCoordinator
    ) VRFConsumerBaseV2Plus(_vrfCoordinator){
        admin = msg.sender;
    }

    function getLotteryWinningNumber() external {
        require(msg.sender == koanPlayLottery, "Only koanPlayLottery");
        require(s_keyHash != bytes32(0), "Must have valid key hash");

        // Will revert if subscription is not set and funded.
        latestRequestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
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
        s_keyHash = _keyHash;
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

    function setLatestLotteryId(uint256 _latestLotteryId) external isLotteryContract{
        latestLotteryId = _latestLotteryId;
    }

     function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {

        require(latestRequestId == requestId, "Wrong requestId");
        randomResult = uint32(1000000 + (randomWords[0] % 1000000));
    }
    
}
