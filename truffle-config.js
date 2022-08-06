require("babel-register");
require("babel-polyfill");
const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*", // Match any network id
    },
  },

  compilers: {
    solc: {
      version: "0.8.15",
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
