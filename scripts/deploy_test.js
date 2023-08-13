const { ethers } = require("hardhat")
const fs = require("fs")
const path = require("path")

async function main() {
    //
    console.log("Deploying...")
    const deployedContract = await ethers.deployContract("DynamicConsent")
    await deployedContract.waitForDeployment()
    console.log("Contract deployed")

    const folder = 1
    let consents = JSON.parse(fs.readFileSync(path.join("./Release", "consents", folder.toString(), "training_data.json")))
    let researcherqueries = JSON.parse(fs.readFileSync(path.join("./Release", "queries", "researcher_queries.json")))
    let patientqueries = JSON.parse(fs.readFileSync(path.join("./Release", "queries", "patient_queries.json")))

    console.time("insertion")
    for (const i in consents) {
        if (i < 99) {
            await deployedContract.storeRecord(
                consents[i]["patientID"],
                consents[i]["studyID"],
                consents[i]["timestamp"],
                consents[i]["categorySharingChoices"],
                consents[i]["elementSharingChoices"]
            )
        } else {
            break
        }
    }
    console.timeEnd("insertion")

    console.time("researcher query")
    // patientIDs = await deployedContract.queryForResearcher(
    //     researcherqueries[0]["studyID"],
    //     researcherqueries[0]["timestamp"],
    //     researcherqueries[0]["categorySharingChoices"],
    //     researcherqueries[0]["elementSharingChoices"]
    // )
    patientIDs = await deployedContract.queryForResearcher(
        3,
        1641053693,
        ["03_Living Environment and Lifestyle", "04_Biospecimen", "05_Socioeconomic Status", "07_Laboratory Test Results"],
        ["01_02_Mental health disease or condition", "01_03_Sexual or reproductive disease or condition"]
    )
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
    outputstring = await deployedContract.queryForPatient(9319, 3, 1641024390, 1641027411)
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
