import '@nomicfoundation/hardhat-foundry'
import '@nomicfoundation/hardhat-toolbox'
import { config as dotenvConfig } from 'dotenv'
import { statSync } from 'fs'
import { type HardhatUserConfig, type NetworkUserConfig } from 'hardhat/types'

import { accountsPrivates } from './scripts/address-list'

dotenvConfig({ path: '.env.hardhat' })

if (!statSync('.env.hardhat').isFile()) {
  console.warn('No .env.hardhat file found, required to use tenderly')
  console.warn('Please check .env.hardhat.example for an example')
}

const { TENDERLY_URL } = process.env
const tenderlyNetwork = {} as any
if (TENDERLY_URL != null && TENDERLY_URL.length > 10) {
  tenderlyNetwork.tenderly = {
    url: TENDERLY_URL,
    accounts: accountsPrivates,
  } as NetworkUserConfig
}

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.18',
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
      forking: {
        url: 'https://arb1.arbitrum.io/rpc',
      },
    },
    tenderly: {
      url: TENDERLY_URL,
      accounts: ['0x'],
    },
    ...tenderlyNetwork,
  },
}

export default config
