// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title KoanprotocolFaucet
 * @dev A simple and secure faucet contract for dispensing testnet tokens.
 * 1. users to claim specific tokens or all supported tokens based on eligibility criteria.
 * 2. admin functionalities for managing tokens and users.
 */

contract KoanprotocolFaucet is Ownable, ReentrancyGuard, Pausable {
    struct UserFaucetData {
        uint256 totalDrippedAmount; // Total amount claimed
        uint256 lastDrippedTime; //last claim time
        uint256 nextClaimTime; // next claim time
    }

    // useraddress => (tokenaddress => UserFaucetData)
    mapping(address => mapping(address => UserFaucetData))
        public userFaucetData;
    address[] public supportedTokens;

    // tokenaddress => bool
    mapping(address => bool) public isSupportedToken;

    mapping(address => uint256) public minUserBalanceForToken;

    mapping(address => uint256) public faucetAmountPerToken;

    uint256 public constant MIN_CLAIM_INTERVAL = 3 days;

    mapping(address => bool) public bannedUsers;

    modifier notBanned() {
        require(!bannedUsers[msg.sender], "User is banned");
        _;
    }

    event TokenClaimed(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event TokenAdded(
        address indexed token,
        uint256 minBalance,
        uint256 faucetAmount
    );

    // EVENTS
    event TokenRemoved(address indexed token);
    event MinUserBalanceUpdated(address indexed token, uint256 newMinBalance);
    event FaucetAmountUpdated(address indexed token, uint256 newFaucetAmount);
    event UserBanned(address indexed user);
    event UserUnbanned(address indexed user);

    constructor() Ownable(msg.sender) {}

    function claim(address _token) external notBanned nonReentrant {
        _claimToken(_token);
    }

    function claimAllSupportedTokens() external notBanned nonReentrant {
        for (uint i = 0; i < supportedTokens.length; i++) {
            address currentToken = supportedTokens[i];
            _claimToken(currentToken);
        }
    }
    function _claimToken(address _token) internal whenNotPaused returns (bool) {
        require(isSupportedToken[_token], "Token is not supported");

        uint256 currentUserBalance = IERC20(_token).balanceOf(msg.sender);

        require(
            currentUserBalance < minUserBalanceForToken[_token],
            "User balance is already above minimum threshold"
        );
        require(
            block.timestamp >= userFaucetData[msg.sender][_token].nextClaimTime,
            "Claim cooldown period has not passed"
        );

        uint256 amountToDispense = faucetAmountPerToken[_token];
        require(
            IERC20(_token).balanceOf(address(this)) >= amountToDispense,
            "Amount to dispense is 0"
        );

        bool success = IERC20(_token).transfer(msg.sender, amountToDispense);
        if (!success) {
            return false;
        }

        UserFaucetData storage userData = userFaucetData[msg.sender][_token];
        userData.totalDrippedAmount += amountToDispense;
        userData.lastDrippedTime = block.timestamp;
        userData.nextClaimTime = block.timestamp + MIN_CLAIM_INTERVAL;

        emit TokenClaimed(msg.sender, _token, amountToDispense);

        return true;
    }

    // --- Admin Functions (Only callable by the contract owner) ---

    function addSupportedToken(
        address _token,
        uint256 _minBalance,
        uint256 _faucetAmount
    ) external onlyOwner {
        require(
            _token != address(0),
            "KoanFaucet: Token address cannot be zero."
        );
        require(
            !isSupportedToken[_token],
            "KoanFaucet: Token is already supported."
        );
        require(
            _faucetAmount > 0,
            "KoanFaucet: Faucet amount must be greater than zero."
        );

        supportedTokens.push(_token);
        isSupportedToken[_token] = true;
        minUserBalanceForToken[_token] = _minBalance;
        faucetAmountPerToken[_token] = _faucetAmount;

        emit TokenAdded(_token, _minBalance, _faucetAmount);
    }

    function removeSupportedToken(address _token) external onlyOwner {
        require(
            _token != address(0),
            "KoanFaucet: Token address cannot be zero."
        );
        require(
            isSupportedToken[_token],
            "KoanFaucet: Token is not supported."
        );

        for (uint i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == _token) {
                supportedTokens[i] = supportedTokens[
                    supportedTokens.length - 1
                ];
                supportedTokens.pop();
                break;
            }
        }
        isSupportedToken[_token] = false;
        delete minUserBalanceForToken[_token];
        delete faucetAmountPerToken[_token];

        emit TokenRemoved(_token);
    }

    function updateMinUserBalance(
        address _token,
        uint256 _newMinBalance
    ) external onlyOwner {
        require(
            isSupportedToken[_token],
            "KoanFaucet: Token is not supported."
        );
        minUserBalanceForToken[_token] = _newMinBalance;
        emit MinUserBalanceUpdated(_token, _newMinBalance);
    }

    function updateFaucetAmount(
        address _token,
        uint256 _newFaucetAmount
    ) external onlyOwner {
        require(
            isSupportedToken[_token],
            "KoanFaucet: Token is not supported."
        );
        faucetAmountPerToken[_token] = _newFaucetAmount;
        emit FaucetAmountUpdated(_token, _newFaucetAmount);
    }

    function banUser(address _user) external onlyOwner {
        bannedUsers[_user] = true;
        emit UserBanned(_user);
    }

    function unbanUser(address _user) external onlyOwner {
        bannedUsers[_user] = false;
        emit UserUnbanned(_user);
    }

    function sendOutTokens(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0, "KoanFaucet: No tokens to send out.");
        IERC20(_token).transfer(msg.sender, amount);
    }

    function canClaimAll(address userAddress) external view returns (bool[] memory) {
        require(userAddress != address(0), "Invalid user address");
        require(!bannedUsers[userAddress], "User is banned");
        
        bool[] memory canClaim = new bool[](supportedTokens.length);
        
        for (uint i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            bool canClaimToken = true;
            if (!isSupportedToken[token]) {
                canClaimToken = false;
            }
            else if (IERC20(token).balanceOf(userAddress) >= minUserBalanceForToken[token]) {
                canClaimToken = false;
            }
            else if (block.timestamp < userFaucetData[userAddress][token].nextClaimTime) {
                canClaimToken = false;

            else if (IERC20(token).balanceOf(address(this)) < faucetAmountPerToken[token]) {
                canClaimToken = false;
            }
            
            canClaim[i] = canClaimToken;
        }
        
        return canClaim;
    }

    function canClaimOne(address userAddress, address tokenAddress) external view returns (bool canClaim) {
        require(userAddress != address(0), "Invalid user address");
        require(tokenAddress != address(0), "Invalid token address");
        
      
        canClaim = false;
        
      
        if (bannedUsers[userAddress]) {
            return false;
        }
        
        if (!isSupportedToken[tokenAddress]) {
            return false;
        }
        
        
        if (IERC20(tokenAddress).balanceOf(userAddress) >= minUserBalanceForToken[tokenAddress]) {
            return false;
        }
        
        if (block.timestamp < userFaucetData[userAddress][tokenAddress].nextClaimTime) {
            return false;
        }
        
        if (IERC20(tokenAddress).balanceOf(address(this)) < faucetAmountPerToken[tokenAddress]) {
            return false;
        }
        
       
        return true;
    }
}
