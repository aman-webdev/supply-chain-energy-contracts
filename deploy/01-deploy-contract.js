const { network } = require("hardhat");
const { networkConfig,developmentChains } = require("../helper-hardhat-config");
const verify = require("../scripts/verify");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;

  if(developmentChains.includes(network.name)){
    console.log("----Local network detected----")
  }

  log("Deploying the contract");
  const energyContract = await deploy("ElectricitySupplyChain", {
    contract: "ElectricitySupplyChain",
    from: deployer,
    log: true,
  });
  log("Deployed at ", energyContract.address);
 
  if(!developmentChains.includes(network.name)){
    await verify(energyContract.address,[])
  }
  
};

module.exports.tags=["all","contract"]
