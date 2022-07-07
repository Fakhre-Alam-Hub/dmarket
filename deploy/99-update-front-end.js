const { ethers, network } = require("hardhat")
const fs = require("fs")

const frontEndContractsFile = "pages/constants/networkMapping.json"
const frontEndAbiLocation = "pages/constants/abi/"

module.exports = async () => {
	if (process.env.UPDATE_FRONT_END) {
		console.log("Updating to front end...")
		await updateContractAddresses()
		await updateAbi()
		console.log("Front end updated!")
	}
}

// function to update abi in front end
async function updateAbi() {
	// update abi for NFTMarketplace contract
	const nftMarketplace = await ethers.getContract("NFTMarketplace")
	fs.writeFileSync(
		`${frontEndAbiLocation}NFTMarketplace.json`,
		nftMarketplace.interface.format(ethers.utils.FormatTypes.json)
	)

	// update abi for NFT contract
	const NFT = await ethers.getContract("NFT")
	fs.writeFileSync(
		`${frontEndAbiLocation}NFT.json`,
		NFT.interface.format(ethers.utils.FormatTypes.json)
	)
}

// function to update contract addresses in front end
async function updateContractAddresses() {
	const chainId = network.config.chainId.toString()

	const nftMarketplace = await ethers.getContract("NFTMarketplace")
	const nft = await ethers.getContract("NFT")
	const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"))
	if (chainId in contractAddresses) {
		if (!contractAddresses[chainId]["NFTMarketplace"].includes(nftMarketplace.address)) {
			contractAddresses[chainId]["NFTMarketplace"].push(nftMarketplace.address)
		}
		if (!contractAddresses[chainId]["NFT"].includes(nft.address)) {
			contractAddresses[chainId]["NFT"].push(nft.address)
		}
	} else {
		contractAddresses[chainId] = {
			NFTMarketplace: [nftMarketplace.address],
			NFT: [nft.address],
		}
	}
	fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses))
}
module.exports.tags = ["all", "frontend"]
