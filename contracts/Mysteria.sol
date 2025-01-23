// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Mysteria is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;

    enum Type { Bronze, Silver, Gold, Legendary }

    mapping(Type => string[]) public nftMetadata;
    mapping(address => mapping(Type => uint256)) public userKeys;


    constructor()
        ERC721("Mysteria", "M")
        Ownable(msg.sender)
    {
        // Add IPFS URLs for Bronze NFTs
        nftMetadata[Type.Bronze].push("ipfs://bafkreigapv2ik57x7xipeddsm73sckgzjkgmdmlqohu6tjrerqqejpy5gm");
        nftMetadata[Type.Bronze].push("ipfs://bafkreie53mqt63ttrbgmvfwnmp6nk4lhj5anfgmpbjrrutzgawjrgqgrbu");

        // Add IPFS URLs for Silver NFTs
        nftMetadata[Type.Silver].push("ipfs://bafkreibhqlr7drf3fle4jbdmgcp2d64nll4ljb33px26h5p7t2ocimbxti");
        nftMetadata[Type.Silver].push("ipfs://bafkreicryqefzi52ncxhr5mbc4mskyhonqajnrhfszxapoqrbo7dchqmoi");

        // Add IPFS URLs for Gold NFTs
        nftMetadata[Type.Gold].push("ipfs://bafkreidcikq3om3qawkjljqjfa3zzlf5qyvghynxwg2ueqnhiezfr45dum");
        nftMetadata[Type.Gold].push("ipfs://bafkreigewhuqxrfvb5lti3z6nbz6py2w2u57y7p6iyfr7ze7r4uco35uce");

        // Add IPFS URLs for Legendary NFTs
        nftMetadata[Type.Legendary].push("ipfs://bafkreiaepnvoytjtmpnsypnqgicxmyqaaqdamzk2ksx3inyxmspr6hqnvi");
        nftMetadata[Type.Legendary].push("ipfs://bafkreicb2o2qars54mut7nfao3uobmvqaryjagzas326v7g33aumepseeu");
    }

    function buyKey(Type keyType) external payable {
        uint256 price = (uint256(keyType) + 1) * 1 ether;
        require(msg.value >= price, "Insufficient funds to buy the key");

        userKeys[msg.sender][keyType] += 1;

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function useKeyWithGasSponsor(Type keyType) external {
        require(userKeys[msg.sender][keyType] > 0, "You don't have enough keys for this type");
        require(address(this).balance >= tx.gasprice * gasleft(), "Contract doesn't have enough balance to sponsor gas");

        userKeys[msg.sender][keyType] -= 1;

        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, _nextTokenId))
        ) % nftMetadata[keyType].length;

        string memory selectedMetadata = nftMetadata[keyType][randomIndex];

        safeMint(msg.sender, selectedMetadata);

        // Sponsor the gas by sending ETH to the user
        uint256 gasCost = tx.gasprice * gasleft();
        (bool success, ) = msg.sender.call{value: gasCost}("");
        require(success, "Gas sponsorship failed");
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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
}
