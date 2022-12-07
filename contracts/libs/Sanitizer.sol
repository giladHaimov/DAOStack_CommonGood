// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../milestone/Milestone.sol";
import "../milestone/MilestoneApprover.sol";
import "../milestone/MilestoneResult.sol";


library Sanitizer {

    //@gilad: allow configuration?
    uint constant public MIN_MILESTONE_INTERVAL = 1 days;
    uint constant public MAX_MILESTONE_INTERVAL = 365 days;


    error IllegalMilestoneDueDate( uint index, uint32 dueDate, uint timestamp);

    error NoMilestoneApproverWasSet(uint index);

    error AmbiguousMilestoneApprover(uint index, address externalApprover, uint fundingPTokTarget, uint numPledgers);


    function _sanitizeMilestones( Milestone[] memory milestones_, uint now_, uint minNumMilestones_, uint maxNumMilestones_) internal pure {
        // assuming low milestone count
        require( minNumMilestones_ == 0 || milestones_.length >= minNumMilestones_, "not enough milestones");
        require( maxNumMilestones_ == 0 || milestones_.length <= maxNumMilestones_, "too many milestones");

        for (uint i = 0; i < milestones_.length; i++) {
            _validateDueDate(i, milestones_[i].dueDate, now_);
            _validateApprover(i, milestones_[i].milestoneApprover);
            milestones_[i].result = MilestoneResult.UNRESOLVED;
        }
    }

    function _validateDueDate( uint index, uint32 dueDate, uint now_) private pure {
        if ( (dueDate < now_ + MIN_MILESTONE_INTERVAL) || (dueDate > now_ + MAX_MILESTONE_INTERVAL) ) {
            revert IllegalMilestoneDueDate(index, dueDate, now_);
        }
    }

    function _validateApprover(uint index, MilestoneApprover memory approver_) private pure {
        bool approverIsSet_ = (approver_.externalApprover != address(0) || approver_.fundingPTokTarget > 0 || approver_.targetNumPledgers > 0);
        if ( !approverIsSet_) {
            revert NoMilestoneApproverWasSet(index);
        }
        bool extApproverUnique = (approver_.externalApprover == address(0) || (approver_.fundingPTokTarget == 0 && approver_.targetNumPledgers == 0));
        bool fundingTargetUnique = (approver_.fundingPTokTarget == 0  || (approver_.externalApprover == address(0) && approver_.targetNumPledgers == 0));
        bool numPledgersUnique = (approver_.targetNumPledgers == 0  || (approver_.externalApprover == address(0) && approver_.fundingPTokTarget == 0));

        if ( !extApproverUnique || !fundingTargetUnique || !numPledgersUnique) {
            revert AmbiguousMilestoneApprover(index, approver_.externalApprover, approver_.fundingPTokTarget, approver_.targetNumPledgers);
        }
    }

}

