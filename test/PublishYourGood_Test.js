const { expect } = require("chai");
const { ethers } = require("hardhat");

let price, owner, addr1, addr2, hardhatMarket;

describe("Market contract Test", function () {
  it("Deployment", async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    //parameters
    const brand="Adiddas";
    const model="Yeezy";
    const description="Zebra";
    price="9000000"
    const size="9.5";
    const tag="9090";

    const MarketCont = await ethers.getContractFactory("PublishYourGood");

    hardhatMarket = await MarketCont.deploy();

    const hardhardPublis= await hardhatMarket.Publish(brand,model,description,price,size,tag);
    const arrayVariable=await hardhatMarket.sellerItemList(owner.address);

    const ContractValue = await hardhatMarket.Value();
    //console.log(ContractValue.toString());
    //console.log(arrayVariable);
    //console.log(hardhardPublis);

    //expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  });


  it("Price Update", async function(){
    price=100;
    const fundReleased= await hardhatMarket.connect(owner).updatePrice("0",price);
    console.log(fundReleased);

  });
  
  it("Deactivate Item", async function(){
    const deactivate= await hardhatMarket.connect(owner).Deactivate("0");
    console.log(deactivate);
  });

  it("Activate Item", async function(){
    const activate= await hardhatMarket.connect(owner).Activate("0");
    console.log(activate);
  });

  it("Buy Item", async function(){
    const buyItem=await hardhatMarket.connect(addr1).Buy(owner.address, "0", { value: price });
    console.log("_____________________________________________________________________________");
    //console.log(await hardhatMarket.allListed());
     
    console.log(await hardhatMarket.Value());
    expect(await hardhatMarket.Value()).to.equal(price);
    //const DurationDate= await hardhatMarket.connect(owner).get_txTime();
    console.log("END BUY-----------------");
  });  

  it("Cancel Order", async function(){
    const CancelItem= await hardhatMarket.connect(addr1).Cancel(owner.address,"0", "DEMO");
    console.log("END Cancel-----------------");
  });

  it("Relist item", async function(){
    const activate= await hardhatMarket.connect(owner).Relist("0");
  });

  it("Buy Item", async function(){
    const buyItem=await hardhatMarket.connect(addr2).Buy(owner.address, "0", { value: price });
    console.log("_____________________________________________________________________________");
    //console.log(await hardhatMarket.allListed());
     
    console.log(await hardhatMarket.Value());
    expect(await hardhatMarket.Value()).to.equal(price);
    //const DurationDate= await hardhatMarket.connect(owner).get_txTime();
    console.log("END BUY 2-----------------");
  });  

  it("Ship Item", async function(){
    //owner=addr2;
    console.log("------------SHIPPED-------------------------------------------");
    const shipped= await hardhatMarket.connect(owner).Shipping("12345566","0");
    //console.log(await hardhatMarket.allListed());
    //expect();
    //const DurationDate= await hardhatMarket.connect(owner).get_txTime();
    console.log("END SHIP-----------------");
    //console.log(DurationDate.toString());
  });  

  it("Received Item", async function(){
    const receivedItem= await hardhatMarket.connect(addr2).Received(owner.address,"0","All OK");
    console.log(receivedItem);
    const DurationDate= await hardhatMarket.connect(owner).get_txTime();
    console.log("RECEIVED-----------------");
    console.log(DurationDate.toString());
  });

  /*
  it("Return Item", async function(){
    const ReturnItem=await hardhatMarket.connect(addr2).Return(owner.address,"0");
    console.log("Returned-------------------");
  });

  it("Accept Return", async function(){
    const AcceptReturn=await hardhatMarket.AcceptReturn("0");
  });

  it("ShipReturn Item", async function(){
    const ShipReturn=await hardhatMarket.connect(addr2).ShipReturn(owner.address,"0","212222222");
    console.log("Ship Returned-------------------");
  });

  it("ReceivedReturn", async function(){
    const ReceivedReturn=await hardhatMarket.ReceivedReturn("0");
    console.log("Fully Returned-------------------");
  });*/

  /*it("Ship Item to seller", async function(){
    //owner=addr2;
    console.log("------------SHIPPED-------------------------------------------");
    const shipped= await hardhatMarket.connect(addr2).Shipping("7888900","0");
    //console.log(await hardhatMarket.allListed());
    //expect();
    //const DurationDate= await hardhatMarket.connect(owner).get_txTime();
    console.log("END SHIP TO SELLER-----------------");
    //console.log(DurationDate.toString());
  });  */

  /*it("Relist item", async function(){
    const activate= await hardhatMarket.connect(owner).Relist("0");
  });*/

  /*it("Release fund", async function(){
    const fundReleased= await hardhatMarket.connect(owner).Withdraw("0");

    console.log(await hardhatMarket.Value());
    
  });

  it("Remove Item", async function(){
    const removedItem= await hardhatMarket.Remove("0");
    console.log(removedItem);
  });*/
  
});
