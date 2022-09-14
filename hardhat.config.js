require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
require("./Task/myTask");

const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL || "https://eth-rinkeby.alchemyapi.io/v2/your-api-key";
const GOERLI_RPC_URL=process.env.GOERLI_RPC_URL || "https://eth-goerli.g.alchemy.com/v2/7aKFaFYTJuVBsJFGJadeeMs22gCI07Th";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x";
const ETHERSCAN_KEY=process.env.ETHERSCAN_KEY || "0x";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {

  solidity: "0.8.15",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
        // // If you want to do some forking, uncomment this
        // forking: {
        //   url: MAINNET_RPC_URL
        // }
        chainId: 31337,
    },
    localhost: {
        chainId: 31337,
    },
    rinkeby: {
      url: RINKEBY_RPC_URL,
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      //   accounts: {
      //     mnemonic: MNEMONIC,
      //   },
      saveDeployments: true,
      chainId: 4,
  }, 
  Goerli: {
    url:GOERLI_RPC_URL,
    accounts:PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
    chainId:5,
  },
},   
 etherscan:{
    apiKey: ETHERSCAN_KEY,
 },

};
