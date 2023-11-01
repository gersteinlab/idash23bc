# idash23bc
1st place winning solution to track 2 of the [iDASH 2023 secure genome analysis competition](http://www.humangenomeprivacy.org/2023/)

## Requirements
 - [Nodejs](https://nodejs.org) 
 - [yarn](https://yarnpkg.com/getting-started/install)

## Install
git clone this repo, then:

```
cd idash23bc
yarn
```

## Usage

simple deploy
```
yarn hardhat run scripts/deploy_simple.js
```

Or edit hardhat.config.js with configs for `your_network`, and run
```
yarn hardhat run scripts/deploy_simple.js --network your_network
```

testing/benchmark
```
yarn hardhat run scripts/benchmark1.js
yarn hardhat test
```
