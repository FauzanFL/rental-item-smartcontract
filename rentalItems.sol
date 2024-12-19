// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RentalContract {

    struct Rental {
        uint256 rentalId;
        uint256 itemId;
        string itemName;
        address renter;
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
        bool isReturned;
    }

    struct Item {
        uint256 id;
        string name;
        uint256 stock;
    }

    uint256 private nextRentalId;
    mapping (uint256 => Rental) private rentals;
    mapping (uint256 => Item) private items;

    event RentalCreated(
        uint256 indexed rentalId,
        uint256 indexed itemId,
        address indexed renter,
        string itemName,
        uint256 amount,
        uint256 startDate,
        uint256 endDate
    );

    function addItem(uint256 _itemId, string memory _name, uint256 _stock) external {
        require(items[_itemId].id == 0, "Item already exist");
        items[_itemId] = Item({id: _itemId, name: _name, stock: _stock});
    }

    function changeItemName(uint256 _itemId, string memory _name) external {
        require(items[_itemId].id != 0, "Item not found");
        items[_itemId].name = _name;
    }

    function addItemStock(uint256 _itemId, uint256 _addedAmount) external {
        require(items[_itemId].id != 0, "Item not found");
        items[_itemId].stock += _addedAmount;
    }
    
    function reduceItemStock(uint256 _itemId, uint256 _reducedAmount) external {
        require(items[_itemId].id != 0, "Item not found");
        items[_itemId].stock -= _reducedAmount;
    }

    function deleteItem(uint256 _itemId) external {
        require(items[_itemId].id != 0, "Item not found");
        delete items[_itemId];
    }

    function createRental(uint256 _itemId, uint256 _amount, uint256 _startDate, uint256 _endDate) external {
        Item storage item = items[_itemId];
        require(_startDate < _endDate, "Start time must be before end time");
        require(item.id != 0, "Item not found");
        require(item.stock >= _amount, "Not enough stock");

        item.stock -= _amount;

        rentals[nextRentalId] = Rental({
            rentalId: nextRentalId,
            itemId: _itemId,
            renter: msg.sender,
            itemName: item.name,
            amount: _amount,
            startDate: _startDate,
            endDate: _endDate,
            isReturned: false
        });

        emit RentalCreated(nextRentalId, _itemId, msg.sender, item.name, _amount, _startDate, _endDate);
        nextRentalId++;
    }

    function getRental(uint256 _rentalId) external view returns (
        uint256 rentalId,
        uint256 itemId,
        address renter,
        string memory itemName,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        bool isReturneds
    ) {
        Rental storage rental = rentals[_rentalId];
        require(rental.rentalId != 0, "Rental not found");
        require(rental.renter != address(0), "Rental transaction not found");

        return (
            rental.rentalId,
            rental.itemId,
            rental.renter,
            rental.itemName,
            rental.amount,
            rental.startDate,
            rental.endDate,
            rental.isReturned
        );
    }

    function getListRental() external view returns (
        uint256[] memory rentalIds,
        uint256[] memory itemIds,
        address[] memory renters,
        string[] memory itemNames,
        uint256[] memory amounts,
        uint256[] memory startDates,
        uint256[] memory endDates,
        bool[] memory rentIsReturneds
    ) {
        uint256 totalItems = nextRentalId;

        uint256[] memory rentRentalIds = new uint256[](totalItems);
        uint256[] memory rentItemIds = new uint256[](totalItems);
        address[] memory rentRenters = new address[](totalItems);
        string[] memory rentItemNames = new string[](totalItems);
        uint256[] memory rentAmounts = new uint256[](totalItems);
        uint256[] memory rentStartDates = new uint256[](totalItems);
        uint256[] memory rentEndDate = new uint256[](totalItems);
        bool[] memory rentIsReturned = new bool[](totalItems);

        for (uint256 i = 0; i < totalItems; i++) {
            rentRentalIds[i] = rentals[i].rentalId;
            rentItemIds[i] = rentals[i].itemId;
            rentRenters[i] = rentals[i].renter;
            rentItemNames[i] = rentals[i].itemName;
            rentAmounts[i] = rentals[i].amount;
            rentStartDates[i] = rentals[i].startDate;
            rentEndDate[i] = rentals[i].endDate;
            rentIsReturned[i] = rentals[i].isReturned;
        }

        return (rentalIds, rentItemIds, rentRenters, rentItemNames, rentAmounts, rentStartDates, rentEndDate, rentIsReturned);
    }

    function completeRental(uint256 _rentalId) external {
        Rental storage rental = rentals[_rentalId];
        require(rental.renter != address(0), "Rental transaction not found");

        items[rental.itemId].stock += rental.amount;

        rental.isReturned = true;
    }

    function isReturned(uint256 _rentalId) external view returns (bool) {
        return rentals[_rentalId].isReturned;
    }

    function getStock(uint256 _itemId) external view returns (uint256) {
        return items[_itemId].stock;
    }
}