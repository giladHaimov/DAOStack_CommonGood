// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../vault/IVault.sol";
import "../platform/IPlatform.sol";
import "../project/IProject.sol";
import "../project/PledgeEvent.sol";
import "../utils/InitializedOnce.sol";


contract CommonGoodVault is IVault, ERC165Storage, ReentrancyGuard, InitializedOnce {

    event PTokPlacedInVault( uint sum);

    event PTokTransferredToTeamWallet( uint sumToTransfer_, address indexed teamWallet_, uint platformCut_, address indexed platformAddr_);

    event PTokTransferredToPledger( uint sumToTransfer_, address indexed pledgerAddr_);

    event TeamFundsMovedToPledgers( uint origTeamPTokFunds, uint newPledgersPTokFunds);

    event MilestoneFundsAssignedToTeam( uint sumToAssign, uint teamPTokFunds, uint pledgersPTokFunds);

    error VaultOwnershipCannotBeTransferred( address _owner, address newOwner);

    error VaultOwnershipCannotBeRenounced();
    //----

    uint public pledgersPTokFunds;
    uint public teamPTokFunds;

    uint public totalPToksInvestedInProject; // sum of all PToks added into vault


    constructor() {
        _initialize();
    }


    function initialize(address owner_) external override onlyIfNotInitialized { //@PUBFUNC called by platform //@CLONE
        _markAsInitialized(owner_);
        _initialize();
    }

    function _initialize() private {
        _registerInterface( type(IVault).interfaceId);
        pledgersPTokFunds = 0;
        teamPTokFunds = 0;
        totalPToksInvestedInProject = 0;
    }


    function addNewPledgePToks( uint numPaymentTokens_) external override nonReentrant onlyOwner {  //@PUBFUNC
        // due to new pledge event; MUST be followed by PTok transfer from pledger to vault
        _verifyInitialized();
        _addToPledgersFunds( numPaymentTokens_);
        emit PTokPlacedInVault( numPaymentTokens_);
    }



    function onFailureMoveTeamFundsToPledgers() external override nonReentrant onlyOwner {  //@PUBFUNC
        _verifyInitialized();

        require( _getProject().projectHasFailed(), "project not failed");

        uint origTeamPTokFunds_ = teamPTokFunds;

        teamPTokFunds = 0;
        pledgersPTokFunds += origTeamPTokFunds_;

        emit TeamFundsMovedToPledgers( origTeamPTokFunds_, pledgersPTokFunds);
    }


    function transferPToksToPledger( address pledgerAddr_, uint numPaymentTokens_, bool gracePeriodExit_)
                                        external override nonReentrant onlyOwner returns(uint) {  //@PUBFUNC
        // invoked due to project failure or grace-period exit

        // @PROTECT: DoS, Re-entry
        _verifyInitialized();

        uint actuallyRefunded_ = _transferFromPledgersFundsTo( pledgerAddr_, numPaymentTokens_);

        if (gracePeriodExit_) {
            // subtract from total-investment funds transferred to pledger on grace-period exit
            totalPToksInvestedInProject -= actuallyRefunded_;
        }

        emit PTokTransferredToPledger( numPaymentTokens_, pledgerAddr_);

        return actuallyRefunded_;
    }


    function assignFundsFromPledgersToTeam( uint sumToAssign_) external nonReentrant onlyOwner {
        // called on milestone success
        _verifyInitialized();

        pledgersPTokFunds -= sumToAssign_;
        teamPTokFunds += sumToAssign_;

        emit MilestoneFundsAssignedToTeam( sumToAssign_, teamPTokFunds, pledgersPTokFunds);
    }


    function transferAllVaultFundsToTeam( uint platformCutPromils_, address platformAddr_)
                                            external override nonReentrant onlyOwner returns(uint,uint) { //@PUBFUNC
        // called on project success to pass *all* funds in vault (team+pledgers) to team wallet, while also transferring platform cut
        // @PROTECT: DoS, Re-entry
        _verifyInitialized();

        uint totalSumToTransfer_ = teamPTokFunds + pledgersPTokFunds;

        teamPTokFunds = 0;
        pledgersPTokFunds = 0;

        totalSumToTransfer_ = _correctAccordingTotalNumPToksOwnedByVault( totalSumToTransfer_);

        address teamWallet_ = getTeamWallet();

        uint platformCut_ = (totalSumToTransfer_ * platformCutPromils_) / 1000;

        uint teamCut_ = totalSumToTransfer_ - platformCut_;


        _erc20TransferTo( teamWallet_, teamCut_);

        _erc20TransferTo( platformAddr_, platformCut_);


        emit PTokTransferredToTeamWallet( teamCut_, teamWallet_, platformCut_, platformAddr_);

        return (teamCut_, platformCut_);
    }


    function _transferFromPledgersFundsTo( address receiverAddr_, uint numPToksToTransfer_) private returns(uint) {

        numPToksToTransfer_ = _correctAccordingTotalPledgersFunds( numPToksToTransfer_);

        numPToksToTransfer_ = _correctAccordingTotalNumPToksOwnedByVault( numPToksToTransfer_);


        pledgersPTokFunds -= numPToksToTransfer_;

        _erc20TransferTo( receiverAddr_, numPToksToTransfer_);

        return numPToksToTransfer_;
    }


    function _erc20TransferTo( address receiverAddr_, uint sumToTransfer_) private {
        address paymentTokenAddress_ = getPaymentTokenAddress();
        bool transferred_ = IERC20( paymentTokenAddress_).transfer( receiverAddr_, sumToTransfer_);
        require( transferred_, "Failed to transfer PTok funds");
    }


    function _correctAccordingTotalPledgersFunds( uint sum_) private view returns(uint) {
        if (sum_ > pledgersPTokFunds) {
            sum_ = pledgersPTokFunds;
        }
        return sum_;
    }


    function _correctAccordingTotalNumPToksOwnedByVault( uint sum_) private view returns(uint) {
        uint totalPToksOwnedByVault_ = _totalNumPToksOwnedByVault();
        if (sum_ > totalPToksOwnedByVault_) {
            sum_ = totalPToksOwnedByVault_;
        }
        return sum_;
    }

    function _totalNumPToksOwnedByVault() private view returns(uint) {
        address paymentTokenAddress_ = getPaymentTokenAddress();
        return IERC20( paymentTokenAddress_).balanceOf( address(this));
    }

    //----


    function getPaymentTokenAddress() private view returns(address) {
        return _getProject().getPaymentTokenAddress();
    }

    function getTeamWallet() private view returns(address) {
        return _getProject().getTeamWallet();
    }

    function _getProject() private view returns(IProject) {
        address project_ = getOwner();
        return IProject(project_);
    }


    function changeOwnership( address newOwner) public override( InitializedOnce, IVault) onlyOwnerOrNull {
        return InitializedOnce.changeOwnership( newOwner);
    }

    function vaultBalance() public view override returns(uint) {
        //@gilad: returned balance shouldonly contain the pledgers portion;
        // the team portion should be treated as if it was effectively already transmitted to the team wallet
        return pledgersPTokFunds;
    }


    function getTeamBalanceInVault() external override view returns(uint) {
        return teamPTokFunds;
    }

    function getTotalPToksInvestedInProject() public view override returns(uint) {
        return totalPToksInvestedInProject;
    }

    function getOwner() public override( InitializedOnce, IVault) view returns (address) {
        return InitializedOnce.getOwner();
    }



    //------ retain connected project ownership (behavior declaration)

    function renounceOwnership() public view override onlyOwner {
        revert VaultOwnershipCannotBeRenounced();
    }

    function _addToPledgersFunds( uint toAdd_) private {
        totalPToksInvestedInProject += toAdd_;
        pledgersPTokFunds += toAdd_;
    }

}
