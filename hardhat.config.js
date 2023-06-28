require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.16",
  networks: {
    goerli: {
      url: `https://frosty-side-fog.ethereum-goerli.discover.quiknode.pro/${process.env.QUICKNODE_KEY}/`,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
    gnosis: {
      url: `https://blissful-fragrant-water.xdai.quiknode.pro/${process.env.QUICKNODE_GNO_KEY}/`,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
    mumbai: {
      url: `https://compatible-solitary-grass.matic-testnet.quiknode.pro/${process.env.QUICKNODE_MUMB_KEY}/`,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
    optimism: {
      url: `https://opt-mainnet.g.alchemy.com/v2/${process.env.ALCH_OPTIMISM_KEY}`,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
    scroll: {
      // UMA ORACLE NOT AVAILABLE
      url: `https://alpha-rpc.scroll.io/l2`,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
    linea: {
      // UMA ORACLE NOT AVAILABLE
      url: `https://linea-goerli.infura.io/v3/${process.env.LINEA_KEY}`,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
  },
};
