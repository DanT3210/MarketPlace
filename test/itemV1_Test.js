const { expect } = require("chai");
const { ethers } = require("hardhat");

let price, owner, addr1, addr2, addr3, hardhatMarket, itemStatus;

describe("Market contract Test", function () {
  it("Deployment", async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    //parameters
    const brand="Adiddas";
    const model="Yeezy";
    const description="Zebra";
    price="9000000"
    const size="9.5";
  
    const MarketCont = await ethers.getContractFactory("ItemContract");

    hardhatMarket = await MarketCont.deploy();

    const hardhardPublis= await hardhatMarket.PublishSingle(brand,model,description,price,size);
   //const arrayVariable=await hardhatMarket.sellerItemList("0",owner.address);
   itemStatus= await hardhatMarket.getStatus("0", owner.address);
   console.log("STATUS______________________");
   console.log(itemStatus);
   //console.log("Listed");
  });

  it("Remove item", async function(){
    const removeItem= await hardhatMarket.connect(owner).RemoveSingleItem("0");
    const itemListed_var=await hardhatMarket.SellerList("0", owner.address);
    itemStatus= await hardhatMarket.getStatus("0", owner.address);
    console.log(itemStatus);
    console.log("ITEM REMOVED--------------------");
    console.log(itemListed_var);
  });  

/*  it("New Listed", async function(){
    const brand="Nike";
    const model="AJ1";
    const description="First Class";
    price="19000000"
    const size="9";

   const hardhardPublis= await hardhatMarket._AddItem(brand,model,description,price,size);
   const arrayVariable=await hardhatMarket.itemListedBySeller("1",owner.address);
   itemStatus= await hardhatMarket._itemStatus("1", owner.address);
   console.log(itemStatus);
   console.log("STATUS______________________");
   console.log(arrayVariable);
  });  

  it("Buy Item", async function(){
    const buyItem=await hardhatMarket.connect(addr2)._buyItem(owner.address, "1", { value: price });
    console.log("Buy Add2_______________________________________________________________________");
    itemStatus= await hardhatMarket._itemStatus("1", owner.address);
    console.log(itemStatus);
    console.log("END BUY 2-----------------");
  });  

  it("Ship Item", async function(){
    //owner=addr2;
    console.log("------------SHIPPED-------------------------------------------");
    const shipped= await hardhatMarket.connect(owner)._shipping("12345566","1");
    itemStatus= await hardhatMarket._itemStatus("1", owner.address);
    console.log(itemStatus);
    console.log("END SHIP-----------------");
  });  

  it("Received Item", async function(){
    const receivedItem= await hardhatMarket.connect(addr2)._receivedItem(owner.address,"1","All OK");
    itemStatus= await hardhatMarket._itemStatus("1", owner.address);
    console.log(itemStatus);
    console.log("END RECEIVED-----------------");
  });

  it("Seller Amount", async function(){
    const balanceOffItem= await hardhatMarket.connect(addr2).ballanceOff("1",owner.address);
    console.log(balanceOffItem.toString());
    console.log("SELLER BALANCEOFF-----------------");
  });
  
  it("Return Item", async function(){
    const ReturnItem=await hardhatMarket.connect(addr2)._returnItem(owner.address,"1", "12222111212");
    itemStatus= await hardhatMarket._itemStatus("1", owner.address);
    console.log(itemStatus);
    console.log("END RETURN-----------------");
  });

  it("Seller Received Item", async function(){
    const receivedItem2= await hardhatMarket.receivedReturn("1","All OK");
    itemStatus= await hardhatMarket._itemStatus("1", owner.address);
    console.log(itemStatus);
    console.log("END SELLER RECEIVED-----------------");
  });  

  it("Buyer Amount", async function(){
    const balanceOffItem= await hardhatMarket.ballanceOff("1",addr2.address);
    console.log(balanceOffItem.toString());
    console.log("BUYER BALANCEOFF-----------------");
    const balanceOffSeller= await hardhatMarket.ballanceOff("1",owner.address);
    console.log(balanceOffSeller.toString());    
    console.log("SELLER BALANCEOFF-----------------");
  });

  ////////*******Need to wait few seconds (Fund the way to simulate time in test*********
  it("Buyer Withdraw Funds", async function(){
    const BuyerWithdrawFunds= await hardhatMarket.connect(addr2)._realeaseFunds("1");
    itemStatus= await hardhatMarket._itemStatus("1", owner.address);
    console.log(itemStatus);    
    console.log("BUYER2 WITHDRAW--------------------");
  });

  /*it("Remove Item", async function(){
    const removedItem= await hardhatMarket._unPublish("0");
    console.log(removedItem);
  });*/
  
});
