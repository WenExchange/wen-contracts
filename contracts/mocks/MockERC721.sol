// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC721 is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    constructor()
        ERC721("MyToken", "MTK")
        Ownable()
    {    }

    uint256 public tokenId = 0;
    event NewMint(uint256 tokenId, address owner);

    function safeMint(address to, string memory uri)
        public
        onlyOwner
    {
        tokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit NewMint(tokenId, to);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}