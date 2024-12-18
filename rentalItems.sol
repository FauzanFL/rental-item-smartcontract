// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RentalContract {
    struct Item {
        uint256 id;
        string name;
        address payable owner;
        uint256 rentalPrice;
        uint256 stock;
    }

    struct Rental {
        uint256 itemId;
        string itemName;
        address payable renter;
        uint256 amount;
        uint256 startTime;
        bool isReturned;
    }

    uint256 private nextItemId;
    mapping (uint256 => Item) private items;
    mapping (uint256 => Rental) private rentals;

    event ItemListed(uint256 itemId, string name, uint256 rentalPrice, uint256 stock);
    event ItemRented(uint256 itemId, address renter);
    event ItemReturned(uint256 itemId, address renter);
    event OwnerConfirmedReturn(uint256 itemId, address owner);

    function listItem(string memory _name, uint256 _rentalPrice, uint256 _stock) public {
        require(_rentalPrice > 0, "Rental price must be greater than 0");
        require(_stock > 0, "Stock must be greater than 0");
        
        items[nextItemId] = Item({
            id: nextItemId,
            name: _name,
            stock: _stock,
            owner: payable(msg.sender),
            rentalPrice: _rentalPrice
        });

        emit ItemListed(nextItemId, _name, _rentalPrice, _stock);
        nextItemId++;
    }

    function rentItem(uint256 _itemId, uint256 _amount) public payable  {
        Item storage item = items[_itemId];
        require(item.id != 0, "Item does not exist");
        require(msg.value == item.rentalPrice, "Incorrect rental price");
        require(item.owner != msg.sender, "Owner can not rent its item");
        require(item.stock > 0, "Item is out of stock");
        require(item.stock >= _amount, "Not enough item to rent");

        item.stock -= _amount;
            
        rentals[_itemId] = Rental({
            itemId: _itemId,
            itemName: item.name,
            renter: payable(msg.sender),
            startTime: block.timestamp,
            amount: _amount,
            isReturned: false
        });

        item.owner.transfer(msg.value);

        emit ItemRented(_itemId, msg.sender);
    }

    function returnItem(uint256 _itemId, uint256 _amount) public {
        Rental storage rental = rentals[_itemId];
        require(rental.itemId != 0, "Rental does not exist");
        require(rental.renter == msg.sender, "Only renter can return the item");
        require(!rental.isReturned, "Item already returned");
        require(rental.amount == _amount, "Must return all amount of item rented");

        rental.isReturned = true;

        emit ItemReturned(_itemId, msg.sender);
    }

    function confirmReturn(uint256 _itemId) public {
        Item storage item = items[_itemId];
        require(item.id != 0, "Item does not exist");
        require(item.owner == msg.sender, "Only owner can confirm return");
        require(rentals[_itemId].isReturned, "Item has not been returned");

        emit OwnerConfirmedReturn(_itemId, msg.sender);
    }

    function getRentals() external view returns (
        uint256[] memory itemIds,
        string[] memory itemNames,
        address[] memory renters,
        uint256[] memory amounts,
        uint256[] memory startTimes,
        bool[] memory isReturned
    ) {
        uint256 totalItems = nextItemId;
        uint256[] memory rentalItemIds = new uint256[](totalItems);
        string[] memory rentalItemNames = new string[](totalItems);
        address[] memory rentalRenters = new address[](totalItems);
        uint256[] memory rentalAmounts = new uint256[](totalItems);
        uint256[] memory rentalStartTimes = new uint256[](totalItems);
        bool[] memory rentalIsReturned = new bool[](totalItems);

        for (uint256 i = 0; i < totalItems; i++) {
            rentalItemIds[i] = rentals[i].itemId;
            rentalItemNames[i] = rentals[i].itemName;
            rentalRenters[i] = rentals[i].renter;
            rentalAmounts[i] = rentals[i].amount;
            rentalStartTimes[i] = rentals[i].startTime;
            rentalIsReturned[i] = rentals[i].isReturned;
        }

        return (rentalItemIds, rentalItemNames, rentalRenters, rentalAmounts, rentalStartTimes, rentalIsReturned);
    }
}