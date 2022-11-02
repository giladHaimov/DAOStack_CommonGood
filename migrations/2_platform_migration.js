//truffle migrate --compile-none --reset
const Token   = artifacts.require("./contracts/token/CommonGoodProjectToken.sol");
const Vault   = artifacts.require("./contracts/vault/CommonGoodVault.sol");
const Project = artifacts.require("./contracts/project/Project.sol");
const Platform = artifacts.require("./contracts/platform/Platform.sol");


module.exports = async function(deployer) {

  const usePredeployedContracts_ = require('../globals/vars.js').usePredeployedContracts;

  console.log(`migration: usePredeployedContracts = ${usePredeployedContracts_}`);

  if (usePredeployedContracts_) {
      return; // no new deployments
  }
  
  await deployer.deploy(Project);
  const projectTemplate_inst = await Project.deployed();

  await deployer.deploy(Vault);
  const vaultTemplate_inst = await Vault.deployed();

  await deployer.deploy(Token, "some_name", "some_symbol");
  const token_inst = await Token.deployed();


  const platform_inst = await deployer.deploy( Platform, projectTemplate_inst.address, vaultTemplate_inst.address, token_inst.address);

};