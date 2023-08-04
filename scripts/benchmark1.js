const { ethers } = require("hardhat")
const fs = require("fs")
const path = require("path")
const tdqm = require(`tqdm`)

async function main() {
    //
    console.log("Deploying...")
    const deployedContract = await ethers.deployContract("DynamicConsent")
    await deployedContract.waitForDeployment()
    console.log("Contract deployed")

    const folder = 1
    let consents = JSON.parse(fs.readFileSync(path.join("./Release", "consents", folder.toString(), "training_data.json")))

    let researcherqueries = JSON.parse(fs.readFileSync(path.join("./Release", "test_meaningful_researcher_queries.json")))
    let patientqueries = JSON.parse(fs.readFileSync(path.join("./Release", "test_patient_queries.json")))

    console.time("insertion")
    for (let [i, consent] of tdqm(consents.entries(), { total: 3689 })) {
        await deployedContract.storeRecord(
            consent["patientID"],
            consent["studyID"],
            consent["timestamp"],
            consent["categorySharingChoices"],
            consent["elementSharingChoices"]
        )
    }
    console.timeEnd("insertion")

    console.time("researcher query")
    for (let [i, rquery] of tdqm(researcherqueries.entries(), { total: 50 })) {
        patientIDs = await deployedContract.queryForResearcher(
            rquery["studyID"],
            rquery["timestamp"],
            rquery["categorySharingChoices"],
            rquery["elementSharingChoices"]
        )
        const regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        console.log(regularIntList)
    }
    console.timeEnd("researcher query")
    const regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
    console.log(regularIntList)

    console.time("patient query")
    // outputstring = await deployedContract.queryForPatient(
    //     patientqueries[0]["patientID"],
    //     patientqueries[0]["studyID"],
    //     patientqueries[0]["startTimestamp"],
    //     patientqueries[0]["endTimestamp"]
    // )
    outputstring = await deployedContract.queryForPatient(8837, 3, 1641024390, 1641047888)
    console.timeEnd("patient query")
    console.log(outputstring)

    const used = process.memoryUsage().heapUsed / 1024 / 1024
    console.log(`The script uses approximately ${Math.round(used * 100) / 100} MB`)
}

// main
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
