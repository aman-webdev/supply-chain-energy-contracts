const { deployments, ethers } = require("hardhat");
const { assert, expect } = require("chai");
describe("Energy Supply Chain", async () => {
  let energyContract;
  let owner, powerplantOne, substationOne, distributorOne;
  let energyContractPowerplantOne,
    energyContractSubstationOne,
    energyContractDistributorOne;
  beforeEach(async () => {
    await deployments.fixture(["all"]);
    energyContract = await ethers.getContract("ElectricitySupplyChain");
    [owner, powerplantOne, substationOne, distributorOne] =
      await ethers.getSigners();
    energyContractPowerplantOne = energyContract.connect(powerplantOne);
    energyContractSubstationOne = energyContract.connect(substationOne);
    energyContractDistributorOne = energyContract.connect(distributorOne);
  });

  describe("Deployment", () => {
    it("Should deploy the contract", async () => {
      await expect(energyContract.getPowerplantById(10)).to.be.revertedWith(
        "Powerplant does not exist"
      );
    });
  });

  describe("Powerplant", () => {
    it("Should add the power plant", async () => {
      const powerplantName = "Power Plant One";
      const powerplantArea = "Delhi";
      const energyAvailable = 1000;
      const timeNow = parseInt(new Date().getTime() / (86400 * 1000));
      const tx = await energyContractPowerplantOne.addPowerPlant(
        powerplantName,
        powerplantArea,
        energyAvailable
      );
      const txRes = await tx.wait();
      const powerplantAdded = await energyContract.getPowerplantById(1);
      const energyProducedByDay = (
        await energyContract.getPowerPlantEnergyProducedByDay(1, timeNow)
      ).toString();

      const [powerplantId, powerplantOwner] = txRes.events[0].args;
      assert.equal(energyProducedByDay.toString(), energyAvailable.toString());
      assert.equal(
        powerplantAdded.totalEnergyProduced.toString(),
        energyAvailable
      );
      assert.equal(powerplantAdded.totalEnergySold.toString(), "0");
      assert.equal(powerplantId.toString(), "1");
      assert.equal(powerplantOwner, powerplantOne.address);
    });
  });
});
