require("@nomicfoundation/hardhat-toolbox")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("hardhat/config")

module.exports = {
    defaultNetwork: "hardhat",
    solidity: {
        version: "0.8.12",
        settings: {
            optimizer: {
                enabled: true,
            },
        },
        evmVersion: "byzantium",
    },
    networks: {
        hardhat: {
            blockGasLimit: 7503599627395863,
            gasPrice: 1,
            initialBaseFeePerGas: 1,
            gas: 6503599627395863,
        },
        localhost: {
            url: "http://127.0.0.1:8545/",
            chainId: 31337,
            blockGasLimit: 7503599627395863,
            gasPrice: 1,
            initialBaseFeePerGas: 1,
            gas: 6503599627395863,
        },
    },
    gasReporter: {
        enabled: true,
    },
}
