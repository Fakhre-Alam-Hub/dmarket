// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// contract Marketplace for buying and selling NFTs
contract NFTMarketplace is ReentrancyGuard {
	using Counters for Counters.Counter;
	Counters.Counter private _itemIds;
	Counters.Counter private _itemsSold;

	uint256 listingPrice = 0.025 ether;
	address payable owner;

	constructor() {
		owner = payable(msg.sender);
	}

	struct MarketItem {
		uint256 itemId;
		address nftContract;
		uint256 tokenId;
		address payable seller;
		address payable owner;
		uint256 price;
		bool sold;
	}

	mapping(uint256 => MarketItem) private idToMarketItem;

	event MarketItemCreated(
		uint256 indexed itemId,
		address indexed nftContract,
		uint256 indexed tokenId,
		address payable seller,
		address payable owner,
		uint256 price,
		bool sold
	);

	/* Returns the listing price of the contract */
	function getListingPrice() public view returns (uint256) {
		return listingPrice;
	}

	/* Updates the listing price of the contract */
	function updateListingPrice(uint256 _listingPrice) public payable {
		require(owner == msg.sender, "Only marketplace owner can update listing price.");
		listingPrice = _listingPrice;
	}

	// function to create a new token and add it to the marketplace
	function createMarketItem(
		address nftContract,
		uint256 tokenId,
		uint256 price
	) public payable nonReentrant {
		require(price > 0, "Price must be at least 1 wei");
		require(msg.value == listingPrice, "Price must be equal to listing price");

		_itemIds.increment();
		uint256 itemId = _itemIds.current();

		idToMarketItem[tokenId] = MarketItem(
			itemId,
			nftContract,
			tokenId,
			payable(msg.sender),
			payable(address(0)),
			price,
			false
		);

		IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

		emit MarketItemCreated(
			itemId,
			nftContract,
			tokenId,
			payable(msg.sender),
			payable(address(0)),
			price,
			false
		);
	}

	// function to buy nft
	function createMarketSale(address nftContract, uint256 itemId) public payable nonReentrant {
		uint256 price = idToMarketItem[itemId].price;
		uint256 tokenId = idToMarketItem[itemId].tokenId;
		require(
			msg.value == price,
			"Please submit the asking price in order to complete the purchase"
		);

		// transfer money to seller
		idToMarketItem[itemId].seller.transfer(msg.value);
		// transfer asset to buyer
		IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
		// update the owner of the token
		idToMarketItem[itemId].owner = payable(msg.sender);
		idToMarketItem[itemId].sold = true;
		_itemsSold.increment();
		payable(owner).transfer(listingPrice);
	}

	/* Returns all unsold market items */
	function fetchMarketItems() public view returns (MarketItem[] memory) {
		uint256 itemCount = _itemIds.current();
		uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
		uint256 currentIndex = 0;

		MarketItem[] memory items = new MarketItem[](unsoldItemCount);
		for (uint256 i = 0; i < itemCount; i++) {
			// if owner is 0 address, then it is not sold
			if (idToMarketItem[i + 1].owner == address(0)) {
				uint256 currentId = idToMarketItem[i + 1].itemId;
				MarketItem storage currentItem = idToMarketItem[currentId];
				items[currentIndex] = currentItem;
				currentIndex += 1;
			}
		}
		return items;
	}

	/* Returns only items that a user owns */
	function fetchMyNFTs() public view returns (MarketItem[] memory) {
		uint256 totalItemCount = _itemIds.current();
		uint256 itemCount = 0;
		uint256 currentIndex = 0;

		// get total nymber of items I own
		for (uint256 i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + 1].owner == msg.sender) {
				itemCount += 1;
			}
		}

		MarketItem[] memory items = new MarketItem[](itemCount);
		for (uint256 i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + 1].owner == msg.sender) {
				uint256 currentId = idToMarketItem[i + 1].itemId;
				MarketItem storage currentItem = idToMarketItem[currentId];
				items[currentIndex] = currentItem;
				currentIndex += 1;
			}
		}
		return items;
	}

	/* Returns only items a user has created */
	function fetchItemsCreated() public view returns (MarketItem[] memory) {
		uint256 totalItemCount = _itemIds.current();
		uint256 itemCount = 0;
		uint256 currentIndex = 0;

		for (uint256 i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + 1].seller == msg.sender) {
				itemCount += 1;
			}
		}

		MarketItem[] memory items = new MarketItem[](itemCount);
		for (uint256 i = 0; i < totalItemCount; i++) {
			if (idToMarketItem[i + 1].seller == msg.sender) {
				uint256 currentId = idToMarketItem[i + 1].itemId;
				MarketItem storage currentItem = idToMarketItem[currentId];
				items[currentIndex] = currentItem;
				currentIndex += 1;
			}
		}
		return items;
	}
}
