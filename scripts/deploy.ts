import { ethers } from "hardhat";

async function main() {

  const DegenGame = await ethers.deployContract("DegenGame");

  await DegenGame.waitForDeployment();

  console.log(
    `DegenGame contract deployed to ${DegenGame.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
