const { ethers } = require("hardhat")
const fs = require("fs")
const path = require("path")
const { expect, assert } = require("chai")

describe("pquery testset 1 (start/end time)", function () {
    let deployedContract
    before(async function () {
        console.log("Deploying...")
        deployedContract = await ethers.deployContract("DynamicConsent")
        await deployedContract.waitForDeployment()
        console.log("Contract deployed")

        console.time("insertion")
        for (let i = 0; i < 99; i++) {
            await deployedContract.storeRecord(42, i, i * 2 + 100, ["01_testcat"], ["01_01_testele1", "01_02_testele2"])
        }
        for (let i = 0; i < 99; i++) {
            await deployedContract.storeRecord(45, i, i * 2 + 101, ["01_testcat"], ["01_01_testele1", "01_02_testele2"])
        }
        console.timeEnd("insertion")
    })

    it("Test patient query 1", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, -1, 166, 254)
        console.timeEnd("patient query")
        let expectedString = ""
        for (let i = 33; i <= 77; i++) {
            expectedString += i + "," + (i * 2 + 100) + "," + "[01_testcat],[01_01_testele1,01_02_testele2]\n"
        }
        assert.equal(outputstring, expectedString)
    })

    it("Test patient query 1.1", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, -1, 165, 254)
        console.timeEnd("patient query")
        let expectedString = ""
        for (let i = 33; i <= 77; i++) {
            expectedString += i + "," + (i * 2 + 100) + "," + "[01_testcat],[01_01_testele1,01_02_testele2]\n"
        }
        assert.equal(outputstring, expectedString)
    })

    it("Test patient query 1.2", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, -1, 166, 255)
        console.timeEnd("patient query")
        let expectedString = ""
        for (let i = 33; i <= 77; i++) {
            expectedString += i + "," + (i * 2 + 100) + "," + "[01_testcat],[01_01_testele1,01_02_testele2]\n"
        }
        assert.equal(outputstring, expectedString)
    })

    it("Test patient query 2", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, -1, -1, 254)
        console.timeEnd("patient query")
        let expectedString = ""
        for (let i = 0; i <= 77; i++) {
            expectedString += i + "," + (i * 2 + 100) + "," + "[01_testcat],[01_01_testele1,01_02_testele2]\n"
        }
        assert.equal(outputstring, expectedString)
    })

    it("Test patient query 3", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, -1, 166, -1)
        console.timeEnd("patient query")
        let expectedString = ""
        for (let i = 33; i <= 98; i++) {
            expectedString += i + "," + (i * 2 + 100) + "," + "[01_testcat],[01_01_testele1,01_02_testele2]\n"
        }
        assert.equal(outputstring, expectedString)
    })

    it("Test patient query 4", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, -1, -1, -1)
        console.timeEnd("patient query")
        let expectedString = ""
        for (let i = 0; i <= 98; i++) {
            expectedString += i + "," + (i * 2 + 100) + "," + "[01_testcat],[01_01_testele1,01_02_testele2]\n"
        }
        assert.equal(outputstring, expectedString)
    })

    it("Test patient query 4", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, -1, 210, 210)
        console.timeEnd("patient query")
        let expectedString = ""
        for (let i = 55; i <= 55; i++) {
            expectedString += i + "," + (i * 2 + 100) + "," + "[01_testcat],[01_01_testele1,01_02_testele2]\n"
        }
        assert.equal(outputstring, expectedString)
    })

    it("Test patient query 5", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, 67, -1, -1)
        console.timeEnd("patient query")
        let expectedString = ""
        for (let i = 67; i <= 67; i++) {
            expectedString += i + "," + (i * 2 + 100) + "," + "[01_testcat],[01_01_testele1,01_02_testele2]\n"
        }
        assert.equal(outputstring, expectedString)
    })

    it("Test patient query 6", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, 231, -1, -1)
        console.timeEnd("patient query")
        let expectedString = ""
        assert.equal(outputstring, expectedString)
    })

    it("Test patient query 7", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, 67, 333, -1)
        console.timeEnd("patient query")
        let expectedString = ""
        assert.equal(outputstring, expectedString)
    })

    it("Test patient query 8", async function () {
        console.time("patient query")
        outputstring = await deployedContract.queryForPatient(42, 67, -1, 82)
        console.timeEnd("patient query")
        let expectedString = ""
        assert.equal(outputstring, expectedString)
    })
})

