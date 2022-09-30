// SPDX-License-Identifier:MIT

pragma solidity ^0.8.15;
        //@Title: Online Trade Marker (blockchain eBay)
        //@author: Dant3210
        //@notice: Functions Contract
        //@dev: Contract under development (work in progress )
        //@version: remix

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/utils/Context.sol";
import "./PublishOracle.sol";

error PFuntionalities__NotBuyer();
error PFuntionalities__NotSeller();
error PFuntionalities__NotActive();
error PFuntionalities__NotListed();
error PFuntionalities__NotEnoughFunds();
error PFuntionalities__NotBuyerSeller();

//import "./PublishOracle.sol";

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
    } 
    
    enum ItemStatus{Listed,Sold, Shipped, Received, Return_Request, Canceled, Completed}
    ItemStatus private item_status;  
    uint256 private txDuration;
    uint256 private itemID;

    event EventLog(address indexed  _user, string indexed _status,uint indexed Tag, uint _date,  uint price); 
    event ShippedItem(address indexed _buyer, uint indexed Tag, uint256 _trackNo, uint _date);
    event ReceivedItem(address indexed _buyer, uint indexed Tag, string _reviewNote, uint _date);  
    event WithdrawFund(address indexed _account, uint indexed _amount, uint indexed _date);  

    //mapping(address=>ItemListed[]) private listedItems;  //Item's Seller(s) list
    mapping(uint256=>mapping(address=>address)) private itemBuyers;   //Item's Buyer(s) list (* id-seller-buyer)
    mapping(address=>uint256)private balanceOff;  //Seller ledger
    mapping(uint256=>mapping(address=>ItemListed)) private listedItems; //per ID, address-List
    mapping(address=>mapping(uint256=>address))private itemCanceled;//track cancelations based on (buyer-itemID-Seller)
    
    receive() external payable {}

    ////////////////////////
    //MODIFIERS FUNCTIONS//
    //////////////////////
    function _onlyBuyer(uint _id, address _buyer, address _seller)private view{
        if(itemBuyers[_id][_seller]!=_buyer){revert PFuntionalities__NotBuyer();}
    }

    function _onlySeller(uint256 _id, address _seller)private view{
        if(listedItems[_id][_seller].itemPrice<0){revert PFuntionalities__NotSeller();}
    }

    function _buyerSeller(uint _id, address _buyer, address _seller)private view{
        if(listedItems[_id][_seller].itemPrice<0 || itemBuyers[_id][_seller]!=_buyer){revert PFuntionalities__NotBuyerSeller();}
    }

     function _isListed(uint256 _id, address _seller)private view{
        if(listedItems[_id][_seller].item_status!=ItemStatus.Listed){revert PFuntionalities__NotListed();}
    }

    function _checkPrice(uint256 _price)private pure{
        if(_price<=0){ revert PFuntionalities__NotEnoughFunds(); }
    }
    //**********************************************************************************************************************************************
    function _getStatus(uint _id, address _account)public view returns(ItemStatus){
        return listedItems[_id][_account].item_status;
    }

    function sellerItemList(uint _id, address _account) public view virtual returns (ItemListed memory) {
        return listedItems[_id][_account];
    } 

    function ballanceOff(address _account)public view returns(uint){
        return balanceOff[_account];
    }

    function buyers(uint256 _id, address _seller) public view virtual returns (address) {
        return itemBuyers[_id][_seller];
    } 

    function _removeBuyers(uint256 _id, address _seller)internal virtual{
        delete itemBuyers[_id][_seller];
    } 

    function devFeeCalculation(uint256 _itemPrice)internal view virtual returns(uint256){
        return (_itemPrice*5/100);
    }
    //////////////////////////
    //SELLER FUNCTIONALITIES//
    //////////////////////////
    function _AddItem(string memory _brand, string memory _model, string memory _description,uint256 _price, string memory _size, uint256 _uniqueTag)
    external nonReentrant {
        _checkPrice(_price);
        address _seller=_msgSender();
        require(_seller != address(0), "ERROR: action from the zero address");
        listedItems[itemID][_seller]=ItemListed(_brand, _model,_description,item_status,_price,_size, _uniqueTag);
        ItemListed memory aux_List=listedItems[itemID][_seller];
        emit EventLog(_seller, "Listed",_uniqueTag, block.timestamp, aux_List.itemPrice); 
        itemID++;            
    }    

    function _updatePrice(uint _id, uint _newPrice)external{
        address _seller=_msgSender();
        _onlySeller(_id, _seller);
        _isListed(_id,_seller);
        _checkPrice(_newPrice);
        listedItems[_id][_seller].itemPrice=_newPrice;
    }      

    function _unPublish(uint _id)external{
        address _seller=_msgSender();
        _onlySeller(_id, _seller);
        _isListed(_id,_seller);
        delete listedItems[_id][_seller];
    }   
    
    function _relistItem(uint _id) external{
        address _seller=_msgSender();
        _onlySeller(_id, _seller);
        ItemListed memory aux_List=listedItems[_id][_seller];
        require(aux_List.item_status==ItemStatus.Canceled, "ERROR: Item can't be relisted");
        require(balanceOff[buyers(_id,_seller)]<=0, "ERROR: Buyer hasn't withdraw yet");
        listedItems[_id][_seller].item_status=ItemStatus.Listed;
    } 

    function _shipping(uint256 _trackNo, uint _id)external{
        _shippedItem(_trackNo, _id, _msgSender());
    }

    function _shippedItem(uint256 _trackNo, uint _id, address _seller) internal {
        _onlySeller(_id, _seller);
        ItemListed memory aux_List=listedItems[_id][_seller];
        require(aux_List.item_status==ItemStatus.Sold || aux_List.item_status==ItemStatus.Return_Request, "ERROR: Item hasn't been sold");
        require(balanceOff[_seller]>=aux_List.itemPrice, "ERROR: Not enought funds");
        require(txDuration>=block.timestamp, "ERROR: Shipping windows expired");
        listedItems[_id][_seller].item_status=ItemStatus.Shipped;
        emit ShippedItem(_seller, aux_List.uniqueTag,_trackNo, block.timestamp);
        txDuration=addShippingTime_Orc();
    }         

    function _realeaseFunds(uint _id) external nonReentrant{
        require(txDuration>0, "ERROR: Item hasn't been sold");
        address _account=_msgSender();
        ItemListed memory aux_List=listedItems[_id][_account];
        uint256 aux_iPrice=aux_List.itemPrice;
        require(balanceOff[_account]>=aux_List.itemPrice, "ERROR: No enough funds");
        require (block.timestamp>=txDuration, "ERROR: Wait few seconds more");
        uint devTax;
            if(aux_List.item_status==ItemStatus.Received){
                devTax=devFeeCalculation(aux_iPrice);
                listedItems[_id][_account].item_status=ItemStatus.Completed; 
            } else{
                require (listedItems[_id][itemCanceled[_account][_id]].item_status==ItemStatus.Canceled, "ERROR: Active Item");
                aux_iPrice= listedItems[_id][itemCanceled[_account][_id]].itemPrice;
                devTax=devFeeCalculation(aux_iPrice)/2;   
                _removeBuyers(_id,itemCanceled[_account][_id]);             
            }       
        payable (owner()).transfer(devTax);        
        payable (_account).transfer(aux_iPrice-devTax);
        emit WithdrawFund(_account, aux_iPrice-devTax, block.timestamp);
        balanceOff[_account]-=aux_iPrice;        
        txDuration=0;
    }     

    /////////////////////////
    //BUYER FUNCTIONALITIES// 
    ////////////////////////
    function _buyItem(address _seller, uint _id) external payable nonReentrant{
        address _buyer=_msgSender();
        _isListed(_id,_seller) ;
        require(_seller!=_buyer, "ERROR: You're the seller");
        ItemListed memory aux_List=listedItems[_id][_seller];
        require(aux_List.itemPrice<=(msg.value), "ERROR: Need more funds");
        balanceOff[_seller]+=aux_List.itemPrice;
        listedItems[_id][_seller].item_status=ItemStatus.Sold;
        itemBuyers[_id][_seller]=_buyer;
        emit EventLog(_buyer, "Bought",aux_List.uniqueTag, block.timestamp, aux_List.itemPrice);
        txDuration=updateTime_Orc();
    }  

    function _cancelTransaction(address _seller,uint _id, string calldata _reason) external nonReentrant{
        address _buyer=_msgSender();
        _onlyBuyer(_id,_buyer, _seller);
        ItemListed memory aux_List=listedItems[_id][_seller];
        require (aux_List.item_status==ItemStatus.Sold, "ERROR: Item has been shipped");
        balanceOff[_seller]-=aux_List.itemPrice;
        balanceOff[_buyer]+=aux_List.itemPrice;
        listedItems[_id][_seller].item_status=ItemStatus.Canceled;
        emit EventLog(_buyer,_reason,aux_List.uniqueTag, block.timestamp, aux_List.itemPrice);
        txDuration=block.timestamp;
        itemCanceled[_buyer][_id]=_seller;
    }     

    function _receivedItem(address _seller, uint _id, string calldata _review) external {
        address _buyer=_msgSender();
        _buyerSeller(_id,_buyer, _seller);
        ItemListed memory aux_List=listedItems[_id][_seller];
        require (aux_List.item_status==ItemStatus.Shipped, "ERROR: Item hasn't been shipped");
        listedItems[_id][_seller].item_status=ItemStatus.Received;
        emit ReceivedItem(_buyer, aux_List.uniqueTag, _review, block.timestamp);
        txDuration=updateTime_Orc();
    }      

    function _returnItem(address _seller,uint _id, uint _trackNo) external{
        address _buyer=_msgSender();
        _onlyBuyer(_id,_buyer, _seller);
        ItemListed memory aux_List=listedItems[_id][_seller];
        require (aux_List.item_status!=ItemStatus.Completed, "ERROR: Sale's Closed");
        if(aux_List.item_status!=ItemStatus.Received){revert ("Item hasn't been received!");}
        require (block.timestamp<txDuration, "ERROR: Return Window Close");
        listedItems[_id][_seller].item_status=ItemStatus.Return_Request;    
        _shippedItem(_trackNo, _id, _seller);
    }      
}