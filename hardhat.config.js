require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require('dotenv').config();


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks:{
    hardhat:{
      
    },
    mumbai: {
      url: process.env.ALCHEMY_API_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`,"cd395b9982f51d469742bf17523c4e87d43b778d6c3e8499a3f54a68b8a7accb","f0076b1efd0f679341fa0ac50c9f24048d82c97d3de5337aedc231b22c96ed92","93e34e964e9f07ebc642f5f64a63897d0eb88dd59ae31b138c3fb826f074ccfc"],
  },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    }, 
  },
  etherscan: {
    apiKey: {
        polygonMumbai: "SRHVR8XK7ENVAD976Q9A53B5KIB38RK1U3",
    },
},
};
