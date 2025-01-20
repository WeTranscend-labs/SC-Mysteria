// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MysteriaGacha is ERC721, Ownable {
    using Counters for Counters.Counter;

    enum Rarity { Common, Uncommon, Rare, Epic, Legendary }

    struct NFTAttributes {
        string name;
        string description;
        Rarity rarity;
        string imageURL;
    }

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => NFTAttributes) public nftAttributes;

    uint256 public commonCost = 2 ether;
    uint256 public rareCost = 5 ether;
    uint256 public legendaryCost = 10 ether;

    event NFTMinted(address indexed user, uint256 tokenId, Rarity rarity);
    event NFTUpgraded(address indexed user, uint256 tokenId, bool success);

    constructor() ERC721("MysteriaNFT", "MYST") Ownable(msg.sender) {}

    function mintNFT(uint256 tier) external payable {
        require(tier >= 0 && tier <= 2, "Invalid tier");
        uint256 cost;
        Rarity rarity;

        if (tier == 0) {
            cost = commonCost;
            rarity = randomRarity(95, 1, 0, 0, 0); // Common to Uncommon, 1% Rare
        } else if (tier == 1) {
            cost = rareCost;
            rarity = randomRarity(0, 90, 9, 1, 0); // Rare to Epic, 1% Legendary
        } else if (tier == 2) {
            cost = legendaryCost;
            rarity = Rarity.Legendary; // Guaranteed Legendary
        }

        require(msg.value >= cost, "Insufficient token value sent");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        nftAttributes[tokenId] = NFTAttributes({
            name: string(abi.encodePacked("Mysteria NFT #", toString(tokenId))),
            description: "A unique NFT from Mysteria",
            rarity: rarity,
            imageURL: "ipfs://placeholder_image_url"
        });

        emit NFTMinted(msg.sender, tokenId, rarity);
    }

    function upgradeNFT(uint256 tokenId) external payable {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        NFTAttributes storage attributes = nftAttributes[tokenId];
        require(attributes.rarity < Rarity.Legendary, "Cannot upgrade Legendary NFTs");

        uint256 cost = (uint256(attributes.rarity) + 1) * 2 ether;
        require(msg.value >= cost, "Insufficient token value sent");

        bool success = randomChance(70); // 70% chance to upgrade
        if (success) {
            attributes.rarity = Rarity(uint256(attributes.rarity) + 1);
        } else {
            if (attributes.rarity > Rarity.Common) {
                attributes.rarity = Rarity(uint256(attributes.rarity) - 1);
            }
        }

        emit NFTUpgraded(msg.sender, tokenId, success);
    }

    function randomRarity(uint256 commonProb, uint256 uncommonProb, uint256 rareProb, uint256 epicProb, uint256 legendaryProb) private view returns (Rarity) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 100;

        if (random < commonProb) {
            return Rarity.Common;
        } else if (random < commonProb + uncommonProb) {
            return Rarity.Uncommon;
        } else if (random < commonProb + uncommonProb + rareProb) {
            return Rarity.Rare;
        } else if (random < commonProb + uncommonProb + rareProb + epicProb) {
            return Rarity.Epic;
        } else {
            return Rarity.Legendary;
        }
    }

    function randomChance(uint256 successRate) private view returns (bool) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 100;
        return random < successRate;
    }

    function toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
