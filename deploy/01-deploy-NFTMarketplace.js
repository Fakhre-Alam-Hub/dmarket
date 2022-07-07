const { network } = require("hardhat")
const { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
	const { deploy, log } = deployments
	const { deployer } = await getNamedAccounts()
	console.log("deployer : ", deployer)

	const nftmarket_args = []
	const nftMarketplace = await deploy("NFTMarketplace", {
		from: deployer,
		args: nftmarket_args,
		log: true,
		waitConfirmations: network.config.blockConfirmations || 1,
	})

	const nft_args = [nftMarketplace.address]
	const NFT = await deploy("NFT", {
		from: deployer,
		args: nft_args,
		log: true,
		waitConfirmations: network.config.blockConfirmations || 1,
	})

	// Verify the deployment
	if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
		log("Verifying NFTMarketplace...")
		await verify(nftMarketplace.address, nftmarket_args)
		log("Verifying NFT...")
		await verify(NFT.address, nft_args)
	}
	log("----------------------------------------------------")
}

module.exports.tags = ["all", "nftmarketplace"]
