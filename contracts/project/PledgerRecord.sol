// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


struct PledgerRecord {
    uint enterDate;
    uint completedMilestonesWhenEntered;
    uint successfulMilestoneStartIndex;
    bool noLongerActive;
    //PledgeEvent[] events;
}
