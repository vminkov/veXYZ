module.exports = async ({ run, ethers, getNamedAccounts, deployments, getChainId }) => {
  console.log("RPC URL: ", ethers.provider.connection.url);
  const chainId = parseInt(await getChainId());
  console.log("chainId: ", chainId);
  const { deployer } = await getNamedAccounts();
  console.log("deployer: ", deployer);
}

module.exports.tags = ["prod"];
