// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract ElectricitySupplyChain {
    event PowerPlantAdded(uint256 indexed powerplantId, address indexed owner);
    event EnergyAddedByPowerPlant(
        uint256 indexed powerplantId,
        uint256 energyAdded,
        uint256 date
    );

    event SubstationAdded(
        uint256 indexed substationId,
        uint256 indexed powerplantId,
        address indexed owner
    );
    event EnergyBoughtBySubstation(
        uint256 indexed substationId,
        uint256 energyBought,
        uint256 date
    );

    event DistributorAdded(
        uint256 indexed distributorId,
        uint256 indexed substationId,
        address indexed owner
    );
    event EnergyBoughtByDistributor(
        uint256 indexed distributorId,
        uint256 energyBought,
        uint256 date
    );
    // Define the Distributor struct
    struct Distributor {
        uint256 substationId;
        address distributorAddress;
        string name;
        string area;
        uint256 energyAvailable;
        uint256[] consumerIds;
        uint256 totalEnergySold;
        uint256 totalEnergyBought;
    }

    // Define the Substation struct
    struct Substation {
        string name;
        string area;
        uint256 powerplantId;
        address substationAddress;
        uint256 totalEnergyReceived;
        uint256 totalEnergySold;
        uint256[] distributorIds;
        uint256 energyAvailableToBuy;
    }

    // Define the PowerPlant struct
    struct PowerPlant {
        string name;
        string area;
        address powerplantAddress;
        uint256[] substationIds;
        uint256 totalEnergyProduced;
        uint256 totalEnergySold;
        uint256 energyAvailableToBuy;
    }

    // Define an array to hold all the power plants
    mapping(uint256 => PowerPlant) public powerPlants;
    mapping(address => uint256) public powerPlantsAddressToIds;
    mapping(uint256 => mapping(uint256 => uint256)) powerPlantsDailyEnergyProducedById;
    mapping(uint256 => mapping(uint256 => uint256)) powerPlantsDailyEnergySoldById;

    mapping(uint256 => Distributor) public distributors;
    mapping(address => uint256) public distributorAddressToIds;
    // distributorId -> date -> energy bought
    mapping(uint256 => mapping(uint256 => uint256)) distributorsDailyEnergyBoughtById;

    mapping(uint256 => Substation) public substations;
    mapping(address => uint256) public substationsAddressToIds;

    mapping(uint256 => mapping(uint256 => uint256)) substationsDailyEnergyBoughtById;
    mapping(uint256 => mapping(uint256 => uint256)) substationsDailyEnergySoldById;

    // ids for each entity
    uint256 powerPlantCount;
    uint256 distributorCount;
    uint256 substationCount;

    // Define a function to add a new power plant to the supply chain
    function addPowerPlant(
        string memory _name,
        string memory _area,
        uint256 _energyAvailableToBuy
    ) public {
        uint256 powerplantId = powerPlantsAddressToIds[msg.sender];
        // check if power plant does not exist with the wallet address
        require(powerplantId == 0, "Power plant already exists");
        powerPlantCount += 1;
        PowerPlant storage powerplant = powerPlants[powerPlantCount];
        powerPlantsAddressToIds[msg.sender] = powerPlantCount;
        // Create a new PowerPlant struct
        powerplant.powerplantAddress = msg.sender;
        powerplant.name = _name;
        powerplant.area = _area;
        powerplant.energyAvailableToBuy = _energyAvailableToBuy;
        powerplant.totalEnergyProduced = _energyAvailableToBuy;
        uint256 today = block.timestamp / 86400;
        powerPlantsDailyEnergyProducedById[powerPlantCount][today] = _energyAvailableToBuy;
        emit PowerPlantAdded(powerPlantCount, msg.sender);
    }

    // Define a function to add a new substation to a power plant
    function addSubstation(
        uint256 _powerPlantId,
        string memory _name,
        string memory _area
    ) public {
        // check if powerplant exists
        require(
            powerPlants[_powerPlantId].powerplantAddress != address(0),
            "Power Plant does not exist"
        );
        require(
            substationsAddressToIds[msg.sender] == 0,
            "Substation already exists with the current address"
        );
        substationCount += 1;
        Substation storage substation = substations[substationCount];
        substationsAddressToIds[msg.sender] = substationCount;
        substation.name = _name;
        substation.area = _area;
        substation.substationAddress = msg.sender;
        substation.powerplantId = _powerPlantId;
        // add substation id to the power plant
        powerPlants[_powerPlantId].substationIds.push(substationCount);
        emit SubstationAdded(substationCount, _powerPlantId, msg.sender);
    }

    // Define a function to add energy available to buy for a powerplant
    function addEnergyAvailableToBuy(
        uint256 _energyAvailableToBuy
    ) public onlyPowerPlantOwner {
        uint256 powerplantId = powerPlantsAddressToIds[msg.sender];
        PowerPlant storage powerPlant = powerPlants[powerplantId];
        powerPlant.energyAvailableToBuy += _energyAvailableToBuy;
        // Update the daily energy produced mapping
        uint256 today = block.timestamp / 86400;
        powerPlantsDailyEnergyProducedById[powerplantId][
            today
        ] += _energyAvailableToBuy;
        powerPlant.totalEnergyProduced += _energyAvailableToBuy;
        emit EnergyAddedByPowerPlant(
            powerplantId,
            _energyAvailableToBuy,
            today
        );
    }

    // Define a function for a substation to buy energy from a power plant
    function buyEnergyFromPowerPlant(
        uint256 _energyAmount
    ) public onlySubstationOwner {
        uint256 substationId = substationsAddressToIds[msg.sender];
        Substation storage substation = substations[substationId];
        // Get the power plant from the powerPlants array
        PowerPlant storage powerPlant = powerPlants[substation.powerplantId];
        require(
            powerPlant.energyAvailableToBuy >= _energyAmount,
            "Insufficient energy available to buy"
        );
        powerPlant.energyAvailableToBuy -= _energyAmount;
        substation.totalEnergyReceived += _energyAmount;
        // Update the daily energy bought mapping
        uint256 today = block.timestamp / 86400;
        substationsDailyEnergyBoughtById[substationId][today] += _energyAmount;
        substation.energyAvailableToBuy += _energyAmount;
        powerPlantsDailyEnergySoldById[substation.powerplantId][
            today
        ] += _energyAmount;
        emit EnergyBoughtBySubstation(
            substationsAddressToIds[msg.sender],
            _energyAmount,
            today
        );
    }

    function addDistributor(
        string memory _name,
        string memory _area,
        uint256 _substationIndex
    ) public {
        require(
            substations[_substationIndex].substationAddress != address(0),
            "Substation does not exist"
        );
        require(
            distributorAddressToIds[msg.sender] == 0,
            "Distributor already exists with the address"
        );
        distributorCount += 1;
        // Get the substation from the power plant's substations array
        Substation storage substation = substations[_substationIndex];
        Distributor storage distributor = distributors[distributorCount];
        distributor.name = _name;
        distributor.area = _area;
        distributor.distributorAddress = msg.sender;
        distributor.substationId = _substationIndex;
        // Add the new Distributor to the distributors array of the substation
        substation.distributorIds.push(distributorCount);
        emit DistributorAdded(distributorCount, _substationIndex, msg.sender);
    }

    function buyEnergyFromSubstation(
        uint256 _energyAmount
    ) public onlyDistributorOwner {
        uint256 distributorId = distributorAddressToIds[msg.sender];
        Distributor storage distributor = distributors[distributorId];
        // Get the power plant from the powerPlants array
        Substation storage substation = substations[distributor.substationId];
        require(
            substation.energyAvailableToBuy >= _energyAmount,
            "Insufficient energy available to buy"
        );
        substation.energyAvailableToBuy -= _energyAmount;
        distributor.totalEnergyBought += _energyAmount;
        // Update the daily energy bought mapping
        uint256 today = block.timestamp / 86400;
        distributorsDailyEnergyBoughtById[distributorId][
            today
        ] += _energyAmount;
        distributor.energyAvailable += _energyAmount;
        substationsDailyEnergySoldById[distributor.substationId][
            today
        ] += _energyAmount;

        emit EnergyBoughtByDistributor(distributorId, _energyAmount, today);
    }


    // powerplants
    function getPowerplantById(
        uint256 _powerplantIndex
    )
        public
        view
        powerPlantExists(_powerplantIndex)
        returns (PowerPlant memory)
    {
        return powerPlants[_powerplantIndex];
    }

    function getPowerPlantEnergySoldByDay(
        uint256 _powerplantIndex,
        uint256 _day
    ) public view powerPlantExists(_powerplantIndex) returns (uint256) {
        return powerPlantsDailyEnergySoldById[_powerplantIndex][_day];
    }

    function getPowerPlantEnergyProducedByDay(
        uint256 _powerplantIndex,
        uint256 _day
    ) public view powerPlantExists(_powerplantIndex) returns (uint256) {
        return powerPlantsDailyEnergyProducedById[_powerplantIndex][_day];
    }

    function getSubstationsOfPowerPlant(uint256 _powerplantIndex) external view powerPlantExists(_powerplantIndex) returns (Substation[] memory){
        uint256[] memory substationIds = getPowerplantById(_powerplantIndex).substationIds;
        Substation[] memory substationsArray = new Substation[](substationIds.length);
        for(uint256 i=0;i<substationIds.length;i++){
            substationsArray[i]=(getSubstationById(substationIds[i]));
        }
        return substationsArray;
    }

    // substations
    function getSubstationById(
        uint256 _substationIndex
    )
        public
        view
        substationExists(_substationIndex)
        returns (Substation memory)
    {
        return substations[_substationIndex];
    }

    function getSubstationEnergySoldByDay(
        uint256 _substationIndex,
        uint256 _day
    ) public view substationExists(_substationIndex) returns (uint256) {
        return substationsDailyEnergySoldById[_substationIndex][_day];
    }

    function getSubstationEnergyBoguhtByDay(
        uint256 _substationIndex,
        uint256 _day
    ) public view substationExists(_substationIndex) returns (uint256) {
        return substationsDailyEnergyBoughtById[_substationIndex][_day];
    }

    
    // distributors
    function getDistributorById(
        uint256 _distributorIndex
    )
        public
        view
        distributorExists(_distributorIndex)
        returns (Distributor memory)
    {
        return distributors[_distributorIndex];
    }

    // function getdistributorEnergySoldByDay(
    //     uint256 _distributorIndex,
    //     uint256 _day
    // ) public view distributorExists(_distributorIndex) returns (uint256) {
    //     return distributorsDailyEnergySoldById[_distributorIndex][_day];
    // }

    function getDistributorEnergyBoguhtByDay(
        uint256 _distributorIndex,
        uint256 _day
    ) public view distributorExists(_distributorIndex) returns (uint256) {
        return distributorsDailyEnergyBoughtById[_distributorIndex][_day];
    }

    modifier powerPlantExists(uint256 _powerplantIndex) {
        require(
            powerPlants[_powerplantIndex].powerplantAddress != address(0),
            "Powerplant does not exist"
        );
        _;
    }

    modifier substationExists(uint256 _substationIndex) {
        require(
            substations[_substationIndex].substationAddress != address(0),
            "Substation does not exist"
        );
        _;
    }
    modifier distributorExists(uint256 _distributorIndex) {
        require(
            distributors[_distributorIndex].distributorAddress != address(0),
            "Distributor does not exist"
        );
        _;
    }

    modifier onlyPowerPlantOwner() {
        require(
            powerPlantsAddressToIds[msg.sender] != 0,
            "Poweplant does not exist or you are not the owner"
        );
        require(
            powerPlants[powerPlantsAddressToIds[msg.sender]]
                .powerplantAddress == msg.sender,
            "Only owner allowed"
        );
        _;
    }

    modifier onlySubstationOwner() {
        require(
            substationsAddressToIds[msg.sender] != 0,
            "Substation does not exist or you are not the owner"
        );
        require(
            substations[substationsAddressToIds[msg.sender]]
                .substationAddress == msg.sender,
            "Only owner allowed"
        );
        _;
    }

    modifier onlyDistributorOwner() {
        require(
            distributorAddressToIds[msg.sender] != 0,
            "Distributor does not exist or you are not the owner"
        );
        require(
            distributors[distributorAddressToIds[msg.sender]]
                .distributorAddress == msg.sender,
            "Only owner allowed"
        );
        _;
    }
}
