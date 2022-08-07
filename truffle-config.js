require("babel-register");
require("babel-polyfill");
require('dotenv').config();
const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*", // Match any network id
    },
    mainnet: {
      provider: () => new HDWalletProvider(
        process.env.PRIVATE_KEY, 
        process.env.INFURA_URL
      ),
      network_id: 56,       //mainnet
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
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    bscscan: ''
  }
};
