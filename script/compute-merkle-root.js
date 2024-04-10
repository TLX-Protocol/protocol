const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");
const path = require("path");

const expectedTotal = 6_000_000n * 10n**18n;

const rootDir = path.dirname(__dirname);
const snapshotFile = path.join(rootDir, "data", "snapshot.json");

const snapshot = JSON.parse(fs.readFileSync(snapshotFile, "utf8"));
const sortedSnapshot = Object.entries(snapshot).sort(([a], [b]) =>
  a.toLowerCase().localeCompare(b.toLowerCase())
);
const merkleTreeData = sortedSnapshot.map(([address, data]) => [
  address,
  BigInt(data.total_share) * 10n ** 18n,
]);
const totalValue = merkleTreeData.reduce((acc, [, value]) => acc + value, 0n);
if (totalValue !== expectedTotal) {
  throw new Error(
    `Total value is not as expected. Expected: ${expectedTotal}, got: ${totalValue}`
  );
}


const tree = StandardMerkleTree.of(merkleTreeData, ["address", "uint256"]);
console.log("root", tree.root);

// get some proof for testing
 console.log(merkleTreeData[123], tree.getProof(123));
