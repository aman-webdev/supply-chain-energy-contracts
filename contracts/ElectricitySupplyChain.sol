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
        address indexed owner,
        uint256 energyAvailableToBuy
    );
    event SubstationConnectedToPowerPlant(
        uint256 indexed substationId,
        uint256 indexed powerPlantId,
        uint256 indexed prevPowerplantId
    );
    event EnergyBoughtBySubstation(
        uint256 indexed substationId,
        uint256 energyBought,
        uint256 date
    );

    event DistributorAdded(
        uint256 indexed distributorId,
        address indexed owner,
        uint256 energyAvailableToBuy
    );
    event DistributorConnectedToSubstation(
        uint256 indexed distributorId,
        uint256 indexed substationId,
        uint256 indexed prevSubstationId
    );
    event EnergyBoughtByDistributor(
        uint256 indexed distributorId,
        uint256 energyBought,
        uint256 date
    );

    event ConsumerAdded(uint256 indexed consumerId, address owner);
    event ConsumerConnectedToDistributor(
        uint256 indexed consumerId,
        uint256 indexed distributorId,
        uint256 indexed prevDistributorId
    );
    event ElectricityPaidByConsumer(
        uint256 indexed consumerId,
        uint256 energyConsumed,
        uint256 startTime,
        uint256 endTime
    );

    event UpdateUnitsConsumedRan(uint256 day);

    event ConsumerCancelledElectricity(
        uint256 consumerTicker,
        uint256 distributorTicker,
        uint256 energyConsumed,
        uint256 startTime,
        uint256 today
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
        bool isEnergySupply;
        bool isLessEnergyWarning;
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

    struct Consumer {
        string name;
        string homeAddress;
        address consumerAddress;
        uint256 distributorId;
        uint256 totalEnergyConsumed;
        bool isElectricitySupply;
        uint256 payableAmountForEnergy;
        uint256 startCycleTime;
        uint256 endCycleTime;
        bool isLastElectricityBillPaid;
        uint256 energyConsumedInCurrentCycle;
        // uint256 lastScriptExecutionTime;
        // uint256 currentScriptExecutionTime;
    }

    struct Payment {
        uint256 unitsConsumed;
        // uint256 amountPaid; TODO: include this
        uint256 startTime;
        uint256 endTime;
    }

    // consumer -> Payment
    mapping(address => Payment[]) public consumerPayments;

    // Define an array to hold all the power plants
    mapping(uint256 => PowerPlant) public powerPlants;
    mapping(address => uint256) public powerPlantsAddressToIds;
    mapping(uint256 => mapping(uint256 => uint256))
        public powerPlantsDailyEnergyProducedById;
    mapping(uint256 => mapping(uint256 => uint256))
        public powerPlantsDailyEnergySoldById;

    mapping(uint256 => Distributor) public distributors;
    mapping(address => uint256) public distributorAddressToIds;
    uint256[] public distributorArray;
    // distributorId -> date -> energy bought
    mapping(uint256 => mapping(uint256 => uint256))
        public distributorsDailyEnergyBoughtById;
    mapping(uint256 => mapping(uint256 => uint256))
        public distributorsDailyEnergySoldById;

    mapping(uint256 => Substation) public substations;
    mapping(address => uint256) public substationsAddressToIds;

    mapping(uint256 => mapping(uint256 => uint256))
        public substationsDailyEnergyBoughtById;
    mapping(uint256 => mapping(uint256 => uint256))
        public substationsDailyEnergySoldById;

    mapping(uint256 => Consumer) public consumers;
    mapping(address => uint256) public consumersAddressToIds;

    mapping(uint256 => mapping(uint256 => uint256))
        public consumersDailyEnergyBoughtById;

    // ids for each entity
    uint256 powerPlantCount;
    uint256 distributorCount;
    uint256 substationCount;
    uint256 consumerCount;

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
        powerPlantsDailyEnergyProducedById[powerPlantCount][
            today
        ] = _energyAvailableToBuy;
        emit PowerPlantAdded(powerPlantCount, msg.sender);
    }

    // Define a function to add a new substation to a power plant
    function addSubstation(
        uint256 _energyAvailableToBuy,
        string memory _name,
        string memory _area
    ) public {
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
        substation.energyAvailableToBuy = _energyAvailableToBuy;
        // add substation id to the power plant

        emit SubstationAdded(
            substationCount,
            msg.sender,
            _energyAvailableToBuy
        );
    }

    function connectSubstationToPowerplant(
        uint256 powerplantIndex
    ) public onlySubstationOwner powerPlantExists(powerplantIndex) {
        Substation storage substation = substations[
            substationsAddressToIds[msg.sender]
        ];
        uint256 prevPlantId = substation.powerplantId;
        if (substation.powerplantId != 0) {
            PowerPlant storage prevPlant = powerPlants[substation.powerplantId];
            uint256 index;
            for (uint256 i = 0; i < prevPlant.substationIds.length; i++) {
                if (
                    prevPlant.substationIds[i] ==
                    substationsAddressToIds[msg.sender]
                ) {
                    index = i;
                    break;
                }
            }
            for (uint i = index; i < prevPlant.substationIds.length - 1; i++) {
                prevPlant.substationIds[i] = prevPlant.substationIds[i + 1];
            }
            prevPlant.substationIds.pop();
        }
        substation.powerplantId = powerplantIndex;
        PowerPlant storage powerplant = powerPlants[powerplantIndex];
        powerplant.substationIds.push(substationsAddressToIds[msg.sender]);
        emit SubstationConnectedToPowerPlant(
            substationsAddressToIds[msg.sender],
            powerplantIndex,
            prevPlantId
        );
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
        powerPlant.totalEnergySold += _energyAmount;
        emit EnergyBoughtBySubstation(
            substationsAddressToIds[msg.sender],
            _energyAmount,
            today
        );
    }

    function addDistributor(
        string memory _name,
        string memory _area,
        uint256 _energyAvailableToBuy
    ) public {
        require(
            distributorAddressToIds[msg.sender] == 0,
            "Distributor already exists with the address"
        );
        distributorCount += 1;
        Distributor storage distributor = distributors[distributorCount];
        distributorAddressToIds[msg.sender] = distributorCount;
        distributor.name = _name;
        distributor.area = _area;
        distributor.distributorAddress = msg.sender;
        distributor.energyAvailable = _energyAvailableToBuy;
        distributor.isEnergySupply = true;
        distributorArray.push(distributorCount);
        emit DistributorAdded(
            distributorCount,
            msg.sender,
            _energyAvailableToBuy
        );
    }

    function connectDistributorToSubstation(
        uint256 _substationIndex
    ) public onlyDistributorOwner substationExists(_substationIndex) {
        Distributor storage distributor = distributors[
            distributorAddressToIds[msg.sender]
        ];
        uint256 prevSubstationIndex = distributor.substationId;
        if (distributor.substationId != 0) {
            Substation storage prevSubstation = substations[
                distributor.substationId
            ];
            uint256 index;
            for (uint256 i = 0; i < prevSubstation.distributorIds.length; i++) {
                if (
                    prevSubstation.distributorIds[i] ==
                    distributorAddressToIds[msg.sender]
                ) {
                    index = i;
                    break;
                }
            }
            for (
                uint i = index;
                i < prevSubstation.distributorIds.length - 1;
                i++
            ) {
                prevSubstation.distributorIds[i] = prevSubstation
                    .distributorIds[i + 1];
            }
            prevSubstation.distributorIds.pop();
        }
        distributor.substationId = _substationIndex;
        Substation storage substation = substations[_substationIndex];
        substation.distributorIds.push(substationsAddressToIds[msg.sender]);
        emit DistributorConnectedToSubstation(
            distributorAddressToIds[msg.sender],
            _substationIndex,
            prevSubstationIndex
        );
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
        distributor.isEnergySupply = true;

        emit EnergyBoughtByDistributor(distributorId, _energyAmount, today);
    }

    function addConsumer(
        string memory _name,
        string memory _homeAddress
    ) public {
        consumerCount += 1;
        Consumer storage consumer = consumers[consumerCount];
        consumer.name = _name;
        consumer.homeAddress = _homeAddress;
        consumersAddressToIds[msg.sender] = consumerCount;
        consumer.consumerAddress = msg.sender;
        consumer.isLastElectricityBillPaid = true;
        emit ConsumerAdded(consumerCount, msg.sender);
    }

    function calculateEnergyConsumptionOfEachConsumer() public {
        uint256 today = block.timestamp / 86400;
        for (uint i = 0; i < distributorArray.length; i++) {
            // get all the distributors
            Distributor storage distributor = distributors[distributorArray[i]];
            // showing warning message if distributor has less than 20% energy
            uint256 minimumEnergyPercentage = (distributor.energyAvailable*20)/100;
            if(distributor.energyAvailable <= minimumEnergyPercentage) distributor.isLessEnergyWarning=true;
            if (distributor.isEnergySupply) {
                uint256 totalEnergyConsumedByConsumersOfADistributor = 0;
                // variable for totalEnergyConsmedofADistributor
                for (uint j = 0; j < distributor.consumerIds.length; j++) {
                    Consumer storage consumer = consumers[
                        distributor.consumerIds[j]
                    ];

                    // to reset last electricity bill paid as false
                    if (consumer.isLastElectricityBillPaid)
                        consumer.isLastElectricityBillPaid = false;
                    // consumer.lastScriptExecutionTime = consumer
                    //     .currentScriptExecutionTime;
                    // consumer.currentScriptExecutionTime = block.timestamp;
                    // uint256 energyConsumedInThisCycle = consumer
                    //     .currentScriptExecutionTime -
                    //     consumer.lastScriptExecutionTime;
                    // if (energyConsumedInThisCycle > distributor.energyAvailable) {
                    //     distributor.isEnergySupply = false;
                    //      consumer
                    //         .energyConsumedInCurrentCycle += distributor.energyAvailable;
                    //     consumer.totalEnergyConsumed += distributor.energyAvailable;
                    //     totalEnergyConsumedByConsumersOfADistributor += (distributor.energyAvailable);
                    //     distributor.energyAvailable = 0;
                    // }
                    // if (distributor.isEnergySupply) {
                    //     consumer
                    //         .energyConsumedInCurrentCycle += energyConsumedInThisCycle;
                    //     consumer.totalEnergyConsumed += energyConsumedInThisCycle;
                    //     totalEnergyConsumedByConsumersOfADistributor += (consumer
                    //         .currentScriptExecutionTime -
                    //         consumer.lastScriptExecutionTime);
                    // }

                    consumer.totalEnergyConsumed++;
                    consumer.energyConsumedInCurrentCycle++;
                    distributor.energyAvailable--;
                    totalEnergyConsumedByConsumersOfADistributor++;
                    consumersDailyEnergyBoughtById[distributor.consumerIds[j]][
                        today
                    ]++;
                    if (distributor.energyAvailable <= 0) {
                        distributor.isEnergySupply = false;
                        break;
                    }
                }
                distributor
                    .totalEnergySold += totalEnergyConsumedByConsumersOfADistributor;
                distributorsDailyEnergySoldById[distributorArray[i]][
                    today
                ] += totalEnergyConsumedByConsumersOfADistributor;
                // if (
                //     totalEnergyConsumedByConsumersOfADistributor >
                //     distributor.energyAvailable
                // ) {
                //     distributor.energyAvailable = 0;
                //     distributor.isEnergySupply = false;
                // } else
                //     distributor
                //         .energyAvailable -= totalEnergyConsumedByConsumersOfADistributor;
            }
        }

        emit UpdateUnitsConsumedRan(today);
    }

    // as soon as consumer connects, the energy consumption starts
    function connectConsumerToDistributor(
        uint256 _distributorIndex
    ) public distributorExists(_distributorIndex) onlyConsumerOwner {
        require(
            distributors[_distributorIndex].energyAvailable >= 0,
            "Distributor doesn't have enough energy, please connect later"
        );
        uint256 consumerId = consumersAddressToIds[msg.sender];
        Consumer storage consumer = consumers[consumerId];
        require(
            consumer.isLastElectricityBillPaid,
            "Please pay the energy used first"
        );
        Distributor storage distributor = distributors[_distributorIndex];
        uint256 prevDistributorId = consumer.distributorId;
        if (prevDistributorId != 0) {
            Distributor storage prevDistributor = distributors[
                prevDistributorId
            ];
            uint256 index;
            for (uint256 i = 0; i < prevDistributor.consumerIds.length; i++) {
                if (
                    prevDistributor.consumerIds[i] ==
                    consumersAddressToIds[msg.sender]
                ) {
                    index = i;
                    break;
                }
            }
            for (
                uint i = index;
                i < prevDistributor.consumerIds.length - 1;
                i++
            ) {
                prevDistributor.consumerIds[i] = prevDistributor.consumerIds[
                    i + 1
                ];
            }
            prevDistributor.consumerIds.pop();
        }
        distributor.consumerIds.push(consumerId);
        consumer.startCycleTime = block.timestamp;
        //TODO: uncomment this aftrt testing and remove the bottom one
        // consumer.endCycleTime = block.timestamp + 30 days;
        consumer.endCycleTime = block.timestamp;
        consumer.isElectricitySupply = true;
        consumer.distributorId = _distributorIndex;
        consumer.isLastElectricityBillPaid = true;
        emit ConsumerConnectedToDistributor(
            consumerId,
            _distributorIndex,
            prevDistributorId
        );
    }

    function getConsumersFromADistributor(
        uint256 _distributorIndex
    ) public view returns (uint256[] memory) {
        // Distributor memory distributor = distributors[_distributorIndex];
        // uint256 currentTime = block.timestamp;
        // uint256 totalEnergyConsumedByConsumers;
        // for (uint256 i = 0; i < distributor.consumerIds.length; i++) {
        //     Consumer memory consumer = consumers[distributor.consumerIds[i]];
        //     uint256 consumed = currentTime - consumer.startCycleTime;
        //     totalEnergyConsumedByConsumers += consumed;
        // }
        // return totalEnergyConsumedByConsumers;
        return distributors[_distributorIndex].consumerIds;
    }

    function payBill() public onlyConsumerOwner {
        Consumer storage consumer = consumers[
            consumersAddressToIds[msg.sender]
        ];
        require(
            block.timestamp >= consumer.endCycleTime,
            "Payment can only be made after 30 days"
        );
        Payment memory payment = Payment(
            consumer.energyConsumedInCurrentCycle,
            consumer.startCycleTime,
            block.timestamp
        );
        consumerPayments[msg.sender].push(payment);
        consumer.startCycleTime = block.timestamp;
        //TODO: uncomment this after testing
        // consumer.endCycleTime = block.timestamp + 30 days;
        consumer.endCycleTime = block.timestamp;
        consumer.energyConsumedInCurrentCycle = 0;
        consumer.isElectricitySupply = true;
        consumer.isLastElectricityBillPaid = true;

        //@TODO: need to be reimplemented
        // uint256 startCycleTime = consumer.startCycleTime;
        // uint256 energyUsed = block.timestamp - consumer.startCycleTime;
        // Distributor storage distributor = distributors[consumer.distributorId];
        // distributor.totalEnergySold += energyUsed;
        // consumer.totalEnergyConsumed += energyUsed;
        // uint256 today = block.timestamp / 86400;
        // // consumerPayments[msg.sender].
        // consumerPayments[msg.sender].push(
        //     Payment(energyUsed, consumer.startCycleTime, block.timestamp)
        // );
        // consumer.startCycleTime = block.timestamp;
        emit ElectricityPaidByConsumer(
            consumersAddressToIds[msg.sender],
            payment.unitsConsumed,
            payment.startTime,
            block.timestamp
        );
    }

    function payBillAndCancelSupply() public {
        Consumer storage consumer = consumers[
            consumersAddressToIds[msg.sender]
        ];

        require(
            block.timestamp >= consumer.endCycleTime,
            "Payment can only be made after 30 days"
        );
        uint256 prevDistributorId = consumer.distributorId;
        Payment memory payment = Payment(
            consumer.energyConsumedInCurrentCycle,
            consumer.startCycleTime,
            consumer.endCycleTime
        );
        consumerPayments[msg.sender].push(payment);
        consumer.startCycleTime = 0;
        consumer.endCycleTime = 0;
        consumer.energyConsumedInCurrentCycle=0;
        consumer.isElectricitySupply = false;
        consumer.isLastElectricityBillPaid = true;
        consumer.distributorId = 0;

        // remove consumer from the distributor list
        Distributor storage prevDistributor = distributors[prevDistributorId];
        uint256 index;
        for (uint256 i = 0; i < prevDistributor.consumerIds.length; i++) {
            if (
                prevDistributor.consumerIds[i] ==
                consumersAddressToIds[msg.sender]
            ) {
                index = i;
                break;
            }
        }
        for (uint i = index; i < prevDistributor.consumerIds.length - 1; i++) {
            prevDistributor.consumerIds[i] = prevDistributor.consumerIds[i + 1];
        }
        prevDistributor.consumerIds.pop();

        emit ConsumerCancelledElectricity(consumersAddressToIds[msg.sender],prevDistributorId,payment.unitsConsumed,payment.startTime, block.timestamp/86400);
    }

    function getUnitsConsumedByConsumerInCycle(
        uint256 consumerIndex
    ) public view returns (uint256) {
        return consumers[consumerIndex].energyConsumedInCurrentCycle;
    }

    function getDistributors() public view returns (uint[] memory) {
        return distributorArray;
    }

    // TODO: Check every 15 mins to see the energy produced by each consumer and then reduce the amount of emergy used by consumers by calculating the block timestamp

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

    function getSubstationsOfPowerPlant(
        uint256 _powerplantIndex
    )
        external
        view
        powerPlantExists(_powerplantIndex)
        returns (Substation[] memory)
    {
        uint256[] memory substationIds = getPowerplantById(_powerplantIndex)
            .substationIds;
        Substation[] memory substationsArray = new Substation[](
            substationIds.length
        );
        for (uint256 i = 0; i < substationIds.length; i++) {
            substationsArray[i] = (getSubstationById(substationIds[i]));
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

    function getSubstationEnergyBoughtByDay(
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

    function getConsumerById(
        uint256 _consumerIndex
    ) public view consumerExists(_consumerIndex) returns (Consumer memory) {
        return consumers[_consumerIndex];
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

    modifier consumerExists(uint256 _consumerIndex) {
        require(
            consumers[_consumerIndex].consumerAddress != address(0),
            "Consumer does not exist"
        );
        _;
    }

    modifier onlyConsumerOwner() {
        require(
            consumersAddressToIds[msg.sender] != 0,
            "Consumer does not exist or you are not the owner"
        );
        require(
            consumers[consumersAddressToIds[msg.sender]].consumerAddress ==
                msg.sender,
            "You are not the owner"
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
