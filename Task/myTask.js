const {task}=require("hardhat/config");
require("@nomiclabs/hardhat-ethers");


task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();
  
    for (const account of accounts) {
      console.log(account.address);
    }
  });

  task("blockNumber", "Prints the current block number").setAction(async (taskArgs, hre)=>{
    const blockNumber=await hre.ethers.provider.getBlockNumber();
    console.log(blockNumber);
  });
  
  //module.exports = {};