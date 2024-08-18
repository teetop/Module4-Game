import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

// const config: HardhatUserConfig = {
//   solidity: "0.8.24",
// };
//
// export default config;





require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const { URL, PRIVATE_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
const config: HardhatUserConfig = {
  solidity: "0.8.24",
  defaultNetwork: "fuji",
  etherscan: {
    apiKey: {
      snowtrace: "snowtrace", // apiKey is not required, just set a placeholder
    },
    customChains: [
      {
        network: "snowtrace",
        chainId: 43113,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/testnet/evm/43113/etherscan",
          browserURL: "https://testnet.snowtrace.io",
        },
      },
    ],
  },
  networks: {
    snowtrace: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [`0x${PRIVATE_KEY}`],
    },
    fuji: {
      url: URL,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
};

export default config;