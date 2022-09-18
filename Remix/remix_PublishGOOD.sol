// SPDX-License-Identifier:MIT
/*
pragma solidity ^0.8.15;
        //@Title: Online Trade Marker (blockchain eBay)
        //@author: Dant3210
        //@notice: Main Contract
        //@dev: Contract under development (work in progress )

import "./PublishFunctionalities.sol";
//import "hardhat/console.sol";

contract PublishYourGood is PublishFunctionalities {

    /////////////////////
    //SELLER FUNCTIONS//
    ///////////////////
    function Publish(string memory _brand, string memory _model, string memory _description,uint256 _price, string memory _size, uint256 _tag) external{
       _AddItem(_brand,_model,_description,_price,_size, _tag, _msgSender());
    }   

    //Update Price
    function updatePrice(uint _id, uint _newPrice)external{
        _updatePrice(_id, _newPrice, _msgSender());
    }

    function Remove(uint _id)external{
        _unPublish(_id, _msgSender());
    }

    //Relist a Canceled or a Returned Item
    function Relist(uint _id) external {
        _relistItem(_id, _msgSender());
    }

    //Ship Item
    function Shipping(uint256 _trackNo, uint _id) external{ 
        _shippedItem(_trackNo, _id, _msgSender());
    }   

    //Withdraw Seller's funds
    function Withdraw(uint _id) external {
        _realeaseFunds(_id, _msgSender());          
    }    

    ////////////////////
    //BUYER FUNCTIONS//
    //////////////////
    function Buy(address _seller, uint _id) external payable{
        _buyItem(_seller, _id, _msgSender());
    }   

    //Cancel Transaction
    function Cancel(address _seller,uint _id, string calldata _reason) external{
        _cancelTransaction(_seller, _id, _msgSender(),_reason);
    }      

    //Received Item
    function Received(address _seller, uint _id, string calldata _review) external{
        _receivedItem(_seller, _id, _review,_msgSender());
    }   
    
    //Return Item
    function Return(address _seller,uint _id, uint _trackNo) external{
        _returnItem(_seller, _id,_trackNo, _msgSender());
    }  
}