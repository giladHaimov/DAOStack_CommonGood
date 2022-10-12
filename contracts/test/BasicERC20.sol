// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


interface BasicERC20 {

    //function balanceOf(address) external pure returns (uint256) { return 0; }
    function balanceOf(address account) external view returns (uint256);

    //function approve(address,uint) public pure returns (bool) { return true; }
    function approve(address spender, uint256 amount) external returns (bool);

    //function allowance(address, address) public pure returns (uint) { return 0; }
    function allowance(address owner, address spender) external view returns (uint256);
}