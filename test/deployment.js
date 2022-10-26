//usage:
//  $ truffle test test/deployment.js  --network goerli

const Web3 = require('web3');
const BN = require('bn.js');
const { expectEvent, expectRevert }  = require('@openzeppelin/test-helpers');
const truffleAssert = require('truffle-assertions');

const Token   = artifacts.require("./contracts/token/CommonGoodProjectToken.sol");
const Project = artifacts.require("./contracts/project/Project.sol");
const Platform = artifacts.require("./contracts/platform/Platform.sol");


contract("Deployment", (accounts_) => {

   const COIN_UNIT = 'gwei'; //'ether'

   const ZERO_ADDR = "0x0000000000000000000000000000000000000000";

   const MILLION = 1000000;

   let paymentTokenInstance;
   let platformInst;

    const addr1 = accounts_[0];
    const addr2 = accounts_[1];
    const addr3 = accounts_[2];
    const addr4 = accounts_[3];


   beforeEach( async function () {
        paymentTokenInstance = await Token.deployed();
        platformInst = await Platform.deployed();

        await platformInst.approvePaymentToken( paymentTokenInstance.address, true);
        await markProjectTeamAsBetaTester( addr1);
   });


/*
    it("Goerli deploy", async () => {

          await verifyNetworkId( 5, "Goerli");

          await createNewContract();
    });
*/
    it("Mainnet deploy", async () => {

          await verifyNetworkId( 1, "Mainnet");

          await createNewContract();
    });


    async function createNewContract() {

          const MILESTONE_VALUE = _toWei('1');
          const MIN_PLEDGE_SUM = MILESTONE_VALUE;

          const CID_VALUE = '0x4554480000000000000000000000000000000000000000000000000000000000';

          const zeroPTok = 0;

          let params_ = { tokenName: "tok332",
                          tokenSymbol: "tk4",
                          projectVault: ZERO_ADDR,
                          paymentToken: paymentTokenInstance.address,
                          minPledgedSum: MIN_PLEDGE_SUM,
                          initialTokenSupply: 100*MILLION,
                          projectToken: ZERO_ADDR,
                          cid: CID_VALUE };

          let ts_ = await platformInst.getBlockTimestamp();

          let extApprover_2 = { externalApprover: addr2, targetNumPledgers: 0, fundingPTokTarget: 0 };
          let extApprover_3 = { externalApprover: addr3, targetNumPledgers: 0, fundingPTokTarget: 0 };
          let extApprover_4 = { externalApprover: addr4, targetNumPledgers: 0, fundingPTokTarget: 0 };

          milestones_ = [
                { milestoneApprover: extApprover_2, prereqInd: -1, pTokValue: zeroPTok,        result: 0, dueDate: addSecs(ts_, 200000) },
                { milestoneApprover: extApprover_3, prereqInd: -1, pTokValue: MILESTONE_VALUE, result: 0, dueDate: addSecs(ts_, 200000) },
                { milestoneApprover: extApprover_4, prereqInd: -1, pTokValue: MILESTONE_VALUE, result: 0, dueDate: addSecs(ts_, 200000) }
          ];

          const projectAddr_ = await invokeCreateProject( params_, milestones_, addr1);

          console.log(`===>  created project address: ${projectAddr_}`);

  }

   async function invokeCreateProject( params_, milestones_, addr_) {
          let receipt_ = await platformInst.createProject( params_, milestones_, { from: addr_ });

          let projectAddr_ = await extractProjectAddressFromEvent( receipt_);

          // cast projectAddress_ to project instance;
          thisProjInstance = await Project.at( projectAddr_);

          thisTeamWallet = await thisProjInstance.getTeamWallet();

          return projectAddr_;
    }

   async function extractProjectAddressFromEvent( receipt_) {
        let projectAddr_ = ZERO_ADDR;
        truffleAssert.eventEmitted( receipt_, 'ProjectWasDeployed', (ev) => {
            projectAddr_ = ev.projectAddress;
            return true;
        });
        console.log(`project address: ${projectAddr_}`);
        return projectAddr_;
   }

   function addSecs(baseSecs, addedSecs) {
        return (new BN(baseSecs).add(new BN(addedSecs))).toString();
   }

   function _toWei( val) {
        return Web3.utils.toWei( val, COIN_UNIT);
   }

   async function markProjectTeamAsBetaTester( teamAddr) {
        await platformInst.setBetaTester( teamAddr, true);
    }

    async function verifyNetworkId( targetId, targetName) {
        const netId = await web3.eth.net.getId();
        console.log(` netId: ${netId}`);

        switch (netId) {
            case targetId:
              console.log(`on ${targetName}`);
              break
            default:
              assert.fail(`not on ${targetName}`);
          }
     }

});