describe("rquery testset 1 (matching)", function () {
    let deployedContract
    before(async function () {
        console.log("Deploying...")
        deployedContract = await ethers.deployContract("DynamicConsent")
        await deployedContract.waitForDeployment()
        console.log("Contract deployed")

        console.time("insertion")
        await deployedContract.storeRecord(111, 123, 100, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(
            222,
            234,
            200,
            ["01_testcat", "02_testcat", "03_testcat"],
            ["04_01_testele", "04_02_testele", "07_01_testele", "09_01_testele"]
        )
        await deployedContract.storeRecord(333, 345, 300, ["01_testcat", "08_testcat", "23_testcat"], ["07_01_testele2"])
        console.timeEnd("insertion")
    })

    it("Test researcher query 1", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 2", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, ["99_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 3", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, ["01_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 4", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, [], ["02_01_testele1"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 5", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, [], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 6", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, [], ["99_01_testele1"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 7", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, [], ["02_01_testele1", "02_02_testele2", "02_99_testele99"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    // ["01_testcat", "02_testcat", "03_testcat"], ["04_01_testele","04_02_testele","07_01_testele","09_01_testele"])

    it("Test researcher query 8", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(234, -1, [], ["01_01_testele", "01_02_testele", "01_33_testele", "01_99_testele"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [222]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 9", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(
            234,
            -1,
            ["02_testcat", "03_testcat"],
            ["01_01_testele", "01_02_testele", "01_33_testele", "01_99_testele"]
        )
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [222]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 10", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(
            234,
            -1,
            ["01_testcat", "02_testcat", "03_testcat"],
            ["01_01_testele", "01_02_testele", "01_33_testele", "01_99_testele", "04_01_testele", "04_02_testele", "07_01_testele", "09_01_testele"]
        )
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [222]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 11", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(
            234,
            -1,
            ["01_testcat", "03_testcat"],
            [
                "01_01_testele",
                "01_02_testele",
                "01_33_testele",
                "01_99_testele",
                "02_33_testele",
                "02_99_testele",
                "04_01_testele",
                "04_02_testele",
                "07_01_testele",
                "09_01_testele",
            ]
        )
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [222]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 12", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(234, -1, ["01_testcat", "02_testcat", "03_testcat"], ["04_99_testele"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 13", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(234, -1, ["01_testcat", "02_testcat", "03_testcat", "04_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    //     await deployedContract.storeRecord(333, 345, 300, ["01_testcat", "08_testcat", "23_testcat"], ["07_01_testele2"])

    it("Test researcher query 14", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(345, -1, ["01_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [333]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 14", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(345, -1, [], ["07_01_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [333]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 15", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(345, -1, [], ["07_99_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 15", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(345, -1, ["99_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 16", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(345, -1, ["01_testcat", "08_testcat", "15_testcat", "23_testcat"], ["07_01_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 16", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(345, -1, ["01_testcat", "08_testcat", "23_testcat"], ["03_03_testele", "07_01_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })
})

describe("rquery testset 2 (latestIDs)", function () {
    let deployedContract
    before(async function () {
        console.log("Deploying...")
        deployedContract = await ethers.deployContract("DynamicConsent")
        await deployedContract.waitForDeployment()
        console.log("Contract deployed")

        console.time("insertion")
        await deployedContract.storeRecord(111, 123, 100, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(111, 123, 200, ["01_testcat"], [])
        await deployedContract.storeRecord(111, 123, 300, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("insertion")
    })

    it("Test researcher query 1", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 2", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 350, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 3", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 300, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 4", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 250, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 5", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 150, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 6", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 100, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 7", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 55, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })
})

describe("rquery testset 3 (more latestIDs)", function () {
    let deployedContract
    before(async function () {
        console.log("Deploying...")
        deployedContract = await ethers.deployContract("DynamicConsent")
        await deployedContract.waitForDeployment()
        console.log("Contract deployed")

        console.time("insertion")

        await deployedContract.storeRecord(111, 123, 50, ["01_testcat"], [])
        await deployedContract.storeRecord(222, 123, 50, ["01_testcat"], [])
        await deployedContract.storeRecord(333, 123, 50, ["01_testcat"], [])
        await deployedContract.storeRecord(444, 123, 50, ["01_testcat"], [])
        await deployedContract.storeRecord(555, 123, 50, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(666, 123, 50, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(777, 123, 50, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])

        await deployedContract.storeRecord(111, 123, 100, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(222, 123, 100, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(333, 123, 100, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(444, 123, 100, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(555, 123, 100, ["01_testcat"], [])
        await deployedContract.storeRecord(666, 123, 100, ["01_testcat"], [])
        await deployedContract.storeRecord(777, 123, 100, ["01_testcat"], [])

        await deployedContract.storeRecord(111, 123, 200, ["01_testcat"], [])
        await deployedContract.storeRecord(222, 123, 200, ["01_testcat"], [])
        await deployedContract.storeRecord(333, 123, 200, ["01_testcat"], [])
        await deployedContract.storeRecord(444, 123, 200, ["01_testcat"], [])
        await deployedContract.storeRecord(555, 123, 200, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(666, 123, 200, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(777, 123, 200, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("insertion")
    })

    it("Test researcher query 1", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [555, 666, 777]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 2", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 150, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111, 222, 333, 444]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 3", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 200, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [555, 666, 777]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 4", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 67, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [555, 666, 777]
        assert.equal(regularIntList, expectedIDs.toString())
    })
})

describe("rquery testset 3 (more matching)", function () {
    let deployedContract
    before(async function () {
        console.log("Deploying...")
        deployedContract = await ethers.deployContract("DynamicConsent")
        await deployedContract.waitForDeployment()
        console.log("Contract deployed")

        console.time("insertion")

        await deployedContract.storeRecord(111, 123, 100, ["09_testcat"], [])
        await deployedContract.storeRecord(111, 123, 200, ["08_testcat"], [])
        await deployedContract.storeRecord(111, 123, 300, ["07_testcat"], [])
        await deployedContract.storeRecord(111, 123, 400, ["06_testcat"], [])
        await deployedContract.storeRecord(111, 123, 500, ["05_testcat"], [])
        await deployedContract.storeRecord(111, 123, 600, ["04_testcat"], [])
        await deployedContract.storeRecord(111, 123, 700, ["03_testcat"], [])
        await deployedContract.storeRecord(111, 123, 800, ["02_testcat"], [])
        await deployedContract.storeRecord(111, 123, 900, ["01_testcat"], [])
        console.timeEnd("insertion")
    })

    it("Test researcher query 1", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 650, ["04_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 2", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, ["01_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 3", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 650, ["01_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 4", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, ["04_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 5", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 99, ["09_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 6", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 100, ["09_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 7", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 101, ["09_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 8", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 900, ["01_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 9", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, 899, ["01_testcat"], [])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })
})

describe("rquery testset 4 (edge case)", function () {
    let deployedContract
    before(async function () {
        console.log("Deploying...")
        deployedContract = await ethers.deployContract("DynamicConsent")
        await deployedContract.waitForDeployment()
        console.log("Contract deployed")

        console.time("insertion")
        await deployedContract.storeRecord(111, 123, 100, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        await deployedContract.storeRecord(111, 234, 300, ["08_testcat"], ["07_01_testele2"])
        console.timeEnd("insertion")
    })

    it("Test researcher query 1", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(123, -1, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = [111]
        assert.equal(regularIntList, expectedIDs.toString())
    })

    it("Test researcher query 2", async function () {
        console.time("researcher query")
        let patientIDs = await deployedContract.queryForResearcher(234, -1, ["01_testcat"], ["02_01_testele1", "02_02_testele2"])
        console.timeEnd("researcher query")

        let regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        let expectedIDs = []
        assert.equal(regularIntList, expectedIDs.toString())
    })
})
