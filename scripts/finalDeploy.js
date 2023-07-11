const hre = require("hardhat");

async function main() {

  const ERC4907 = await hre.ethers.getContractFactory("ERC4907");
  // const lock = await Lock.deploy(unlockTime, { value: lockedAmount });
  const contract = await ERC4907.deploy();
  await contract.deployed();
  console.log("4907 Contract Address: ", contract.address);

  const NFTMarketPlace = await hre.ethers.getContractFactory("NFTMarketPlace");
  const marketContract = await NFTMarketPlace.deploy(contract.address,1);
  await marketContract.deployed();
  console.log("NFTMarketPlace Contract Address: ", marketContract.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
