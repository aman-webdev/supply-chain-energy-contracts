const { deployments, ethers } = require("hardhat");
const { assert, expect } = require("chai");
const { time } = require("@openzeppelin/test-helpers");

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

    describe("Created power plant", async () => {
      const powerplantName = "Power Plant One";
      const powerplantArea = "Delhi";
      const energyAvailable = 1000;
      const today = parseInt(new Date().getTime() / (86400 * 1000));
      const yesterday = Math.floor(
        new Date("27 Feb 2023").getTime() / (1000 * 86400)
      );
      const tomorrow = Math.floor(
        new Date("28 Feb 2023").getTime() / (1000 * 86400)
      );
      beforeEach(async () => {
        const tx = await energyContractPowerplantOne.addPowerPlant(
          powerplantName,
          powerplantArea,
          energyAvailable
        );
      });

      it("Should not create a new power plant with the same wallet address", async () => {
        const powerplant = await energyContract.getPowerplantById(1);
        assert.equal(powerplant.name, powerplantName);
        await expect(
          energyContractPowerplantOne.addPowerPlant(
            powerplantName,
            powerplantArea,
            energyAvailable
          )
        ).to.be.revertedWith("Power plant already exists");
      });

      it("Should add energy available to the powerplant", async () => {
        const tx = await energyContractPowerplantOne.addEnergyAvailableToBuy(
          energyAvailable
        );
        const txRes = await tx.wait(1);
        const [powerplantId, addEnergyAvailableToBuy, date] =
          txRes.events[0].args;
        const powerplant = await energyContract.getPowerplantById(1);
        const energyProducedToday =
          await energyContract.getPowerPlantEnergyProducedByDay(1, today);
        const energyProducedYesterday =
          await energyContract.getPowerPlantEnergyProducedByDay(1, yesterday);
        console.log(energyProducedToday.toString());
        assert.equal(powerplantId.toString(), "1");
        assert.equal(addEnergyAvailableToBuy.toString(), energyAvailable);
        assert.equal(
          powerplant.totalEnergyProduced.toString(),
          energyAvailable * 2
        );
        assert.equal(
          powerplant.energyAvailableToBuy.toString(),
          energyAvailable * 2
        );
        assert.equal(powerplant.totalEnergySold.toString(), 0);
        assert.equal(energyProducedToday.toString(), energyAvailable * 2);
        assert.equal(energyProducedYesterday.toString(), 0);
      });

      it("Should add energy available to the same day after 12 hours gap", async () => {
        const startTime = (await ethers.provider.getBlock()).timestamp;
        await energyContractPowerplantOne.addEnergyAvailableToBuy(
          energyAvailable / 2
        );
        const energyProducedTodayFirst =
          await energyContract.getPowerPlantEnergyProducedByDay(1, today);
        await ethers.provider.send("evm_increaseTime", [43200]); // Move 12 hours forward
        await ethers.provider.send("evm_mine", []);
        await energyContractPowerplantOne.addEnergyAvailableToBuy(
          energyAvailable / 2
        );
        const energyProducedTodaySecond =
          await energyContract.getPowerPlantEnergyProducedByDay(1, today);
        const energyProducedYesterday =
          await energyContract.getPowerPlantEnergyProducedByDay(1, yesterday);
        const energyProducedTomorrow =
          await energyContract.getPowerPlantEnergyProducedByDay(1, tomorrow);
        assert.equal(energyProducedTodaySecond.toString(), energyAvailable * 2);
        assert.equal(energyProducedTomorrow.toString(), 0);
        assert.equal(energyProducedYesterday.toString(), 0);
      });

      it("Should add energy for different days", async () => {
        await energyContractPowerplantOne.addEnergyAvailableToBuy(
          energyAvailable
        );
        const energyProducedToday =
          await energyContract.getPowerPlantEnergyProducedByDay(1, today);
        await ethers.provider.send("evm_increaseTime", [172800]); // Move 2 days forward
        await ethers.provider.send("evm_mine", []);
        await energyContractPowerplantOne.addEnergyAvailableToBuy(
          energyAvailable / 2
        );
        const timeLater = Math.floor(
          (new Date().getTime() / 1000 + 172800) / 86400
        );
        const energyProducedTwoDaysLater =
          await energyContract.getPowerPlantEnergyProducedByDay(1, timeLater);
        const energyProducedYesterday =
          await energyContract.getPowerPlantEnergyProducedByDay(1, yesterday);
        const powerplant = await energyContract.getPowerplantById(1);
        assert.equal(energyProducedToday.toString(), energyAvailable * 2);
        assert.equal(energyProducedTwoDaysLater.toString(), 500);
        assert.equal(energyProducedYesterday.toString(), 0);
        assert.equal(powerplant.totalEnergyProduced.toString(), 2500);
        assert.equal(powerplant.energyAvailableToBuy.toString(), 2500);
      });

      it("Should revert if the power plant does not exist", async () => {
        await expect(
          energyContractSubstationOne.addEnergyAvailableToBuy(energyAvailable)
        ).to.be.revertedWith(
          "Poweplant does not exist or you are not the owner"
        );
        const powerplant = await energyContract.getPowerplantById(1);
        assert.equal(
          powerplant.totalEnergyProduced.toString(),
          energyAvailable
        );
      });
    });
  });

  describe("Substation",()=>{
    const powerplantName = "Power Plant One";
    const powerplantArea = "Delhi";
    const energyAvailable = 1000;
    const substationName="Substation One"
    const substationArea = "Delhi";
    const today = parseInt(new Date().getTime() / (86400 * 1000));
    const yesterday = Math.floor(
      new Date("27 Feb 2023").getTime() / (1000 * 86400)
    );
    const tomorrow = Math.floor(
      new Date("28 Feb 2023").getTime() / (1000 * 86400)
    );
    beforeEach(async()=>{
      await energyContractPowerplantOne.addPowerPlant(
        powerplantName,
        powerplantArea,
        energyAvailable
      );
    })
    it("Should revert if the powerplant does not exist",async()=>{
          await expect(energyContractSubstationOne.addSubstation(2,substationName,substationArea)).to.be.revertedWith("Power Plant does not exist")
    })

    it("Should add the substation",async()=>{
        const tx =   await (energyContractSubstationOne.addSubstation(1,substationName,substationArea))
        const txRes = await tx.wait(1)
        const [substationId,powerplantId,substationowner]=txRes.events[0].args
        const powerplant = await energyContract.getPowerplantById(1)
        const substation = await energyContract.getSubstationById(1)
        assert.equal(substationId.toString(),'1')
        assert.equal(substationId.toString(),'1')
        assert.equal(substationowner,substationOne.address)
        assert.equal(substation.powerplantId.toString(),'1')
    })

    it("Should buy energy from powerplant -> revert if substation doesnt exist",async()=>{
        await expect(energyContractSubstationOne.buyEnergyFromPowerPlant(100)).to.be.reverted
    })

    it("Should be able to buy energy from power plant",async()=>{
      await  (energyContractSubstationOne.addSubstation(1,substationName,substationArea))
      const tx = await energyContractSubstationOne.buyEnergyFromPowerPlant(100)
      const powerplant = await energyContract.getPowerplantById(1)
      const substation = await energyContract.getSubstationById(1)
      const powerplantEnergySoldByDay= await energyContract.getPowerPlantEnergySoldByDay(1,today)
      const substationEnergySoldByDay= await energyContract.getSubstationEnergySoldByDay(1,today)
      const substationEnergyBoughtByDay= await energyContract.getSubstationEnergyBoughtByDay(1,today)
      const substationEnergyBoughtYesterday= await energyContract.getSubstationEnergyBoughtByDay(1,yesterday)
      const txRes = await tx.wait(1)
      const [substaionId,energyBought,date]=txRes.events[0].args
      assert.equal(substaionId.toString(),'1')
      assert.equal(energyBought.toString(),'100')
      assert.equal(date.toString(),today)
      assert.equal(powerplant.energyAvailableToBuy.toString(),energyAvailable-100)
      assert.equal(powerplant.totalEnergyProduced.toString(),energyAvailable)
      assert.equal(powerplant.totalEnergySold.toString(),100)
      assert.equal(substation.totalEnergyReceived.toString(),100)
      assert.equal(substation.energyAvailableToBuy.toString(),100)
      assert.equal(powerplantEnergySoldByDay.toString(),100)
      assert.equal(substationEnergySoldByDay.toString(),0)
      assert.equal(substationEnergyBoughtByDay.toString(),100)
      assert.equal(substationEnergyBoughtYesterday.toString(),0)
    })
  })
});
