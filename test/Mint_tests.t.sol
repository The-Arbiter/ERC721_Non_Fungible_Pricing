// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "../src/Basic_NFT.sol";
import "../src/IERC721A.sol";

contract Mint_Tests is Test, IERC721Receiver {

    Basic_NFT basic_nft;

    function setUp() public {
        basic_nft = new Basic_NFT();
    }

    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data
    ) public override returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }

    fallback () external payable {
    }

    
    receive () external payable{
    }

    /// MINT FUNCTION

    function test_mint_gas() public{

        // Give the address some ETH
        Test.startHoax(address(100),100_000e18);

        uint256 mintPrice = basic_nft.MINT_PRICE();
        
        basic_nft.safeMint{value:mintPrice*10} (address(100), 10);

       

    }

    function test_mint_will_not_exceed_maximum_supply() public{

        // Give the address some ETH
        Test.startHoax(address(100),100_000e18);
        uint256 mintPrice = basic_nft.MINT_PRICE();
        uint256 maxSupply = basic_nft.MAX_SUPPLY();
        basic_nft.safeMint{value:mintPrice*maxSupply} (address(100), maxSupply);

        // Mint them all
        uint256 currentSupply = basic_nft.CURRENT_SUPPLY();
        console2.log("Current supply is ",currentSupply);
        if(currentSupply!=maxSupply){
            revert("Minted too many or too few");
        }

        //Try and mint another
        vm.expectRevert(Basic_NFT.CannotMintMoreThanMaximum.selector);
        basic_nft.safeMint{value:mintPrice} (address(100), 1);

    }

    function test_mint_cannot_pay_too_little(uint256 amountToMint_) public{

        uint256 maxSupply = basic_nft.MAX_SUPPLY();
        vm.assume(amountToMint_<maxSupply && amountToMint_!=0);
        // Give the address some ETH
        Test.startHoax(address(100),100_000e18);
        uint256 mintPrice = basic_nft.MINT_PRICE();

        vm.expectRevert(Basic_NFT.SendMoreEther.selector);
        basic_nft.safeMint{value:mintPrice*amountToMint_-1} (address(100), amountToMint_);

    }

    function test_mint_can_pay_too_much(uint256 amountToMint_, uint128 amountToOverpay_) public{

        uint256 maxSupply = basic_nft.MAX_SUPPLY();
        uint256 currentSupply = basic_nft.MAX_SUPPLY();
        
        if(currentSupply == maxSupply){
            return;
        }

        vm.assume(currentSupply + amountToMint_ <= maxSupply);
        vm.assume(amountToMint_ < 10 && amountToMint_!=0);
        vm.assume(amountToOverpay_<1 ether);
        
        // Give the address some ETH
        Test.startHoax(address(100),100_000e18);
        uint256 mintPrice = basic_nft.MINT_PRICE();

        basic_nft.safeMint{value: mintPrice * amountToMint_ + amountToOverpay_}(address(100), amountToMint_);

    }

    function test_mint_cannot_be_zero() public{

         // Give the address some ETH
         Test.startHoax(address(100),100_000e18);
         uint256 mintPrice = basic_nft.MINT_PRICE();
         vm.expectRevert(IERC721A.MintZeroQuantity.selector);
         basic_nft.safeMint{value: mintPrice}(address(100), 0);

    }

    /// SET BASE URI FUNCTION

    function test_get_and_set_baseUri() public{
        
        // Check that it is initially blank
        if(keccak256(bytes(basic_nft.baseURI()))!=keccak256(bytes(""))){
            revert("Initial baseURI isn't blank");
        }
        // Change it
        string memory newUri = "www.google.com/";
        basic_nft.setBaseURI(newUri);
        // Check it
        if(keccak256(bytes(basic_nft.baseURI()))!=keccak256(bytes(newUri))){
            revert("The baseURI didn't change");
        }

    }

    /// WITHDRAW FUNCTION


    function test_withdrawal() public {

        test_mint_gas();

        uint256 oldThisBalance = address(this).balance;
        uint256 oldContractbalance = address(basic_nft).balance;
     
        vm.stopPrank();
        basic_nft.withdraw();

        uint256 newContractbalance = address(basic_nft).balance;
        uint256 newThisBalance = address(this).balance;
        if(address(this).balance - oldThisBalance  !=  oldContractbalance - newContractbalance){
            revert("We didn't withdraw properly");
        }
       
    }



}
