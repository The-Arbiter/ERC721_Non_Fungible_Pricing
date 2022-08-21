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

[DEPR] v1.0 of Non-Fungible-Pricing will implement method 2 and use reasonable step values (0.01 ETH).
uint16 supports 65536 steps of 0.01 ETH (max price 655 ETH for a mint). 
Assuming ETH price in a range of $400 - $4000 (as of June 2022), this should allow for a usable price range.

[CURRENT] v2.0 of Non-Fungible-Pricing uses scaleAmountByPercentage (from 0xSplits) to perform price scaling
using assembly (making it cheaper). It still doesn't use assembly for storage read / write (which would save 
more gas) since I want this to be user-friendly.


TODO LIST

~~Main items~~
Tests for this



*/



contract NFPToken is ERC721A, Ownable{
    
    error CannotMintMoreThanMaximum();
    error SendMoreEther();
    error NoFreeMint();

    error TokenPricesMustBeSetForAllTokens();

    uint256 public constant MAX_SUPPLY = 16; /// @dev For easier testing we use 10 here, make it 10k or whatever you want
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public CURRENT_SUPPLY = 0;
    string public baseUri = "";


    /// @dev You can customise this constant (prices per slot)
    uint256 constant pricesPerSlot = 16;
    /// Multiplier represents the lowest common multiple of all prices
    uint256 constant multiplier = 0.001 ether;
    bool constant FREE_MINT_ALLOWED = false;

    /// @dev Store {setting} prices in a single slot (change this if you want)
    struct PricesStruct {
        uint16 price_0;
        uint16 price_1;
        uint16 price_2;
        uint16 price_3;
        uint16 price_4;
        uint16 price_5;
        uint16 price_6;
        uint16 price_7;
        uint16 price_8;
        uint16 price_9;
        uint16 price_10;
        uint16 price_11;
        uint16 price_12;
        uint16 price_13;
        uint16 price_14;
        uint16 price_15;
    }

    /// @dev The number of 32 byte words you need to store all prices will be x/16 (rounded up) for x NFTs
    mapping (uint256 => PricesStruct) TokenPrices;


    /**
    *   @dev OnlyOwner function which allows setting of prices
    */
    function setTokenPrices(uint16[] calldata newPrices) external onlyOwner returns(bool){

        // Make sure the owner is pricing ALL tokens
        if(newPrices.length!=MAX_SUPPLY){
            revert TokenPricesMustBeSetForAllTokens();
        }

        // Set up an instance of the prices in memory 
        PricesStruct memory priceArray;

        // Solidity rounds down decimals in uints so we +1 since we need at least one slot
        uint256 numberOfSlotsRequired = (MAX_SUPPLY / pricesPerSlot) + 1;

        // Start and end indices for calldata array slicing
        uint256 startIndex = 0;
        uint256 endIndex;

        /// NOTE This will leave any uninitialised values as copies of the second last mapping element. 
        /// This shouldn't matter unless you plan on expanding your collection size.
        /// In which case, move the memory copy of priceArray inside the loop and you're good to go.

        // Loop through the prices 16 at a time
        for(uint256 currentSlot=0; currentSlot < numberOfSlotsRequired; ++currentSlot){
            
            // Don't read non-existent array entries 
            if(startIndex + pricesPerSlot > MAX_SUPPLY - 1){
                endIndex = MAX_SUPPLY - 1;
            }else{
                endIndex = startIndex + pricesPerSlot;
            }

            // Copy it to memory
            uint16[] memory tempPrices = newPrices[startIndex : endIndex];

            // Copy the corresponding slice of the array
            priceArray.price_0 = tempPrices[0];
            priceArray.price_1 = tempPrices[1];
            priceArray.price_2 = tempPrices[2];
            priceArray.price_3 = tempPrices[3];
            priceArray.price_4 = tempPrices[4];
            priceArray.price_5 = tempPrices[5];
            priceArray.price_6 = tempPrices[6];
            priceArray.price_7 = tempPrices[7];
            priceArray.price_8 = tempPrices[8];
            priceArray.price_9 = tempPrices[9];
            priceArray.price_10 = tempPrices[10];
            priceArray.price_11 = tempPrices[11];
            priceArray.price_12 = tempPrices[12];
            priceArray.price_13 = tempPrices[13];
            priceArray.price_14 = tempPrices[14];
            priceArray.price_15 = tempPrices[15];
            
            // Increment the offset
            startIndex += pricesPerSlot;
            // Write to storage
            TokenPrices[currentSlot] = priceArray;
        }

        return true;
    }


    /** 
    *   @dev Updates a token number tokenId with price newPrice
    */
    function updateTokenPrice(uint256 tokenId ,uint16 newPrice) public onlyOwner returns(bool){

        uint256 slotIndex;
        uint256 slotPosition;
        // Figure out which price we are referring to
        unchecked{
            slotIndex = tokenId / pricesPerSlot;
            slotPosition = tokenId % pricesPerSlot;
        }
        
        // Switch statement the price into the slot (unchecked for)
        if     (slotPosition == 0) {TokenPrices[slotIndex].price_0 = newPrice;}
        else if(slotPosition == 1) {TokenPrices[slotIndex].price_1 = newPrice;}
        else if(slotPosition == 2) {TokenPrices[slotIndex].price_2 = newPrice;}
        else if(slotPosition == 3) {TokenPrices[slotIndex].price_3 = newPrice;}
        else if(slotPosition == 4) {TokenPrices[slotIndex].price_4 = newPrice;}
        else if(slotPosition == 5) {TokenPrices[slotIndex].price_5 = newPrice;}
        else if(slotPosition == 6) {TokenPrices[slotIndex].price_6 = newPrice;}
        else if(slotPosition == 7) {TokenPrices[slotIndex].price_7 = newPrice;}
        else if(slotPosition == 8) {TokenPrices[slotIndex].price_8 = newPrice;}
        else if(slotPosition == 9) {TokenPrices[slotIndex].price_9 = newPrice;}
        else if(slotPosition == 10) {TokenPrices[slotIndex].price_10 = newPrice;}
        else if(slotPosition == 11) {TokenPrices[slotIndex].price_11 = newPrice;}
        else if(slotPosition == 12) {TokenPrices[slotIndex].price_12 = newPrice;}
        else if(slotPosition == 13) {TokenPrices[slotIndex].price_13 = newPrice;}
        else if(slotPosition == 14) {TokenPrices[slotIndex].price_14 = newPrice;}
        else if(slotPosition == 15) {TokenPrices[slotIndex].price_15 = newPrice;}

        return true;
    }

    /** 
    *   @dev Gets price for token tokenId
    */
    function getTokenPrice(uint256 tokenId) public returns (uint256 tokenPrice) {

        uint256 slotIndex;
        uint256 slotPosition;
        // Figure out which price we are referring to
        unchecked{
            slotIndex = tokenId / pricesPerSlot;
            slotPosition = tokenId % pricesPerSlot;
        }
        
        /// @dev These are unchecked math blocks, it is your responsibility to make sure that the 
        /// price doesn't overflow. This is unrealistic anyway.

        // Effectively a switch statement
        if     (slotPosition == 0) {unchecked{tokenPrice=TokenPrices[slotIndex].price_0 * multiplier;}}
        else if(slotPosition == 1) {unchecked{tokenPrice=TokenPrices[slotIndex].price_1 * multiplier;}}
        else if(slotPosition == 2) {unchecked{tokenPrice=TokenPrices[slotIndex].price_2 * multiplier;}}
        else if(slotPosition == 3) {unchecked{tokenPrice=TokenPrices[slotIndex].price_3 * multiplier;}}
        else if(slotPosition == 4) {unchecked{tokenPrice=TokenPrices[slotIndex].price_4 * multiplier;}}
        else if(slotPosition == 5) {unchecked{tokenPrice=TokenPrices[slotIndex].price_5 * multiplier;}}
        else if(slotPosition == 6) {unchecked{tokenPrice=TokenPrices[slotIndex].price_6 * multiplier;}}
        else if(slotPosition == 7) {unchecked{tokenPrice=TokenPrices[slotIndex].price_7 * multiplier;}}
        else if(slotPosition == 8) {unchecked{tokenPrice=TokenPrices[slotIndex].price_8 * multiplier;}}
        else if(slotPosition == 9) {unchecked{tokenPrice=TokenPrices[slotIndex].price_9 * multiplier;}}
        else if(slotPosition == 10) {unchecked{tokenPrice=TokenPrices[slotIndex].price_10 * multiplier;}}
        else if(slotPosition == 11) {unchecked{tokenPrice=TokenPrices[slotIndex].price_11 * multiplier;}}
        else if(slotPosition == 12) {unchecked{tokenPrice=TokenPrices[slotIndex].price_12 * multiplier;}}
        else if(slotPosition == 13) {unchecked{tokenPrice=TokenPrices[slotIndex].price_13 * multiplier;}}
        else if(slotPosition == 14) {unchecked{tokenPrice=TokenPrices[slotIndex].price_14 * multiplier;}}
        else if(slotPosition == 15) {unchecked{tokenPrice=TokenPrices[slotIndex].price_15 * multiplier;}}

        // Make sure the user is not minting beyond set prices (unless free mints are allowed)
        if(tokenPrice==0 && !FREE_MINT_ALLOWED){
            revert NoFreeMint();
        }
    }

    constructor() ERC721A("Non Fungible Price Token", "NFPT")
    {}


    function safeMint(address to, uint256 _numberToMint) public payable {
        
        if(CURRENT_SUPPLY + _numberToMint > MAX_SUPPLY){
            revert CannotMintMoreThanMaximum();
        }

        uint256 priceRequired;

        // Calculate price required for single
        if(_numberToMint == 1){
            priceRequired = getTokenPrice(CURRENT_SUPPLY+1);
        }
        // and multiple mints
        else{
            for(uint256 i=0; i<_numberToMint; i++){
                priceRequired += getTokenPrice(CURRENT_SUPPLY+1 + i);
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
