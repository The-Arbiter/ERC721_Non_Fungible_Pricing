// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./ERC721A.sol";


/** 

NON-FUNGIBLE PRICING
by Ulquiorra

Non-fungible pricing is a gas-efficient way of storing prices on-chain.

There are two main approaches:

1) Keccak hash the entire price list and pass it in as calldata, compare and then use the values if correct
    [+] No storage usage
    [-] Keccak of long arrays is expensive
    [-] Breaks composability

2) Using the lowest-common-denominator principle, break NFT pricing into 'steps' and pack many instances of these steps into a struct
    [+] Maintains composability
    [-] Requires storage usage
    [-] Still expensive to store with packed structs (unless using nonsensical bytecode)

v1.0 of Non-Fungible-Pricing will implement method 2 and use reasonable step values (0.01 ETH).
uint16 supports 65536 steps of 0.01 ETH (max price 655 ETH for a mint). 
Assuming ETH price in a range of $400 - $4000 (as of June 2022), this should allow for a usable price range.

TODO LIST

~~Main items~~
Tests for this
Clean up the if statement forest and turn it to switch and case if I can somehow

*/

contract Basic_NFT is ERC721A, Ownable{
    
    error CannotMintMoreThanMaximum();
    error SendMoreEther();

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public CURRENT_SUPPLY = 0;
    string public baseUri = "";

    /// @dev Multiplier is set at 0.01 based on the above assumptions
    uint256 constant multiplier = 0.01 ether;

    /// @dev Store sixteen prices in the space of 
    struct Sixteen_Prices {
        uint16 slot0;
        uint16 slot1;
        uint16 slot2;
        uint16 slot3;
        uint16 slot4;
        uint16 slot5;
        uint16 slot6;
        uint16 slot7;
        uint16 slot8;
        uint16 slot9;
        uint16 slot10;
        uint16 slot11;
        uint16 slot12;
        uint16 slot13;
        uint16 slot14;
        uint16 slot15;
    }

    /// @dev The number of 32 byte words you need to store all prices will be x/16 (rounded up) for x NFTs
    mapping (uint256 => Sixteen_Prices) NFT_Prices;

    /// @dev OnlyOwner function allows contract owner to set prices after contract creation
    /// @param prices_ Array of prices, all as uint16 multiples of 0.01 ETH.
    function setPrices(uint16[] calldata prices_) external onlyOwner{

        uint256 arrayLength = prices_.length;
        // Set up an instance of the prices in memory 
        Sixteen_Prices memory priceArray;

        uint256 numberOfSlotsRequired = (arrayLength / 16 ) + 1;

        uint256 startIndex = 0;
        uint256 endIndex;

        
        /// NOTE This will leave any uninitialised values as copies of the second last mapping element. 
        /// This shouldn't matter unless you plan on expanding your collection size.
        /// In which case, move the memory copy of priceArray inside the loop and you're good to go.

        // Loop through the prices 16 at a time
        for(uint256 index=0; index<numberOfSlotsRequired; ++index){
            
            // Don't read non-existent array entries
            if(startIndex + 16 > arrayLength - 1){
                endIndex = arrayLength - 1;
            }else{
                endIndex = startIndex+16;
            }

            // Copy it to memory
            uint16[] memory tempPrices = prices_[startIndex : endIndex];

            // Copy the corresponding slice of the array
            priceArray.slot0 = tempPrices[0];
            priceArray.slot1 = tempPrices[1];
            priceArray.slot2 = tempPrices[2];
            priceArray.slot3 = tempPrices[3];
            priceArray.slot4 = tempPrices[4];
            priceArray.slot5 = tempPrices[5];
            priceArray.slot6 = tempPrices[6];
            priceArray.slot7 = tempPrices[7];
            priceArray.slot8 = tempPrices[8];
            priceArray.slot9 = tempPrices[9];
            priceArray.slot10 = tempPrices[10];
            priceArray.slot11 = tempPrices[11];
            priceArray.slot12 = tempPrices[12];
            priceArray.slot13 = tempPrices[13];
            priceArray.slot14 = tempPrices[14];
            priceArray.slot15 = tempPrices[15];
            
            // Increment the offset
            startIndex += 16;
            // Write to storage
            NFT_Prices[index] = priceArray;
            
        }
    }

    /// @dev Updates the price for a given tokenId 
    function updatePrice(uint256 tokenId_ ,uint16 newPrice_) external onlyOwner{

        uint256 slotNumber = tokenId_ % 16;
        // 😂BRUH😂 no switch statements
        if(slotNumber == 0) NFT_Prices[tokenId_/16].slot0 = newPrice_;
        if(slotNumber == 1)  NFT_Prices[tokenId_/16].slot1 = newPrice_;
        if(slotNumber == 2)  NFT_Prices[tokenId_/16].slot2 = newPrice_;
        if(slotNumber == 3)  NFT_Prices[tokenId_/16].slot3 = newPrice_;
        if(slotNumber == 4)  NFT_Prices[tokenId_/16].slot4 = newPrice_;
        if(slotNumber == 5)  NFT_Prices[tokenId_/16].slot5 = newPrice_;
        if(slotNumber == 6)  NFT_Prices[tokenId_/16].slot6 = newPrice_;
        if(slotNumber == 7)  NFT_Prices[tokenId_/16].slot7 = newPrice_;
        if(slotNumber == 8)  NFT_Prices[tokenId_/16].slot8 = newPrice_;
        if(slotNumber == 9)  NFT_Prices[tokenId_/16].slot9 = newPrice_;
        if(slotNumber == 10)  NFT_Prices[tokenId_/16].slot10 = newPrice_;
        if(slotNumber == 11)  NFT_Prices[tokenId_/16].slot11 = newPrice_;
        if(slotNumber == 12)  NFT_Prices[tokenId_/16].slot12 = newPrice_;
        if(slotNumber == 13)  NFT_Prices[tokenId_/16].slot13 = newPrice_;
        if(slotNumber == 14)  NFT_Prices[tokenId_/16].slot14 = newPrice_;
        if(slotNumber == 15)  NFT_Prices[tokenId_/16].slot15 = newPrice_;

    }

    function getPrice(uint256 tokenId_) public returns (uint256) {

        uint256 slotNumber = tokenId_ % 16;
        // 😂BRUH😂 no switch statements
        if(slotNumber == 0) return NFT_Prices[tokenId_/16].slot0 * multiplier;
        if(slotNumber == 1) return NFT_Prices[tokenId_/16].slot1 * multiplier;
        if(slotNumber == 2) return NFT_Prices[tokenId_/16].slot2 * multiplier;
        if(slotNumber == 3) return NFT_Prices[tokenId_/16].slot3 * multiplier;
        if(slotNumber == 4) return NFT_Prices[tokenId_/16].slot4 * multiplier;
        if(slotNumber == 5) return NFT_Prices[tokenId_/16].slot5 * multiplier;
        if(slotNumber == 6) return NFT_Prices[tokenId_/16].slot6 * multiplier;
        if(slotNumber == 7) return NFT_Prices[tokenId_/16].slot7 * multiplier;
        if(slotNumber == 8) return NFT_Prices[tokenId_/16].slot8 * multiplier;
        if(slotNumber == 9) return NFT_Prices[tokenId_/16].slot9 * multiplier;
        if(slotNumber == 10) return NFT_Prices[tokenId_/16].slot10 * multiplier;
        if(slotNumber == 11) return NFT_Prices[tokenId_/16].slot11 * multiplier;
        if(slotNumber == 12) return NFT_Prices[tokenId_/16].slot12 * multiplier;
        if(slotNumber == 13) return NFT_Prices[tokenId_/16].slot13 * multiplier;
        if(slotNumber == 14) return NFT_Prices[tokenId_/16].slot14 * multiplier;
        if(slotNumber == 15) return NFT_Prices[tokenId_/16].slot15 * multiplier;

    }

    constructor() ERC721A("Name", "Symbol")
    {}


    function safeMint(address to, uint256 _numberToMint) public payable {
        
        if(CURRENT_SUPPLY + _numberToMint > MAX_SUPPLY){
            revert CannotMintMoreThanMaximum();
        }

        uint256 priceRequired;

        // Calculate price required for single
        if(_numberToMint == 1){
            priceRequired = getPrice(CURRENT_SUPPLY+1);
        }
        // and multiple mints
        else{
            for(uint256 i=0; i<_numberToMint; i++){
                priceRequired += getPrice(CURRENT_SUPPLY+1 + i);
            }
        }
        
        if(msg.value < _numberToMint * MINT_PRICE){
            revert SendMoreEther();
        }

        CURRENT_SUPPLY += _numberToMint;

        _safeMint(to, _numberToMint);

    }
   
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory baseUri_) external onlyOwner {
        baseUri = baseUri_;
    }

    function withdraw() external onlyOwner {
        payable(Ownable.owner()).transfer(address(this).balance);
    }

    
    

    
}
