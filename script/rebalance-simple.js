const { ethers } = require('ethers');

// Setup
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Contract addresses
const FACTORY = "0x5Dd85f51e9fD6aDE8ecc216C07919ecD443eB14d";

// ABIs
const factoryAbi = ["function allTokens() external view returns (address[] memory)"];
const tokenAbi = ["function canRebalance() external view returns (bool)", "function rebalance() external"];

async function rebalance() {
    const factory = new ethers.Contract(FACTORY, factoryAbi, signer);
    const tokens = await factory.allTokens();
    
    for (const tokenAddr of tokens) {
        const token = new ethers.Contract(tokenAddr, tokenAbi, signer);
        if (await token.canRebalance()) {
            await token.rebalance();
            console.log(`Rebalanced ${tokenAddr}`);
        }
    }
}

rebalance().catch(console.error);