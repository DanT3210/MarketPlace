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
    const arrayVariable=await hardhatMarket.itemsListed_All(owner.address);

    const ContractValue = await hardhatMarket.Value();
    //console.log(ContractValue.toString());
    console.log(arrayVariable);
    //console.log(hardhardPublis);

    //expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  });

  it("Buy Item", async function(){
    const buyItem=await hardhatMarket.connect(addr1).Buy(owner.address, "0", { value: price });
    console.log("_____________________________________________________________________________");
    //console.log(await hardhatMarket.allListed());
     
    console.log(await hardhatMarket.Value());
    expect(await hardhatMarket.Value()).to.equal(price);
  });

  it("Ship Item", async function(){
    //owner=addr2;
    console.log("------------SHIPPED-------------------------------------------");
    const shipped= await hardhatMarket.connect(owner).shipItem("12345566","0");
    //console.log(await hardhatMarket.allListed());
    //expect();
  });

  it("Received Item", async function(){
    const receivedItem= await hardhatMarket.connect(addr1).Received(owner.address,"0","All OK");
    console.log(receivedItem);
  });

  it("Release fund", async function(){
    const fundReleased= await hardhatMarket.connect(owner).realeaseFunds("0");
    console.log(await hardhatMarket.Value());
  });

  it("Remove Item", async function(){
    const removedItem= await hardhatMarket.Remove("0");
    console.log(removedItem);
  });
  
});
