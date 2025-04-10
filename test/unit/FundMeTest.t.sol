// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
// 2. Imports
import {FundMe} from "../../src/FundMe.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    // address constant USER = address(0x123);mock一个固定的address
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 10 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 public GAS_PRICE = 1 gwei;

    function setUp() external {
        // Deploy the contract
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
        // Set up the test environment
        // vm.deal(address(this), 10 ether); // Give this contract 10 ether
    }

    // function testOwnerIsMsgSender() public {
    //     // us->Test->FundMe
    //     assertEq(fundMe.i_owner(), address(this));
    // }
    function testPriceFeedVersion() public {
        uint256 version = fundMe.getVersion();
        console.log("Price Feed Version: ", version);
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        // vm.expectRevert(); assert this tx fails/reverts
        fundMe.fund();
    }

    function testOwnerIsMsgSender() public {
        // us->Test->FundMe
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}(); //10 eth
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFounders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        // reset every test function
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingFundMeBalance = fundMe.getOwner().balance;
        uint256 startingUserBalance = address(fundMe).balance;
        // Act
        uint256 gasStart = gasleft(); // 1000
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // cost 200
        fundMe.withdraw();
        uint256 gasEnd = gasleft(); // 800
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // 200
        console.log("gasUsed: ", gasUsed);
        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingFundMeBalance + startingUserBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (
            uint160 i = startingFunderIndex;
            i < startingFunderIndex + numberOfFunders;
            i++
        ) {
            // 想用number生成address，number需要是uint160
            hoax(address(i), SEND_VALUE);
            // hoax == vm.prank(address(i)); +vm.deal(account, newBalance);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingFundMeBalance = fundMe.getOwner().balance;
        uint256 startingUserBalance = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        // form prank to stopPrank, the msg.sender is the owner

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingUserBalance ==
                fundMe.getOwner().balance
        );
    }
}
