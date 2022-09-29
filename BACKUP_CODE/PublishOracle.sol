// SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;
        //@Title: Online Trade Marker (blockchain eBay)
        //@author: Dant3210
        //@notice: Oracle Contract (*Time)
        //@dev: Contract under development (work in progress )

contract PublishOracle{
    

    function updateTime_Orc()internal virtual view returns(uint256){
        return (block.timestamp + 3 days);
    }

    function addShippingTime_Orc()internal virtual view returns(uint256){
        return (block.timestamp + 10 days);
    }


}