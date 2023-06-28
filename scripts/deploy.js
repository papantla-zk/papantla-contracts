// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const InsuranceArbitrator = await ethers.getContractFactory(
    "InsuranceArbitrator"
  );
  const _insurance = await InsuranceArbitrator.deploy(
    "0xe9DcE89B076BA6107Bb64EF30678efec11939234" // mumbai usdc
  );

  await _insurance.deployed();

  console.log("InsuranceArbitrator address:", await _insurance.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
