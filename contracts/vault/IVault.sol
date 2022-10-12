// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

//import "../project/ITeamWalletOwner.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../project/PledgeEvent.sol";

interface IVault {
    //function setTargetProject(ITeamWalletOwner newProject) external;
    function transferPaymentTokenToTeamWallet(uint sum_, uint platformCut, address platformAddr_) external;
    function transferPaymentTokensToPledger( address pledgerAddr_, uint sum_) external returns(uint);

    function increaseBalance( uint numPaymentTokens_) external;

    function vaultBalance() external view returns(uint);

    function totalAllPledgerDeposits() external view returns(uint);

    function decreaseTotalDepositsOnPledgerGraceExit(PledgeEvent[] calldata pledgerEvents) external;

    function changeOwnership( address project_) external;
    function getOwner() external view returns (address);

    function initialize( address owner_) external;

    //Ownable
    // function owner() external view returns (address);
    // function renounceOwnership() external ;
    // function transferOwnership(address newOwner) external ;
}

