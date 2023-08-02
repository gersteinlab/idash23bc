// simple script that only deploys the smart contract

const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  //
  console.log("Deploying...");
  const deployedContract = await ethers.deployContract("DynamicConsent");
  await deployedContract.waitForDeployment();
  console.log("Contract deployed");
}

// main
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
