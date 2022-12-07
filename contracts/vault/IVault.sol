// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/access/Ownable.sol";
import "../project/PledgeEvent.sol";

interface IVault {

    function transferAllVaultFundsToTeam( uint platformCutPromils_, address platformAddr_) external returns(uint,uint);

    function transferPToksToPledger( address pledgerAddr_, uint sum_, bool gracePeriodExit_) external returns(uint);

    function addNewPledgePToks( uint numPaymentTokens_) external;

    function vaultBalance() external view returns(uint); // ==pledger balance in vault

    function getTeamBalanceInVault() external view returns(uint);

    function getTotalPToksInvestedInProject() external view returns(uint);

    function changeOwnership( address project_) external;
    function getOwner() external view returns (address);

    function onFailureMoveTeamFundsToPledgers() external;

    function assignFundsFromPledgersToTeam( uint sum_) external;

    function initialize( address owner_) external;
}

