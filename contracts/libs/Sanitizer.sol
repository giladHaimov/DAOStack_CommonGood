// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../milestone/Milestone.sol";
import "../milestone/MilestoneApprover.sol";
import "../milestone/MilestoneResult.sol";


/*
    TODO: hhhh

tokens:   https://www.youtube.com/watch?v=gc7e90MHvl8

    find erc20 asset price via chainlink callback or API:
            https://blog.chain.link/fetch-current-crypto-price-data-solidity/
            https://www.quora.com/How-do-I-get-the-price-of-an-ERC20-token-from-a-solidity-smart-contract
            https://blog.logrocket.com/create-oracle-ethereum-smart-contract/
            https://noahliechti.hashnode.dev/an-effective-way-to-build-your-own-oracle-with-solidity

    use timelock?

    truffle network switcher

    deploy in testnet -- rinkbey

    a couple of basic tests
            deploy 2 ms + 3 bidders
            try get eth - fail
            try get tokens fail
            success
            try get eth - fail
            try get tokens fail
            success
            try get eth - success
            try get tokens success
---

    IProject IPlatform + supprit-itf
    beta mode
    clone contract for existing template address

    https://www.youtube.com/watch?v=LZ3XPhV7I1Q
            openz token types

    go over openzeppelin relevant utils

   refund nft receipt from any1 (not only orig ownner); avoid reuse (burn??)

   refund eth for leaving pledgr -- grace/failure

   allow prj erc20 frorpldgr on prj success

   inject vault and rpjtoken rather than deploy

   write some tests

   create nft

   when transfer platform token??

   deal with nft cashing

   deal with completed_indexes list after change -- maybe just remove it?

   problem with updating project --how keep info on completedList and pundedStartingIndex

   who holds the erc20 project-token funds of this token? should pre-invoke to make sure has funds?
-------

Guice - box bonding curvse :  A bonding curve describes the relationship between the price and supply of an asset

    what is market-makers?

    startProj, endProj, pledGer.enterTime  // project.projectStartTime, project.projectEndTime
    compensate with erc20 only if proj success
    maybe receipt == erc721?;

    reserved sum === by frequency calculation;

*/

library Sanitizer {

    error NoMilestoneApproverWasSet(uint index);

    error AmbiguousMilestoneApprover(uint index, address externalApprover, uint fundingTarget, uint numPledgers);


    function _sanitizeMilestones(Milestone[] memory milestones_) internal pure {
        // assuming low milestone count
        for (uint i = 0; i < milestones_.length; i++) {
            _validateApprover(i, milestones_[i].milestoneApprover);
            milestones_[i].result = MilestoneResult.UNRESOLVED;
        }
    }

    function _validateApprover(uint index, MilestoneApprover memory approver_) private pure {
        bool approverIsSet_ = (approver_.externalApprover != address(0) || approver_.fundingTarget > 0 || approver_.targetNumPledgers > 0);
        if ( !approverIsSet_) {
            revert NoMilestoneApproverWasSet(index);
        }
        bool extApproverUnique = (approver_.externalApprover == address(0) || (approver_.fundingTarget == 0 && approver_.targetNumPledgers == 0));
        bool fundingTargetUnique = (approver_.fundingTarget == 0  || (approver_.externalApprover == address(0) && approver_.targetNumPledgers == 0));
        bool numPledgersUnique = (approver_.targetNumPledgers == 0  || (approver_.externalApprover == address(0) && approver_.fundingTarget == 0));

        if ( !extApproverUnique || !fundingTargetUnique || !numPledgersUnique) {
            revert AmbiguousMilestoneApprover(index, approver_.externalApprover, approver_.fundingTarget, approver_.targetNumPledgers);
        }
    }

}

