// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./ERC721A.sol";


contract Basic_NFT is ERC721A, Ownable{
    
    error CannotMintMoreThanMaximum();
    error SendMoreEther();

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public CURRENT_SUPPLY = 0;
    string public baseUri = "";

    constructor() ERC721A("Name", "Symbol")
    {}


    function safeMint(address to, uint256 _numberToMint) public payable {
        
        if(CURRENT_SUPPLY + _numberToMint > MAX_SUPPLY){
            revert CannotMintMoreThanMaximum();
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
