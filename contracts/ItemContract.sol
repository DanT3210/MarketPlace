// SPDX-License-Identifier:MIT

pragma solidity ^0.8.15;
//@Title: Online Trade Marker (blockchain eBay)
//@author: Dant3210
//@notice: Functions Contract
//@dev: Contract under development (work in progress )
//@version: remix

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ItemFunctionality.sol";

error PFuntionalities__NotSeller();

contract ItemContract is ItemFunctionality{

    event Shipped(uint256 id,address from,string trackNo,address to, uint256 dateTime);

    //  (0)    (1)    (2)      (3)        (4)      (5)        (6)       
    //{Listed,Sold, Shipped,  Rejected, Canceled, Acepted, Unlisted}
    struct Item{string brand; string model; string description; uint256 itemPrice; string size; uint8 status;} 
    struct Order{uint256 itemID; address to; uint256 QTY; uint8 status;}

    uint256 private itemID;
    uint256 private orederNo;

    //Mapping ItemID to owner of the item
    mapping(uint256=>mapping(address=>Item)) private ItemList; 
    //Mapping Item(s) in process (OrderNo->Seller-OrderDetail)
    mapping(uint256=>mapping(address=>Order))private ItemOrders;

    receive() external payable {}

     //MODIFIERS//
     modifier onlySeller(uint id, address seller){
        _checkSeller(id,seller);
        _;
     }

     modifier itemOwner(uint256 id, address account){
         _checkItemOwner(id, account);
         _;
     }

    //ModifierBuyer

     //READ PUBLIC FUNCTIONS//
    function _activeItem(uint256 id)public itemOwner(id, _msgSender()){
        ItemList[id][_msgSender()].status=0;
    }

    function SellerList(uint256 id, address _account) public view returns (Item memory) {
        return ItemList[id][_account];
    } 

    function checkOrder(uint256 id,address seller)public view returns(Order memory){
        return ItemOrders[id][seller];
    }

    function getStatus(uint256 id,address _account)public view returns(uint8){
        return ItemList[id][_account].status;
    }

    //OWNER/DEVELOPER FEE PER COMPLETED TX//
    function devFeeCalculation(uint256 _itemPrice)private pure returns(uint256){
        return (_itemPrice*5/100);
    }    

    //PRIVATE SMALL FUNCTIONS//
    function _checkSeller(uint256 id, address seller)private view{
        if(ItemList[id][seller].itemPrice==0){revert PFuntionalities__NotSeller();}
    }

    //REMANE THIS FUNC TO *OWNUNPUBLISH_ITEM* AS WELL AS THE MODIFIER//
    function _checkItemOwner(uint256 id, address account)private view{
        require(ItemList[id][account].status==6, "ERROR: Item not found");
    }

    function _incrementID(uint256 count)private pure returns(uint256){
        return count+1;
    }

    function _updateStatus(uint8 count, uint orderNo, address seller)private{
        ItemOrders[orderNo][seller].status=count;
    }

    function _checkStatus(uint orderNo, address seller)private view returns(uint8){
        return ItemOrders[orderNo][seller].status;
    }

    function _removeItem(uint256 id, address seller)private{
        delete ItemList[id][seller];
    }

    //ADD TO ORDER MAPPING//
    function _itemBought(uint256 id, address seller, uint256 qty)private{
        
        ItemOrders[orederNo][seller]=Order(id,_msgSender(),qty,1);
        orederNo=_incrementID(orederNo);
    }

    function _itemInprocess(uint256 id, address seller)private{
        Item memory newItemBouhgt=ItemList[id][seller];
        newItemBouhgt.status=6;

        address tempOwner=_msgSender();

        ItemList[id][tempOwner]=newItemBouhgt;
    }
    

    //ACTION FUNCTIONS//
    function PublishSingle(string memory _brand, string memory _model, string memory _description,uint256 _price, string memory _size)public{
        address seller=_msgSender();
        _mint(seller, itemID, 1);
        ItemList[itemID][seller]=Item(_brand, _model,_description,_price,_size, 0);
        itemID=_incrementID(itemID);
    }

    function PublishBatch(uint256[] memory ids, string[] memory _brand, string[] memory _model, string[] memory _description, uint256[] memory amounts, string[] memory _size, uint256[] memory qty)public{
        address seller=_msgSender();
        //uint256[] memory iQTY=new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
           uint256 id = ids[i]; 
           ItemList[id][seller]=Item(_brand[i], _model[i],_description[i],amounts[i],_size[i],0);
           //iQTY[i]=qty[i];
           itemID=_incrementID(itemID);
        }        

        _mintBatch(seller, ids, qty);
    }

    function RemoveSingleItem(uint256 id)external onlySeller(id, _msgSender()){
        address seller=_msgSender();
        uint8 iStatus=getStatus(id, seller);

        require (iStatus==4 || iStatus==0, "ERROR: Can't delete");

        _burn(seller, id, 1);
        _removeItem(id,seller);
    }

    function RemoveBatchItems(uint256[] memory ids, uint256[] memory qty) external{
        address seller=_msgSender();

        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];             
            _checkSeller(id,seller);//SELLER MODIFIER//

            uint8 iStatus=getStatus(ids[i], seller);
            require (iStatus==4 || iStatus==0, "ERROR: Can't delete"); 
        
            _removeItem(id,seller);
        }

        _burnBatch(seller,ids,qty);    
    }

    function BuySingleItem(uint256 id, address seller)external payable{
        address buyer=_msgSender();
        uint256 amount=ItemList[id][seller].itemPrice;
        uint256 qtyTotal=item_qty(seller, id);

        require(msg.value>=amount,"ERROR: Not Enought Funds");
        require(qtyTotal>=1, "ERROR: Insuficient qty");

        _setApprovalForAll(seller, buyer,true);
        safeTransferFrom(seller, buyer, id, 1);

        _itemBought(id,seller,1);
        _itemInprocess(id,seller);

        
        if(qtyTotal<=1){
            _removeItem(id,seller);
        }        
    }

    /*
    *@dev: Batch buy function, call safeBatch function to relocate qty, 
    *if the qty is equal to the total items own, remove the list from previous ownr
    */
    function BuyBatchItems(uint256[] memory ids, address seller, uint256[] memory qty)external payable{
        address buyer=_msgSender();
        //uint256[] memory iQTY = new uint256[](ids.length);
        uint256 qtyTotal;
        uint256 iPrice;

        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];  

            iPrice+=(ItemList[id][seller].itemPrice*qty[i]);

            qtyTotal=item_qty(seller, id);
            uint QTY=qty[i];

            require(msg.value>=iPrice, "ERROR: Not enought funds");
            require(qtyTotal>=QTY, "ERROR: Insuficient QTY");

            _itemBought(id,seller,QTY);
            _itemInprocess(id,seller);

            if(qty[i]==qtyTotal){
                _removeItem(id,seller);
            }
        }
        assert(msg.value>=iPrice);

        _setApprovalForAll(seller, buyer,true);

        _safeBatchTransferFrom(seller, buyer, ids, qty);
    }

    function ShippingSingle(uint256 id,uint256 orderNo, string memory trackNo, address to)external{
        address from=_msgSender();
        uint8 iStatus=_checkStatus(orderNo,from);

        require(iStatus==1 || iStatus==3,"ERROR: Can't shipped");
        _updateStatus(2,orderNo,from);
        emit Shipped(id, from, trackNo, to, block.timestamp);
    }

    function ShippingBatch(uint256[] memory ids, uint256[] memory ordersNo,string[] memory tracksNo, address to)external{
        address from=_msgSender();
        uint8 iStatus;

         for(uint256 i = 0; i < ids.length; i++){
             uint256 id = ids[i];

             iStatus=_checkStatus(ordersNo[id],from);
             require(iStatus==1 || iStatus==3,"ERROR: Can't shipped");

             _updateStatus(2,ordersNo[id],from);

            emit Shipped(id, from, tracksNo[i], to, block.timestamp);
         }
    }     

    function CancelSingleBuy(uint256[] memory ids, address seller, uint256[] memory OrdersNo, uint256[] memory qty, ItemContract iAddress)external{
        address buyer=_msgSender();
        uint256 qtyTotal;

        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i]; 

            qtyTotal=iAddress.item_qty(seller, id);

            require(qtyTotal>=qty[i], "ERROR: Insuficient QTY");
            _updateStatus(6,OrdersNo[id],seller);
            //_removeOrder(id,OrdersNo[id],seller);
        }
        _setApprovalForAll(buyer, seller,true);

        _safeBatchTransferFrom(buyer, seller, ids, qty); 
    }  
}
