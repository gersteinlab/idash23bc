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
    let patientqueries = JSON.parse(fs.readFileSync(path.join("./Release", "test_patient_queries2.json")))

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
    for (let [i, rquery] of tdqm(researcherqueries.entries(), { total: 1000 })) {
        patientIDs = await deployedContract.queryForResearcher(
            rquery["studyID"],
            rquery["timestamp"],
            rquery["categorySharingChoices"],
            rquery["elementSharingChoices"]
        )
        // const regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
        // console.log(regularIntList)
    }
    console.timeEnd("researcher query")
    const regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
    console.log(regularIntList)

    console.time("patient query")
    for (let [i, pquery] of tdqm(patientqueries.entries(), { total: 1000 })) {
        outputstring = await deployedContract.queryForPatient(pquery["patientID"], pquery["studyID"], pquery["startTimestamp"], pquery["endTimestamp"])
        // console.log(outputstring)
    }
    console.timeEnd("patient query")

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
