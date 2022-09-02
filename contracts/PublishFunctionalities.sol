// SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;
        //@Title: Online Trade Marker (blockchain eBay)
        //@author: Dant3210
        //@notice: Functions Contract
        //@dev: Contract under development (work in progress )

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

error PFuntionalities_NotBuyer();
error PFuntionalities_NotSeller();
error PFuntionalities_NotActive();
error PFuntionalities_NotListed();

import "./PublishOracle.sol";

//address payable constant DEVELOPER=payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);

contract PublishFunctionalities is ReentrancyGuard, Context, Ownable, PublishOracle {

    struct ItemListed {
        string brand;
        string model;
        string description;
        ItemStatus item_status;
        uint256 itemPrice; 
        string size;
        uint256 uniqueTag;
        bool active;
    } 
    
    enum ItemStatus{Listed,Sold, Shipped, Received, Return_Request, Canceled, Completed, Returned, Accept}
    ItemStatus private item_status;  
    uint256 private txDuration;

    event EventLog(address indexed  _user, string indexed _status,uint indexed Tag, uint _date); 
    event ShippedItem(address indexed _buyer, uint indexed Tag, uint256 _trackNo, uint _date);
    event ReceivedItem(address indexed _buyer, uint indexed Tag, string _reviewNote, uint _date);    

    mapping(address=>ItemListed[]) private listedItems;  //Item's Seller(s) list
    mapping(uint256=>address) private itemBuyers;   //Item's Buyer(s) list (*based on a unique TAG fiel)
    //mapping(address=>uint) private sellersStars; //List to check the best sellers *Implement WhiteList*
    

//*********INTERNAL MODIFIERS***********************************************************************************************************
    modifier onlyBuyer(uint _id, address _buyer){
        if(itemBuyers[_id]!=_buyer){ revert PFuntionalities_NotBuyer();}
        //require(itemBuyers[_id]==_buyer, NotOwner()/*"You're not the Buyer of this Item"*/);
        _;
    }

    modifier onlySeller(uint256 _id, address _seller){
        if(listedItems[_seller][_id].itemPrice<=0){revert PFuntionalities_NotSeller();}
        //require(listedItems[_seller][_id].itemPrice>0, "You're not the Seller of this Item");
        _;
    }    

    modifier itemActive(uint256 _id, address _seller){
        if(!listedItems[_seller][_id].active){revert PFuntionalities_NotActive();}
        //require(listedItems[_seller][_id].active, "ERROR: Item is not active");
        _;
    }

    modifier isListed(uint256 _id, address _seller){
        if(listedItems[_seller][_id].item_status!=ItemStatus.Listed){revert PFuntionalities_NotListed();}
        //require(listedItems[_seller][_id].item_status==ItemStatus.Listed, "ERROR: Item is not longer Listed");
        _;
    }
//**************************************************************************************************************************************
    receive() external payable {}

    function _removeBuyers(uint256 _id)internal virtual{
        delete itemBuyers[_id];
    } 

    function _totalValue()internal view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    function sellerItemList(address account) public view virtual returns (ItemListed[] memory) {
        return listedItems[account];
    } 

    /*function itemListed(address account, uint256 _id) public view virtual returns (ItemListed memory) {
        return listedItems[account][_id];
    } */

    function buyers(uint256 _id) public view virtual returns (address) {
        return itemBuyers[_id];
    } 

    function devFeeCalculation(uint256 _itemPrice)internal view virtual returns(uint256){
        return (_itemPrice*5/1000);
    }

    //Move status based on activity
    function nextStatus(uint _d) internal view virtual returns (ItemStatus){
        return ItemStatus(uint(item_status) +_d);
    } 

    function nextStatus() internal view virtual returns (ItemStatus){
        return ItemStatus(uint(item_status) -1);
    } 
    
    function _getTransaction_Time()internal view onlyOwner returns(uint256) {
        return txDuration;
    }

    //SELLER FUNCTIONALITIES//
    function _AddItem(string memory _brand, string memory _model, string memory _description,uint256 _price, string memory _size, uint256 _uniqueTag, address _seller) internal virtual nonReentrant{
        require(_seller != address(0), "ERROR: action to the zero address");
        require(_price>0, "ERROR: Item price can't be 0.00");
        listedItems[_seller].push(ItemListed(_brand, _model,_description,item_status,_price,_size, _uniqueTag, true));
        emit EventLog(_seller, "Listed",_uniqueTag, block.timestamp);
    }    

    function _updatePrice(uint _id, uint _newPrice, address _seller)internal virtual onlySeller(_id, _seller) isListed(_id,_seller){
        require(_newPrice>0, "ERROR: Price can't be 0");
        listedItems[_seller][_id].itemPrice=_newPrice;
        emit EventLog(_seller, "Price updated",listedItems[_seller][_id].uniqueTag, block.timestamp);
    }      

    function _unPublish(uint _id, address _seller)internal virtual onlySeller(_id, _seller) itemActive(_id,_seller){
        require(listedItems[_seller][_id].item_status!=ItemStatus.Shipped || listedItems[_seller][_id].item_status!=ItemStatus.Sold
        || listedItems[_seller][_id].item_status!=ItemStatus.Return_Request || listedItems[_seller][_id].item_status!=ItemStatus.Completed, "ERROR: Can't removed item");
        delete listedItems[_seller][_id];
    }   

    function _deactivate(uint _id, address _seller)internal virtual onlySeller(_id, _seller) itemActive(_id, _seller) isListed(_id,_seller){
        listedItems[_seller][_id].active=false;
    }   

    function _activate(uint _id, address _seller)internal virtual onlySeller(_id, _seller) isListed(_id,_seller){
        require(listedItems[_seller][_id].active==false, "ERROR: Item's Active");
        listedItems[_seller][_id].active=true;
    }   

    function _relistItem(uint _id, address _seller) internal onlySeller(_id, _seller){
        //ItemListed memory internalItem=listedItems[_seller][_id];
        require(listedItems[_seller][_id].item_status==ItemStatus.Canceled || listedItems[_seller][_id].item_status==ItemStatus.Returned, "ERROR: Item can't be relisted");
        require(listedItems[_seller][_id].active, "ERROR: Item is active");
        listedItems[_seller][_id].item_status=nextStatus(0);
        emit EventLog(_seller, "Item Relisted",listedItems[_seller][_id].uniqueTag,block.timestamp);
    }    

    function _shippedItem(uint256 _trackNo, uint _id, address _seller) internal virtual onlySeller(_id, _seller) itemActive(_id, _seller){
        require(listedItems[_seller][_id].item_status==ItemStatus.Sold, "ERROR: Item has been sold");
        require(address(this).balance>=listedItems[_seller][_id].itemPrice, "ERROR: Not enought funds");
        require(txDuration>=block.timestamp, "ERROR: Shipping windows expired");
        listedItems[_seller][_id].item_status=nextStatus(2);
        emit ShippedItem(_seller, listedItems[_seller][_id].uniqueTag,_trackNo, block.timestamp);
        txDuration=addShippingTime_Orc();
    }         

    function _realeaseFunds(uint _id, address _seller) internal virtual onlySeller(_id, _seller) nonReentrant itemActive(_id, _seller){
        //Update this condition, maybe an IF with multiple checks
        require(txDuration>0, "ERROR: Item hasn't been sold");
        require (listedItems[_seller][_id].item_status==ItemStatus.Received && (block.timestamp>=txDuration), "ERROR: Can't release funds yet");
        require(address(this).balance>=listedItems[_seller][_id].itemPrice, "ERROR: Not enought funds");
        uint devTax=devFeeCalculation(listedItems[_seller][_id].itemPrice);
        payable (owner()).transfer(devTax);
        payable (_seller).transfer(listedItems[_seller][_id].itemPrice-devTax);
        listedItems[_seller][_id].item_status=nextStatus(6);
        emit EventLog(_seller,"Fund released",listedItems[_seller][_id].uniqueTag, block.timestamp); 
        txDuration=0;
    }    

    function _acceptReturn(uint _id, address _seller)internal virtual onlySeller(_id, _seller) itemActive(_id, _seller){
        require(listedItems[_seller][_id].item_status==ItemStatus.Return_Request, "ERROR: Not returned");
        listedItems[_seller][_id].item_status=nextStatus(8);
    }

    function _receivedReturn(uint _id, address _seller) internal virtual onlySeller(_id, _seller){
        require(listedItems[_seller][_id].item_status==ItemStatus.Shipped, "ERROR Item hasn't been shipped");
        listedItems[_seller][_id].item_status=nextStatus(7);
        _removeBuyers(listedItems[_seller][_id].uniqueTag);
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------//

    //BUYER FUNCTIONALITIES// 
    function _buyItem(address _seller, uint _id, address buyer) internal virtual itemActive(_id, _seller) isListed(_id,_seller) nonReentrant{
        //ItemListed memory internalItem=listedItems[_seller][_id];
        require(_seller!=buyer, "ERROR: You're the seller");
        require(listedItems[_seller][_id].itemPrice<=(msg.value), "ERROR: Need more funds");
        require(_seller != address(0), "ERROR: action to the zero address");
        listedItems[_seller][_id].item_status=nextStatus(1);
        itemBuyers[listedItems[_seller][_id].uniqueTag]=buyer;
        emit EventLog(buyer, "Bought",listedItems[_seller][_id].uniqueTag, block.timestamp);
        txDuration=updateTime_Orc();
    }  

    function _cancelTransaction(address _seller,uint _id, address buyer, string calldata reason) internal virtual onlyBuyer(listedItems[_seller][_id].uniqueTag, buyer) nonReentrant{
        //ItemListed memory internalItem=listedItems[_seller][_id];
        require (listedItems[_seller][_id].item_status==ItemStatus.Sold, "ERROR: Item has been shipped");
        payable (owner()).transfer(devFeeCalculation(listedItems[_seller][_id].itemPrice)/2);
        listedItems[_seller][_id].item_status=nextStatus(5);
        payable(buyer).transfer(listedItems[_seller][_id].itemPrice-devFeeCalculation(listedItems[_seller][_id].itemPrice)/2);
        emit EventLog(buyer,reason,listedItems[_seller][_id].uniqueTag, block.timestamp);
        txDuration=0;
        _removeBuyers(listedItems[_seller][_id].uniqueTag);
    }     

    function _receivedItem(address _seller, uint _id, string calldata _review, address buyer) internal virtual onlyBuyer(listedItems[_seller][_id].uniqueTag, buyer){
        //ItemListed memory internalItem=listedItems[_seller][_id];
        require (listedItems[_seller][_id].item_status==ItemStatus.Shipped, "ERROR: Item hasn't been shipped");
        listedItems[_seller][_id].item_status=nextStatus(3);
        emit ReceivedItem(buyer, listedItems[_seller][_id].uniqueTag, _review, block.timestamp);
        txDuration=updateTime_Orc();
    }       

    function _returnItem(address _seller,uint _id, address buyer) internal virtual onlyBuyer(listedItems[_seller][_id].uniqueTag, buyer){
        // ItemListed memory internalItem=listedItems[_seller][_id];
        require (listedItems[_seller][_id].item_status!=ItemStatus.Completed, "ERROR: Sale's Closed");
        require (listedItems[_seller][_id].item_status==ItemStatus.Received, "ERROR: Item hasn't been received");
        require (block.timestamp<txDuration, "ERROR: Return Window's Close");
        listedItems[_seller][_id].item_status==nextStatus(4);
        
        
        //_removeBuyers(listedItems[_seller][_id].uniqueTag);
    }      

    function _shipReturn(address _seller,uint _id,uint _trackNo, address buyer)internal virtual onlyBuyer(listedItems[_seller][_id].uniqueTag, buyer){
        require(listedItems[_seller][_id].item_status==ItemStatus.Accept, "ERROR: Return hasn't been accepted");
        listedItems[_seller][_id].item_status==nextStatus(2);
        txDuration=addShippingTime_Orc();
        emit ShippedItem(buyer, listedItems[_seller][_id].itemPrice,_trackNo, block.timestamp);
        //_removeBuyers(listedItems[_seller][_id].uniqueTag);
    }

    function _refund(address _seller,uint _id, address buyer) internal virtual onlyBuyer(listedItems[_seller][_id].uniqueTag, buyer) nonReentrant{
        require (listedItems[_seller][_id].item_status==ItemStatus.Shipped, "ERROR: Item in progress");
        //require(condition);
        payable(buyer).transfer(listedItems[_seller][_id].itemPrice);
        listedItems[_seller][_id].item_status=item_status;
    }    
}