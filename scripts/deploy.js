// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
//const hre = require("hardhat");
const {ethers, run, hre, network}= require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  //console.log("Contract balance:", (await deployer.Value()).toString());

  const MarketPlace = await ethers.getContractFactory("PublishYourGood");
  const marketplace = await MarketPlace.deploy();

  console.log("Market Place address:", marketplace.address);
  //console.log(network.config);
  if(network.config.chainId===5 || network.config.chainId===4 && process.env.ETHERSCAN_KEY){
    await marketplace.deployTransaction.wait(6);
    await verify(marketplace.address, []);
  }
}

async function verify(contracAddress, args){
  console.log("Verifying Contract.........");
  try{
    await run("verify:verify", {
      address:contracAddress,
      constructorArguments: args,
    });
  } catch(e){
    if(e.message.toLowerCase().includes("already verified")){
      console.log("Already Verified");
    }else{
      console.log(e);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
