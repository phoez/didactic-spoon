const hre = require("hardhat");

async function main() {
  const RPS = await hre.ethers.getContractFactory("ConfidentialRockPaperScissors");
  const rps = await RPS.deploy();
  await rps.waitForDeployment();
  
  const address = await rps.getAddress();
  console.log("ConfidentialRockPaperScissors deployed to:", address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
