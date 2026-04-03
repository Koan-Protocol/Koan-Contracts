// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Faucet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token for testing
contract MockERC20 is ERC20 {
    uint8 private _decimals;
    
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _decimals = decimals_;
        _mint(msg.sender, initialSupply);
    }
    
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract KoanprotocolFaucetTest is Test {
    KoanprotocolFaucet public faucet;
    MockERC20 public wbtc;
    MockERC20 public usdc;
    MockERC20 public dai;
    MockERC20 public koan;
    MockERC20 public link;
    
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    // Token amounts that would excite users for testing various DeFi features
    uint256 public constant WBTC_FAUCET_AMOUNT = 0.01 * 10**8; // 0.01 BTC (8 decimals)
    uint256 public constant USDC_FAUCET_AMOUNT = 500 * 10**6; // 500 USDC (6 decimals)
    uint256 public constant DAI_FAUCET_AMOUNT = 500 * 10**18; // 500 DAI (18 decimals)
    uint256 public constant KOAN_FAUCET_AMOUNT = 10000 * 10**18; // 10,000 KOAN (18 decimals)
    uint256 public constant LINK_FAUCET_AMOUNT = 50 * 10**18; // 50 LINK (18 decimals)
    
    // Minimum balance thresholds (users must be below these to claim)
    uint256 public constant WBTC_MIN_BALANCE = 0.005 * 10**8; // 0.005 BTC
    uint256 public constant USDC_MIN_BALANCE = 100 * 10**6; // 100 USDC
    uint256 public constant DAI_MIN_BALANCE = 100 * 10**18; // 100 DAI
    uint256 public constant KOAN_MIN_BALANCE = 1000 * 10**18; // 1,000 KOAN
    uint256 public constant LINK_MIN_BALANCE = 10 * 10**18; // 10 LINK
    
    event TokenClaimed(address indexed user, address indexed token, uint256 amount);
    event TokenAdded(address indexed token, uint256 minBalance, uint256 faucetAmount);
    event TokenRemoved(address indexed token);
    event UserBanned(address indexed user);
    event UserUnbanned(address indexed user);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // Deploy faucet contract
        faucet = new KoanprotocolFaucet();
        
        // Deploy mock tokens with realistic supplies
        wbtc = new MockERC20("Wrapped Bitcoin", "WBTC", 8, 100 * 10**8); // 100 BTC
        usdc = new MockERC20("USD Coin", "USDC", 6, 1000000 * 10**6); // 1M USDC
        dai = new MockERC20("Dai Stablecoin", "DAI", 18, 1000000 * 10**18); // 1M DAI
        koan = new MockERC20("Koan Protocol", "KOAN", 18, 100000000 * 10**18); // 100M KOAN
        link = new MockERC20("Chainlink", "LINK", 18, 1000000 * 10**18); // 1M LINK
        
        // Transfer tokens to faucet contract
        wbtc.transfer(address(faucet), 10 * 10**8); // 10 BTC to faucet
        usdc.transfer(address(faucet), 100000 * 10**6); // 100k USDC to faucet
        dai.transfer(address(faucet), 100000 * 10**18); // 100k DAI to faucet
        koan.transfer(address(faucet), 10000000 * 10**18); // 10M KOAN to faucet
        link.transfer(address(faucet), 10000 * 10**18); // 10k LINK to faucet
        
        // Add supported tokens to faucet
        faucet.addSupportedToken(address(wbtc), WBTC_MIN_BALANCE, WBTC_FAUCET_AMOUNT);
        faucet.addSupportedToken(address(usdc), USDC_MIN_BALANCE, USDC_FAUCET_AMOUNT);
        faucet.addSupportedToken(address(dai), DAI_MIN_BALANCE, DAI_FAUCET_AMOUNT);
        faucet.addSupportedToken(address(koan), KOAN_MIN_BALANCE, KOAN_FAUCET_AMOUNT);
        faucet.addSupportedToken(address(link), LINK_MIN_BALANCE, LINK_FAUCET_AMOUNT);
    }
    
    // ============ BASIC FUNCTIONALITY TESTS ============
    
    function testInitialSetup() public {
        // Check if all tokens are properly added
        assertTrue(faucet.isSupportedToken(address(wbtc)));
        assertTrue(faucet.isSupportedToken(address(usdc)));
        assertTrue(faucet.isSupportedToken(address(dai)));
        assertTrue(faucet.isSupportedToken(address(koan)));
        assertTrue(faucet.isSupportedToken(address(link)));
        
        // Check faucet amounts
        assertEq(faucet.faucetAmountPerToken(address(wbtc)), WBTC_FAUCET_AMOUNT);
        assertEq(faucet.faucetAmountPerToken(address(usdc)), USDC_FAUCET_AMOUNT);
        assertEq(faucet.faucetAmountPerToken(address(dai)), DAI_FAUCET_AMOUNT);
        assertEq(faucet.faucetAmountPerToken(address(koan)), KOAN_FAUCET_AMOUNT);
        assertEq(faucet.faucetAmountPerToken(address(link)), LINK_FAUCET_AMOUNT);
        
        // Check minimum balances
        assertEq(faucet.minUserBalanceForToken(address(wbtc)), WBTC_MIN_BALANCE);
        assertEq(faucet.minUserBalanceForToken(address(usdc)), USDC_MIN_BALANCE);
        assertEq(faucet.minUserBalanceForToken(address(dai)), DAI_MIN_BALANCE);
        assertEq(faucet.minUserBalanceForToken(address(koan)), KOAN_MIN_BALANCE);
        assertEq(faucet.minUserBalanceForToken(address(link)), LINK_MIN_BALANCE);
    }
    
    // ============ SINGLE TOKEN CLAIM TESTS ============
    
    function testSingleTokenClaim() public {
        vm.startPrank(user1);
        
        // User should be able to claim WBTC
        uint256 initialBalance = wbtc.balanceOf(user1);
        
        vm.expectEmit(true, true, false, true);
        emit TokenClaimed(user1, address(wbtc), WBTC_FAUCET_AMOUNT);
        
        faucet.claim(address(wbtc));
        
        assertEq(wbtc.balanceOf(user1), initialBalance + WBTC_FAUCET_AMOUNT);
        
        // Check user faucet data
        (uint256 totalDripped, uint256 lastDripped, uint256 nextClaim) = 
            faucet.userFaucetData(user1, address(wbtc));
        
        assertEq(totalDripped, WBTC_FAUCET_AMOUNT);
        assertEq(lastDripped, block.timestamp);
        assertEq(nextClaim, block.timestamp + 3 days);
        
        vm.stopPrank();
    }
    
    function testCannotClaimUnsupportedToken() public {
        MockERC20 unsupportedToken = new MockERC20("Unsupported", "UNS", 18, 1000000 * 10**18);
        
        vm.startPrank(user1);
        vm.expectRevert("Token is not supported");
        faucet.claim(address(unsupportedToken));
        vm.stopPrank();
    }
    
    function testCannotClaimIfUserBalanceTooHigh() public {
        // Give user1 more WBTC than the minimum threshold
        wbtc.mint(user1, WBTC_MIN_BALANCE + 1);
        
        vm.startPrank(user1);
        vm.expectRevert("User balance is already above minimum threshold");
        faucet.claim(address(wbtc));
        vm.stopPrank();
    }
    
    function testCannotClaimDuringCooldown() public {
        vm.startPrank(user1);
        
        // First claim should succeed
        faucet.claim(address(wbtc));
        
        // Second claim should fail due to cooldown
        vm.expectRevert("Claim cooldown period has not passed");
        faucet.claim(address(wbtc));
        
        vm.stopPrank();
    }
    
    function testCanClaimAfterCooldown() public {
        vm.startPrank(user1);
        
        // First claim
        faucet.claim(address(wbtc));
        uint256 balanceAfterFirst = wbtc.balanceOf(user1);
        
        // Fast forward past cooldown period
        vm.warp(block.timestamp + 3 days + 1);
        
        // Second claim should succeed
        faucet.claim(address(wbtc));
        assertEq(wbtc.balanceOf(user1), balanceAfterFirst + WBTC_FAUCET_AMOUNT);
        
        vm.stopPrank();
    }
    
    // ============ CLAIM ALL TOKENS TESTS ============
    
    function testClaimAllSupportedTokens() public {
        vm.startPrank(user1);
        
        uint256 wbtcInitial = wbtc.balanceOf(user1);
        uint256 usdcInitial = usdc.balanceOf(user1);
        uint256 daiInitial = dai.balanceOf(user1);
        uint256 koanInitial = koan.balanceOf(user1);
        uint256 linkInitial = link.balanceOf(user1);
        
        // Expect events for all token claims
        vm.expectEmit(true, true, false, true);
        emit TokenClaimed(user1, address(wbtc), WBTC_FAUCET_AMOUNT);
        vm.expectEmit(true, true, false, true);
        emit TokenClaimed(user1, address(usdc), USDC_FAUCET_AMOUNT);
        vm.expectEmit(true, true, false, true);
        emit TokenClaimed(user1, address(dai), DAI_FAUCET_AMOUNT);
        vm.expectEmit(true, true, false, true);
        emit TokenClaimed(user1, address(koan), KOAN_FAUCET_AMOUNT);
        vm.expectEmit(true, true, false, true);
        emit TokenClaimed(user1, address(link), LINK_FAUCET_AMOUNT);
        
        faucet.claimAllSupportedTokens();
        
        // Check all balances increased
        assertEq(wbtc.balanceOf(user1), wbtcInitial + WBTC_FAUCET_AMOUNT);
        assertEq(usdc.balanceOf(user1), usdcInitial + USDC_FAUCET_AMOUNT);
        assertEq(dai.balanceOf(user1), daiInitial + DAI_FAUCET_AMOUNT);
        assertEq(koan.balanceOf(user1), koanInitial + KOAN_FAUCET_AMOUNT);
        assertEq(link.balanceOf(user1), linkInitial + LINK_FAUCET_AMOUNT);
        
        vm.stopPrank();
    }
    
    function testClaimAllSkipsIneligibleTokens() public {
        // Give user1 too much WBTC so they can't claim it
        wbtc.mint(user1, WBTC_MIN_BALANCE + 1);
        
        vm.startPrank(user1);
        
        uint256 wbtcInitial = wbtc.balanceOf(user1);
        uint256 usdcInitial = usdc.balanceOf(user1);
        
        // This should NOT emit TokenClaimed for WBTC but should for others
        // Note: claimAllSupportedTokens continues even if some tokens fail
        faucet.claimAllSupportedTokens();
        
        // WBTC balance should remain unchanged
        assertEq(wbtc.balanceOf(user1), wbtcInitial);
        // USDC balance should increase
        assertEq(usdc.balanceOf(user1), usdcInitial + USDC_FAUCET_AMOUNT);
        
        vm.stopPrank();
    }
    
    // ============ TOKEN EXHAUSTION TESTS ============
    
    function testTokenExhaustion() public {
        // Calculate how many claims would exhaust WBTC
        uint256 faucetWbtcBalance = wbtc.balanceOf(address(faucet));
        uint256 maxClaims = faucetWbtcBalance / WBTC_FAUCET_AMOUNT;
        
        // Make claims until faucet is almost empty
        for (uint i = 0; i < maxClaims; i++) {
            address claimUser = makeAddr(string(abi.encodePacked("user", vm.toString(i))));
            vm.prank(claimUser);
            faucet.claim(address(wbtc));
        }
        
        // Next claim should fail due to insufficient balance
        address finalUser = makeAddr("finalUser");
        vm.startPrank(finalUser);
        vm.expectRevert("Amount to dispense is 0");
        faucet.claim(address(wbtc));
        vm.stopPrank();
    }
    
    function testClaimAllWithExhaustedToken() public {
        // Exhaust WBTC
        uint256 faucetWbtcBalance = wbtc.balanceOf(address(faucet));
        wbtc.transferFrom(address(faucet), owner, faucetWbtcBalance);
        
        vm.startPrank(user1);
        
        uint256 usdcInitial = usdc.balanceOf(user1);
        
        // Claim all should work for available tokens and skip exhausted ones
        faucet.claimAllSupportedTokens();
        
        // Should still get other tokens
        assertEq(usdc.balanceOf(user1), usdcInitial + USDC_FAUCET_AMOUNT);
        
        vm.stopPrank();
    }
    
    // ============ FRONTEND HELPER FUNCTION TESTS ============
    
    function testCanUserClaimToken() public view {
        // User1 should be able to claim all tokens initially
        assertTrue(canUserClaimToken(user1, address(wbtc)));
        assertTrue(canUserClaimToken(user1, address(usdc)));
        assertTrue(canUserClaimToken(user1, address(dai)));
        assertTrue(canUserClaimToken(user1, address(koan)));
        assertTrue(canUserClaimToken(user1, address(link)));
    }
    
    function testCanUserClaimAll() public view {
        // User1 should be able to claim all tokens initially
        assertTrue(canUserClaimAll(user1));
    }
    
    function testGetUserClaimableTokens() public view {
        address[] memory claimableTokens = getUserClaimableTokens(user1);
        assertEq(claimableTokens.length, 5);
    }
    
    // ============ ADMIN FUNCTION TESTS ============
    
    function testAddSupportedToken() public {
        MockERC20 newToken = new MockERC20("New Token", "NEW", 18, 1000000 * 10**18);
        
        vm.expectEmit(true, false, false, true);
        emit TokenAdded(address(newToken), 100 * 10**18, 1000 * 10**18);
        
        faucet.addSupportedToken(address(newToken), 100 * 10**18, 1000 * 10**18);
        
        assertTrue(faucet.isSupportedToken(address(newToken)));
        assertEq(faucet.minUserBalanceForToken(address(newToken)), 100 * 10**18);
        assertEq(faucet.faucetAmountPerToken(address(newToken)), 1000 * 10**18);
    }
    
    function testRemoveSupportedToken() public {
        vm.expectEmit(true, false, false, false);
        emit TokenRemoved(address(link));
        
        faucet.removeSupportedToken(address(link));
        
        assertFalse(faucet.isSupportedToken(address(link)));
        assertEq(faucet.minUserBalanceForToken(address(link)), 0);
        assertEq(faucet.faucetAmountPerToken(address(link)), 0);
    }
    
    function testBanAndUnbanUser() public {
        vm.expectEmit(true, false, false, false);
        emit UserBanned(user1);
        
        faucet.banUser(user1);
        assertTrue(faucet.bannedUsers(user1));
        
        // Banned user cannot claim
        vm.startPrank(user1);
        vm.expectRevert("User is banned");
        faucet.claim(address(wbtc));
        vm.stopPrank();
        
        // Unban user
        vm.expectEmit(true, false, false, false);
        emit UserUnbanned(user1);
        
        faucet.unbanUser(user1);
        assertFalse(faucet.bannedUsers(user1));
        
        // User can claim again
        vm.startPrank(user1);
        faucet.claim(address(wbtc));
        vm.stopPrank();
    }
    
    function testOnlyOwnerFunctions() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Ownable: caller is not the owner");
        faucet.addSupportedToken(address(0x123), 0, 1000);
        
        vm.expectRevert("Ownable: caller is not the owner");
        faucet.removeSupportedToken(address(wbtc));
        
        vm.expectRevert("Ownable: caller is not the owner");
        faucet.banUser(user2);
        
        vm.expectRevert("Ownable: caller is not the owner");
        faucet.updateMinUserBalance(address(wbtc), 1000);
        
        vm.expectRevert("Ownable: caller is not the owner");
        faucet.updateFaucetAmount(address(wbtc), 1000);
        
        vm.stopPrank();
    }
    
    // ============ PAUSE FUNCTIONALITY TESTS ============
    
    // function testPauseAndUnpause() public {
    //     faucet.pause();
        
    //     vm.startPrank(user1);
    //     vm.expectRevert("Pausable: paused");
    //     faucet.claim(address(wbtc));
    //     vm.stopPrank();
        
    //     faucet.unpause();
        
    //     vm.startPrank(user1);
    //     faucet.claim(address(wbtc));
    //     vm.stopPrank();
    // }
    
    // ============ EDGE CASES ============
    
    function testZeroAddressValidation() public {
        vm.expectRevert("KoanFaucet: Token address cannot be zero.");
        faucet.addSupportedToken(address(0), 1000, 1000);
        
        vm.expectRevert("KoanFaucet: Token address cannot be zero.");
        faucet.removeSupportedToken(address(0));
    }
    
    function testZeroFaucetAmount() public {
        MockERC20 newToken = new MockERC20("New Token", "NEW", 18, 1000000 * 10**18);
        
        vm.expectRevert("KoanFaucet: Faucet amount must be greater than zero.");
        faucet.addSupportedToken(address(newToken), 1000, 0);
    }
    
    function testDuplicateTokenAddition() public {
        vm.expectRevert("KoanFaucet: Token is already supported.");
        faucet.addSupportedToken(address(wbtc), 1000, 1000);
    }
    
    function testSendOutTokens() public {
        uint256 ownerBalanceBefore = wbtc.balanceOf(owner);
        uint256 faucetBalanceBefore = wbtc.balanceOf(address(faucet));
        
        faucet.sendOutTokens(address(wbtc));
        
        assertEq(wbtc.balanceOf(owner), ownerBalanceBefore + faucetBalanceBefore);
        assertEq(wbtc.balanceOf(address(faucet)), 0);
    }
    
    // ============ HELPER FUNCTIONS FOR FRONTEND ============
    
    function canUserClaimToken(address user, address token) public view returns (bool) {
        if (!faucet.isSupportedToken(token)) return false;
        if (faucet.bannedUsers(user)) return false;
        if (faucet.paused()) return false;
        
        uint256 userBalance = IERC20(token).balanceOf(user);
        if (userBalance >= faucet.minUserBalanceForToken(token)) return false;
        
        (, , uint256 nextClaimTime) = faucet.userFaucetData(user, token);
        if (block.timestamp < nextClaimTime) return false;
        
        uint256 faucetBalance = IERC20(token).balanceOf(address(faucet));
        if (faucetBalance < faucet.faucetAmountPerToken(token)) return false;
        
        return true;
    }
    
    function canUserClaimAll(address user) public view returns (bool) {
        if (faucet.bannedUsers(user)) return false;
        if (faucet.paused()) return false;
        
        // Check if user can claim at least one token
        address[] memory tokens = getSupportedTokens();
        for (uint i = 0; i < tokens.length; i++) {
            if (canUserClaimToken(user, tokens[i])) {
                return true;
            }
        }
        return false;
    }
    
    function getUserClaimableTokens(address user) public view returns (address[] memory) {
        address[] memory allTokens = getSupportedTokens();
        address[] memory temp = new address[](allTokens.length);
        uint256 count = 0;
        
        for (uint i = 0; i < allTokens.length; i++) {
            if (canUserClaimToken(user, allTokens[i])) {
                temp[count] = allTokens[i];
                count++;
            }
        }
        
        address[] memory claimableTokens = new address[](count);
        for (uint i = 0; i < count; i++) {
            claimableTokens[i] = temp[i];
        }
        
        return claimableTokens;
    }
    
    function getSupportedTokens() public view returns (address[] memory) {
        // This would need to be implemented in the main contract
        // For now, we'll return hardcoded values
        address[] memory tokens = new address[](5);
        tokens[0] = address(wbtc);
        tokens[1] = address(usdc);
        tokens[2] = address(dai);
        tokens[3] = address(koan);
        tokens[4] = address(link);
        return tokens;
    }
    
    function getUserTokenBalance(address user, address token) public view returns (uint256) {
        return IERC20(token).balanceOf(user);
    }
    
    function getNextClaimTime(address user, address token) public view returns (uint256) {
        (, , uint256 nextClaimTime) = faucet.userFaucetData(user, token);
        return nextClaimTime;
    }
    
    function getTotalClaimedAmount(address user, address token) public view returns (uint256) {
        (uint256 totalClaimed, ,) = faucet.userFaucetData(user, token);
        return totalClaimed;
    }
}