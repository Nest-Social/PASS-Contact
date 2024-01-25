const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

function calculateY(x) {
  return 0.1 * x * x + 0.1;
}

describe("Nest_NFT", function () {
  async function deployFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const TST = await ethers.deployContract("MockERC20");
    await TST.waitForDeployment();

    const GNFT = await ethers.deployContract("MockERC721");
    await GNFT.waitForDeployment();

    const PowerCurveN2 = await ethers.deployContract("PowerCurveN2");
    await PowerCurveN2.waitForDeployment();

    const PowerCurveSqrt = await ethers.deployContract("PowerCurveSqrt");
    await PowerCurveSqrt.waitForDeployment();

    const NFTImplementationERC20 = await ethers.deployContract("NFTImplementationERC20");
    await NFTImplementationERC20.waitForDeployment();

    const NFTImplementationETH = await ethers.deployContract("NFTImplementationETH");
    await NFTImplementationETH.waitForDeployment();

    const NFTFactory = await ethers.getContractFactory("NFTFactory");
    const nftfactory = await upgrades.deployProxy(NFTFactory);
    await nftfactory.waitForDeployment();
    
    await nftfactory.setImplementationETH(NFTImplementationETH.target);
    await nftfactory.setImplementationERC20(NFTImplementationERC20.target);
    await nftfactory.setProtocolFeeMultiplier(ethers.parseEther("0.005"));
    await nftfactory.setProtocolFeeReceiver(addr1.address);
    await nftfactory.addDiscountNFT(GNFT.target);

    const e17 = ethers.parseEther("0.1");
    const e16 = ethers.parseEther("0.01");
    const e16_4 = ethers.parseEther("0.04");

    await nftfactory.createNFT("Nest", "NEST", PowerCurveN2.target, e17, e17, e16, e16_4, 1, "ipfs://666666666688888888888");
    await nftfactory.createNFT("Nest", "NEST", PowerCurveSqrt.target, e17, e17, e16, e16_4, 1, "ipfs://666666666688888888888");
    await nftfactory.createNFTERC20("Nest", "NEST", PowerCurveN2.target, e17, e17, e16, e16_4, 1, "ipfs://666666666688888888888", TST.target);
    await nftfactory.createNFTERC20("Nest", "NEST", PowerCurveSqrt.target, e17, e17, e16, e16_4, 1, "ipfs://666666666688888888888", TST.target);


    return {
      TST,
      GNFT,
      PowerCurveN2,
      PowerCurveSqrt,
      NFTImplementationERC20,
      NFTImplementationETH,
      nftfactory,
      owner,
      addr1,
      addr2
    }
  
  }

  describe('NFT-ETH-n2', function () {
      it('Should get right price and check fee', async function() {
        const { owner, nftfactory, addr1, addr2 } = await loadFixture(deployFixture);
        const nft_addr = await nftfactory.getCreatedNFTs(owner.address);
        const NFT_ETH_N2_addr = nft_addr[0];
        const NFT_ETH_N2 = await ethers.getContractAt("NFTImplementationETH", NFT_ETH_N2_addr);
        const buy_1_price = await NFT_ETH_N2.getBuyPrice();
        const expect_buy_1_price = (0.1).toString();
        expect(buy_1_price).to.equal(ethers.parseEther(expect_buy_1_price));

        let owner_balance_before = await ethers.provider.getBalance(owner.address);
        let addr1_balance_before = await ethers.provider.getBalance(addr1.address);
        let txResponse = await NFT_ETH_N2.buy(1, { value: buy_1_price });
        let txReceipt = await txResponse.wait();
        let gasCost = txReceipt.gasUsed * txResponse.gasPrice;
        const fee = (0.1 * 0.01).toString();
        expect(owner_balance_before - gasCost - buy_1_price + ethers.parseEther(fee)).to.equal(await ethers.provider.getBalance(owner.address));

        const ProtocolFee = (0.1 * 0.005).toString();
        expect(await ethers.provider.getBalance(addr1.address) - addr1_balance_before).to.equal(ethers.parseEther(ProtocolFee));

        const buy_2_price = await NFT_ETH_N2.getBuyCost(2);
        const expect_buy_2_price = calculateY(1)+calculateY(2);
        expect(buy_2_price).to.equal(ethers.parseEther(expect_buy_2_price.toString()));

        owner_balance_before = await ethers.provider.getBalance(owner.address);
        await NFT_ETH_N2.connect(addr2).buy(2, { value: buy_2_price });
        expect(await ethers.provider.getBalance(owner.address) - owner_balance_before).to.equal(buy_2_price * 5n / 100n);

        let addr2_balance_before = await ethers.provider.getBalance(addr2.address);
        const sell_2_price = await NFT_ETH_N2.getSellReward(2);
        const expect_sell_2_price = expect_buy_2_price * 0.945 * 0.945;
        expect(sell_2_price).to.equal(ethers.parseEther(expect_sell_2_price.toString()));

        txResponse = await NFT_ETH_N2.connect(addr2).sell(2);
        txReceipt = await txResponse.wait();
        gasCost = txReceipt.gasUsed * txResponse.gasPrice;

        const divFee = (ethers.parseEther(expect_buy_2_price.toString())) * 945n/1000n * 4n/100n * 2n/3n;

        expect(addr2_balance_before - gasCost + sell_2_price + divFee).to.equal(await ethers.provider.getBalance(addr2.address));

      })

  
  })


});