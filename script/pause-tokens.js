const { ethers } = require("ethers");

// ABI for the functions we need
const FACTORY_ABI = [
    "function allTokens() external view returns (address[] memory)",
];

const TOKEN_ABI = [
    "function isPaused() external view returns (bool)",
    "function isActive() external view returns (bool)",
    "function setIsPaused(bool isPaused) external",
    "function targetAsset() external view returns (string memory)",
    "function targetLeverage() external view returns (uint256)",
    "function isLong() external view returns (bool)",
];

async function pauseAllTokens() {
    // Connect to the network (update RPC URL as needed)
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL || "https://mainnet.optimism.io");
    
    // Load private key from environment
    const privateKey = process.env.PRIVATE_KEY;
    if (!privateKey) {
        throw new Error("PRIVATE_KEY environment variable required");
    }
    const wallet = new ethers.Wallet(privateKey, provider);

    // Contract addresses from deployments.json
    const FACTORY_ADDRESS = "0x5Dd85f51e9fD6aDE8ecc216C07919ecD443eB14d";
    
    const factory = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, wallet);
    
    console.log("Getting all leveraged tokens...");
    const allTokens = await factory.allTokens();
    console.log(`Found ${allTokens.length} leveraged tokens`);

    let pausedCount = 0;
    let alreadyPausedCount = 0;
    let inactiveCount = 0;

    for (let i = 0; i < allTokens.length; i++) {
        const tokenAddress = allTokens[i];
        const token = new ethers.Contract(tokenAddress, TOKEN_ABI, wallet);
        
        try {
            // Get token info
            const [isPaused, isActive, targetAsset, targetLeverage, isLong] = await Promise.all([
                token.isPaused(),
                token.isActive(),
                token.targetAsset(),
                token.targetLeverage(),
                token.isLong()
            ]);

            const tokenInfo = `${targetAsset} ${ethers.formatEther(targetLeverage)}x ${isLong ? 'LONG' : 'SHORT'}`;
            
            if (isPaused) {
                console.log(`[${i + 1}/${allTokens.length}] ${tokenInfo} (${tokenAddress}) - Already paused`);
                alreadyPausedCount++;
                continue;
            }

            if (!isActive) {
                console.log(`[${i + 1}/${allTokens.length}] ${tokenInfo} (${tokenAddress}) - Inactive (liquidated), skipping`);
                inactiveCount++;
                continue;
            }

            // Pause the token
            console.log(`[${i + 1}/${allTokens.length}] ${tokenInfo} (${tokenAddress}) - Pausing...`);
            const tx = await token.setIsPaused(true);
            await tx.wait();
            console.log(`  ✅ Paused! Tx: ${tx.hash}`);
            pausedCount++;

        } catch (error) {
            console.error(`Error processing token ${tokenAddress}:`, error.message);
        }
    }

    console.log("\n=== Summary ===");
    console.log(`Total tokens: ${allTokens.length}`);
    console.log(`Already paused: ${alreadyPausedCount}`);
    console.log(`Newly paused: ${pausedCount}`);
    console.log(`Inactive tokens: ${inactiveCount}`);
}

// Run the script
if (require.main === module) {
    pauseAllTokens()
        .then(() => {
            console.log("Script completed successfully");
            process.exit(0);
        })
        .catch((error) => {
            console.error("Script failed:", error);
            process.exit(1);
        });
}

module.exports = { pauseAllTokens }; 