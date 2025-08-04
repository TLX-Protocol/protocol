require('dotenv').config();
const { ethers } = require("ethers");

// ABI for the functions we need
const FACTORY_ABI = [
    "function allTokens() external view returns (address[] memory)",
];

const TOKEN_ABI = [
    "function isPaused() external view returns (bool)",
    "function isActive() external view returns (bool)",
    "function targetAsset() external view returns (string memory)",
    "function targetLeverage() external view returns (uint256)",
    "function isLong() external view returns (bool)",
    "function totalSupply() external view returns (uint256)",
    "function exchangeRate() external view returns (uint256)",
    "function symbol() external view returns (string memory)",
];

const HELPER_ABI = [
    "function leveragedTokenData() external view returns (tuple(address addr, string symbol, uint256 totalSupply, string targetAsset, uint256 targetLeverage, bool isLong, bool isActive, uint256 rebalanceThreshold, uint256 exchangeRate, bool canRebalance, bool hasPendingLeverageUpdate, uint256 remainingMargin, uint256 leverage, uint256 assetPrice, uint256 userBalance)[] memory)",
];

// Format number with commas and no decimals
function formatUSD(value) {
    const num = parseFloat(ethers.formatEther(value));
    return num.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

async function generateTokenSummary() {
    console.log("📊 Generating Leveraged Token Summary...");
    console.log(`🕒 Generated at: ${new Date().toLocaleString()}`);
    
    // Connect to the network - Alchemy RPC only
    const rpcUrl = process.env.ALCHEMY_URL;
    if (!rpcUrl) {
        throw new Error("ALCHEMY_URL environment variable is required");
    }
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    
    // Get network info
    const network = await provider.getNetwork();
    console.log(`🌐 Network: ${network.name} (Chain ID: ${network.chainId})`);
    console.log("━".repeat(80));
    
    // Contract addresses from deployments.json
    const FACTORY_ADDRESS = "0x5Dd85f51e9fD6aDE8ecc216C07919ecD443eB14d";
    const HELPER_ADDRESS = "0xBdAF7A2C4ee313Be468B9250609ba8496131B1f0";
    
    const factory = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, provider);
    const helper = new ethers.Contract(HELPER_ADDRESS, HELPER_ABI, provider);
    
    console.log("Fetching token data...");
    
    try {
        // Get detailed data from helper contract
        const tokenData = await helper.leveragedTokenData();
        
        // Filter for active tokens only and create a mutable copy
        const activeTokens = [...tokenData.filter(token => token.isActive)];
        
        // Filter for liquidated tokens
        const liquidatedTokens = [...tokenData.filter(token => !token.isActive)];
        
        console.log(`\n📈 ACTIVE TOKENS SUMMARY (${activeTokens.length} tokens)`);
        console.log("=".repeat(105));
        console.log("│ Asset │ Leverage │ Direction │ Symbol │ TVL (sUSD) │ Current Leverage │ Can Rebalance │");
        console.log("=".repeat(105));
        
        let totalTVL = ethers.parseEther("0");
        let totalOI = ethers.parseEther("0");
        
        // Sort by TVL descending
        const sortedTokens = activeTokens.sort((a, b) => {
            const tvlA = (a.totalSupply * a.exchangeRate) / ethers.parseEther("1");
            const tvlB = (b.totalSupply * b.exchangeRate) / ethers.parseEther("1");
            return Number(tvlB - tvlA);
        });
        
        let smallTokensCount = 0;
        let smallTokensTVL = ethers.parseEther("0");
        let smallTokensOI = ethers.parseEther("0");
        
        for (const token of sortedTokens) {
            const tvl = (token.totalSupply * token.exchangeRate) / ethers.parseEther("1");
            const oi = token.remainingMargin;
            const currentLeverage = Number(token.leverage) / Number(ethers.parseEther("1"));
            const targetLeverage = Number(token.targetLeverage) / Number(ethers.parseEther("1"));
            
            totalTVL += tvl;
            totalOI += oi;
            
            // Check if TVL is below 1000 sUSD
            const tvlAmount = Number(ethers.formatEther(tvl));
            if (tvlAmount < 1000) {
                smallTokensCount++;
                smallTokensTVL += tvl;
                smallTokensOI += oi;
                continue;
            }
            
            const direction = token.isLong ? "LONG" : "SHORT";
            const canRebalance = token.canRebalance ? "✅" : "❌";
            
            console.log(
                `│ ${token.targetAsset.padEnd(4)} │ ${targetLeverage.toFixed(1).padStart(6)}x │ ${direction.padEnd(8)} │ ${token.symbol.padEnd(6)} │ ${formatUSD(tvl).padStart(10)} │ ${currentLeverage.toFixed(2).padStart(13)} │ ${canRebalance.padEnd(12)} │`
            );
        }
        
        // Add row for combined small tokens
        if (smallTokensCount > 0) {
            console.log("├───────────────────────────────────────────────────────────────────────────────────────────────────────┤");
            console.log(
                `│ ${`Other (${smallTokensCount} tokens < 1,000 sUSD)`.padEnd(58)} │ ${formatUSD(smallTokensTVL).padStart(10)} │       -          │       -       │`
            );
        }
        
        console.log("=".repeat(105));
        console.log(`\n💰 PROTOCOL TOTALS:`);
        console.log(`Total TVL: ${formatUSD(totalTVL)} sUSD`);
        console.log(`Total Open Interest: ${formatUSD(totalOI)} sUSD`);
        const avgLeverage = totalTVL > 0n ? Number(totalOI * 100n / totalTVL) / 100 : 0;
        console.log(`Average Leverage: ${avgLeverage.toFixed(2)}x`);
        
        // Asset breakdown
        const assetBreakdown = {};
        for (const token of sortedTokens) {
            const tvl = (token.totalSupply * token.exchangeRate) / ethers.parseEther("1");
            if (!assetBreakdown[token.targetAsset]) {
                assetBreakdown[token.targetAsset] = { tvl: 0n, tokens: 0 };
            }
            assetBreakdown[token.targetAsset].tvl += tvl;
            assetBreakdown[token.targetAsset].tokens += 1;
        }
        
        console.log(`\n📊 BY ASSET:`);
        console.log("-".repeat(50));
        Object.entries(assetBreakdown)
            .sort(([,a], [,b]) => Number(b.tvl - a.tvl))
            .forEach(([asset, data]) => {
                console.log(`${asset}: ${formatUSD(data.tvl)} sUSD (${data.tokens} tokens)`);
            });
        
        // Leverage breakdown
        const leverageBreakdown = {};
        for (const token of sortedTokens) {
            const tvl = (token.totalSupply * token.exchangeRate) / ethers.parseEther("1");
            const leverage = Number(token.targetLeverage) / Number(ethers.parseEther("1"));
            const key = `${leverage}x`;
            if (!leverageBreakdown[key]) {
                leverageBreakdown[key] = { tvl: 0n, tokens: 0 };
            }
            leverageBreakdown[key].tvl += tvl;
            leverageBreakdown[key].tokens += 1;
        }
        
        console.log(`\n📊 BY LEVERAGE:`);
        console.log("-".repeat(50));
        Object.entries(leverageBreakdown)
            .sort(([,a], [,b]) => Number(b.tvl - a.tvl))
            .forEach(([leverage, data]) => {
                console.log(`${leverage}: ${formatUSD(data.tvl)} sUSD (${data.tokens} tokens)`);
            });
        
        // Display liquidated tokens table
        if (liquidatedTokens.length > 0) {
            console.log(`\n💀 LIQUIDATED TOKENS (${liquidatedTokens.length} tokens)`);
            console.log("=".repeat(80));
            console.log("│ Asset │ Leverage │ Direction │ Symbol │ Last TVL │ Final Leverage │");
            console.log("=".repeat(80));
            
            // Sort liquidated tokens by targetAsset and leverage
            const sortedLiquidated = liquidatedTokens.sort((a, b) => {
                if (a.targetAsset !== b.targetAsset) {
                    return a.targetAsset.localeCompare(b.targetAsset);
                }
                return Number(a.targetLeverage - b.targetLeverage);
            });
            
            for (const token of sortedLiquidated) {
                const direction = token.isLong ? "LONG" : "SHORT";
                const targetLeverage = Number(token.targetLeverage) / Number(ethers.parseEther("1"));
                const tvl = (token.totalSupply * token.exchangeRate) / ethers.parseEther("1");
                const currentLeverage = Number(token.leverage) / Number(ethers.parseEther("1"));
                
                console.log(
                    `│ ${token.targetAsset.padEnd(4)} │ ${targetLeverage.toFixed(1).padStart(6)}x │ ${direction.padEnd(8)} │ ${token.symbol.padEnd(6)} │ ${formatUSD(tvl).padStart(8)} │ ${currentLeverage.toFixed(2).padStart(12)} │`
                );
            }
            
            console.log("=".repeat(80));
            
            // Count by asset
            const liquidatedByAsset = {};
            for (const token of liquidatedTokens) {
                if (!liquidatedByAsset[token.targetAsset]) {
                    liquidatedByAsset[token.targetAsset] = 0;
                }
                liquidatedByAsset[token.targetAsset]++;
            }
            
            console.log("\n📊 LIQUIDATED BY ASSET:");
            console.log("-".repeat(30));
            Object.entries(liquidatedByAsset)
                .sort(([,a], [,b]) => b - a)
                .forEach(([asset, count]) => {
                    console.log(`${asset}: ${count} tokens`);
                });
        }
        
    } catch (error) {
        console.error("\n❌ Error fetching token data:", error.message);
        console.error("Helper contract address:", HELPER_ADDRESS);
        console.error("Network:", (await provider.getNetwork()).name);
        console.error("Chain ID:", (await provider.getNetwork()).chainId);
        throw new Error("Failed to fetch leveraged token data from helper contract");
    }
}

// Run the script
if (require.main === module) {
    generateTokenSummary()
        .then(() => {
            console.log("\n✅ Summary generated successfully");
            process.exit(0);
        })
        .catch((error) => {
            console.error("Script failed:", error);
            process.exit(1);
        });
}

module.exports = { generateTokenSummary }; 