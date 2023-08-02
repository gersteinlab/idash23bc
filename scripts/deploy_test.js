// this does the same thing as test/test-short, but with some print statements
// also outputs the PDF that is queried as 'deploy2_output.pdf'
// useful for debugging

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
    patientIDs = await deployedContract.queryForResearcher(
        researcherqueries[0]["studyID"],
        researcherqueries[0]["timestamp"],
        researcherqueries[0]["categorySharingChoices"],
        researcherqueries[0]["elementSharingChoices"]
    )
    const regularIntList = patientIDs.map((bigintValue) => parseInt(bigintValue.toString()))
    console.timeEnd("researcher query")
    console.log(regularIntList)

    console.time("patient query")
    outputstring = await deployedContract.queryForPatient(
        patientqueries[0]["patientID"],
        patientqueries[0]["studyID"],
        patientqueries[0]["startTimestamp"],
        patientqueries[0]["endTimestamp"]
    )
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
