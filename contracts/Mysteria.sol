// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Mysteria is ERC721,ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;

    enum Type { Bronze, Silver, Gold, Legendary }

    mapping(Type => string[]) public nftMetadata;
    mapping(address => mapping(Type => uint256)) public userKeys;

    struct NFTInfo {
        uint256 tokenId;
        string tokenURI;
    }


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
        uint256 basePrice = 0.2 ether;
    
        uint256 price = basePrice + (uint256(keyType) * 0.2 ether);
        require(msg.value >= price, "Insufficient funds to buy the key");

        userKeys[msg.sender][keyType] += 1;

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function getKeys(address user) external view returns (uint256[4] memory) {
        uint256[4] memory keys;
        
        keys[0] = userKeys[user][Type.Bronze];
        keys[1] = userKeys[user][Type.Silver];
        keys[2] = userKeys[user][Type.Gold];
        keys[3] = userKeys[user][Type.Legendary];
        
        return keys;
    }

    function useKeyWithGasSponsor(Type keyType) external {
        require(userKeys[msg.sender][keyType] > 0, "You don't have enough keys for this type");

        uint256 initialGas = gasleft();

        userKeys[msg.sender][keyType] -= 1;

        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, _nextTokenId))
        ) % nftMetadata[keyType].length;

        string memory selectedMetadata = nftMetadata[keyType][randomIndex];

        safeMint(msg.sender, selectedMetadata);

        uint256 gasUsed = initialGas - gasleft();

        uint256 gasCost = tx.gasprice * gasUsed;

        require(address(this).balance >= gasCost, "Insufficient contract balance for gas sponsorship");

        (bool success, ) = payable(msg.sender).call{value: gasCost}("");
        require(success, "Gas sponsorship transfer failed");
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function getUserNFTsByType(address user, Type nftType) public view returns (NFTInfo[] memory) {
        uint256 balance = balanceOf(user);
        NFTInfo[] memory matchingNFTs = new NFTInfo[](balance);
        uint256 count = 0;
        
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            string memory uri = tokenURI(tokenId);
            
            for (uint256 j = 0; j < nftMetadata[nftType].length; j++) {
                if (keccak256(abi.encodePacked(uri)) == keccak256(abi.encodePacked(nftMetadata[nftType][j]))) {
                    matchingNFTs[count] = NFTInfo(tokenId, uri);
                    count++;
                    break;
                }
            }
        }
        
        NFTInfo[] memory result = new NFTInfo[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingNFTs[i];
        }
        
        return result;
    }

    function upgradeToSilver() external returns (NFTInfo memory) {

        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))
        ) % nftMetadata[Type.Silver].length;
        
        string memory newURI = nftMetadata[Type.Silver][randomIndex];
        
        uint256 newTokenId = _nextTokenId++;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, newURI);
        
        return NFTInfo({
            tokenId: newTokenId,
            tokenURI: newURI
        });
    }

    function _isNFTOfType(string memory uri, Type nftType) internal view returns (bool) {
        for (uint256 i = 0; i < nftMetadata[nftType].length; i++) {
            if (keccak256(abi.encodePacked(uri)) == keccak256(abi.encodePacked(nftMetadata[nftType][i]))) {
                return true;
            }
        }
        return false;
    }

    function getAllUserNFTs(address user) public view returns (NFTInfo[] memory) {
        uint256 balance = balanceOf(user);
        NFTInfo[] memory userNFTs = new NFTInfo[](balance);
        
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            string memory uri = tokenURI(tokenId);
            userNFTs[i] = NFTInfo(tokenId, uri);
        }
        
        return userNFTs;
    }

    // The following functions are overrides required by Solidity.

        function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

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
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
