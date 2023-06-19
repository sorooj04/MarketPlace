require("@nomicfoundation/hardhat-toolbox");
// require("dotenv").config();
const dotenv = require('dotenv')
// const { GOERLI_URL, PRIVATE_KEY } = process.env;
/** @type import('hardhat/config').HardhatUserConfig */
const MUMBAI_URL = "https://polygon-mumbai.g.alchemy.com/v2/dhkWwnR0AQiCU6p9gshBKjJB45ByPuaA" //process.env.GOERLI_URL;
const PRIVATE_KEY = "db2a77f094d82da7ebd597be64b3daea556ddbc5ae167ff3d0005c7aa6243f13" //process.env.PRIVATE_KEY;
module.exports = {
  solidity: "0.8.17",
  networks: {
    mumbai: {
      url: MUMBAI_URL,
      accounts: [PRIVATE_KEY],
    },
  },
};
