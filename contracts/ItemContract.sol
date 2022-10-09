// SPDX-License-Identifier:MIT

pragma solidity ^0.8.15;
//@Title: Online Trade Marker (blockchain eBay)
//@author: Dant3210
//@notice: Functions Contract
//@dev: Contract under development (work in progress )
//@version: remix

import "./ItemFunctionality.sol";

error PFuntionalities__NotSeller();

contract ItemContract is ItemFunctionality{

    event Shipped(uint256 id,address from,string trackNo,address to, uint256 dateTime);

    //  (0)    (1)    (2)      (3)        (4)      (5)       (6)       
    //{Listed,Sold, Shipped,  Rejected, Canceled, Acepted, Unlisted}
    struct Item{string brand; string model; string description; uint256 itemPrice; string size; uint8 status;} 
    struct Order{uint256 orderID; address to; uint256 QTY; uint8 status;}

    //Item private itemStatus; 
    uint256 private itemID;
    uint256 public orederNo;

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
        address iOwner=_msgSender();
        ItemList[id][iOwner].status=0;
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

    function _checkItemOwner(uint256 id, address account)private view{
        require(ItemList[id][account].status==6, "ERROR: Item not found");
    }

    function _incrementID(uint256 count)private pure returns(uint256){
        return count+1;
    }

    function _updateStatus(uint8 count, uint id, address seller)private{
        ItemList[id][seller].status=count;
    }

    function _checkStatus(uint id, address seller)private view returns(uint8){
        return ItemList[id][seller].status;
    }

    //ADD TO ORDER MAPPING//
    function _itemBought(uint256 id, address seller)private{
        /*Item memory newItemBouhgt=ItemList[id][seller];
        newItemBouhgt.status=6;

        address newItemOwner=_msgSender();

        ItemList[id][newItemOwner]=newItemBouhgt;*/
        
        
        ItemOrders[orederNo][seller]=Order(id,_msgSender(),1,1);
        orederNo=_incrementID(orederNo);
        
    }
    

    //ACTION FUNCTIONS//
    function PublishSingle(string memory _brand, string memory _model, string memory _description,uint256 _price, string memory _size)public{
        address _account=_msgSender();
        _mint(_account, itemID, 1);
        ItemList[itemID][_account]=Item(_brand, _model,_description,_price,_size, 0);
        itemID=_incrementID(itemID);
    }

    function PublishBatch(uint256[] memory ids, string[] memory _brand, string[] memory _model, string[] memory _description, uint256[] memory amounts, string[] memory _size, uint256[] memory qty)public{
        address _account=_msgSender();
        uint256[] memory iQTY=new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
           uint256 id = ids[i]; 
           ItemList[id][_account]=Item(_brand[i], _model[i],_description[i],amounts[i],_size[i],0);
           iQTY[i]=qty[i];
           itemID=_incrementID(itemID);
        }        

        _mintBatch(_account, ids, iQTY);
    }

    function RemoveSingleItem(uint256 id)external onlySeller(id, _msgSender()){
        address seller=_msgSender();
        uint8 iStatus=getStatus(id, seller);

        require (iStatus==4 || iStatus==0, "ERROR: Can't delete");

        _burn(seller, id, 1);
        delete ItemList[id][seller];
    }

    function RemoveBatchItems(uint256[] memory ids, uint256[] memory qty) external{
        address seller=_msgSender();
        //uint256[] memory iQTY = new uint256[](ids.length);

        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];             
            _checkSeller(id,seller);//SELLER MODIFIER//

            uint8 iStatus=getStatus(ids[i], seller);
            require (iStatus==4 || iStatus==0, "ERROR: Can't delete"); 
            
            //iQTY[i] = qty[i];
            delete ItemList[id][seller];
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

        //itemBuyer[id][seller]=buyer;
        //_updateStatus(2, id, seller);
        _itemBought(id,seller);
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

            //iQTY[i] = qty[i];
            qtyTotal=item_qty(seller, id);
            uint QTY=qty[i];

            require(msg.value>=iPrice, "ERROR: Not enought funds");
            require(qtyTotal>=QTY, "ERROR: Insuficient QTY");
            

            for(uint256 j = 1; j <= QTY; j++) {
                _itemBought(id,seller);
            }
            /*if(qty[i]==item_qty(seller, id)){
                delete ItemList[id][seller];
            }*/
        }
        assert(msg.value>=iPrice);

        _setApprovalForAll(seller, buyer,true);

        _safeBatchTransferFrom(seller, buyer, ids, qty);
    }

    function Shipping(uint256 id, string memory trackNo, address to)external onlySeller(id, _msgSender()){
        address from=_msgSender();
        uint8 iStatus=_checkStatus(id,from);

        require(iStatus==1 || iStatus==3,"ERROR: Can't shipped");

        _updateStatus(2,id,from);

        emit Shipped(id, from, trackNo, to, block.timestamp);
    }


}