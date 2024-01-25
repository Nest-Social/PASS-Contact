const { ethers, upgrades } = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();
  const PowerCurveN2 = await ethers.deployContract("PowerCurveN2", { gasLimit: "0x1000000"});
  await PowerCurveN2.waitForDeployment();
  console.log(`Power Curve n2 deployed to ${PowerCurveN2.target}`);

  const PowerCurveSqrt = await ethers.deployContract("PowerCurveSqrt", { gasLimit: "0x1000000"});
  await PowerCurveSqrt.waitForDeployment();
  console.log(`Power Curve sqrt deployed to ${PowerCurveSqrt.target}`);

  const NFTImplementationERC20 = await ethers.deployContract("NFTImplementationERC20", { gasLimit: "0x1000000"});
  await NFTImplementationERC20.waitForDeployment();
  console.log(`NFT Implementation ERC20 deployed to ${NFTImplementationERC20.target}`);

  const NFTImplementationETH = await ethers.deployContract("NFTImplementationETH", { gasLimit: "0x1000000"});
  await NFTImplementationETH.waitForDeployment();
  console.log(`NFT Implementation ETH deployed to ${NFTImplementationETH.target}`);

  const NFTFactory = await ethers.getContractFactory("NFTFactory");
  const nftfactory = await upgrades.deployProxy(NFTFactory);
  await nftfactory.waitForDeployment();
  console.log(`NFT Factory deployed to ${nftfactory.target}`);

  await nftfactory.setImplementationERC20("0x92AAB45F66015508bE03E4FdcB1d28C4227422C9", { gasLimit: "0x100000"});
  await nftfactory.setImplementationETH("0xCcc5fC65064d976B6a3F5d4bCD68d71F23B58BCA", { gasLimit: "0x100000"});
  await nftfactory.setProtocolFeeMultiplier(ethers.parseEther("0.005"), { gasLimit: "0x100000"});
  await nftfactory.setProtocolFeeReceiver(owner.address, { gasLimit: "0x100000"});
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
