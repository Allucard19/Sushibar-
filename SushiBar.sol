// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// SushiBar is the coolest bar in town. You come in with some Sushi, and leave with more! The longer you stay, the more Sushi you get.
//
// This contract handles swapping to and from xSushi, SushiSwap's staking token.
contract SushiBar is ERC20("SushiBar", "xSUSHI"){
    using SafeMath for uint256;
    IERC20 public sushi;
    address public withdrawAddress;

    uint256 public ShopEnterTimestamp;
    uint256 public xshushiBalance;
    uint256 public totalSushi;
    
    // Define the Sushi token contract
    constructor(IERC20 _sushi) public {
        sushi = _sushi;
    }


    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Sushi and mints xSushi
    function enter(uint256 _amount) public {
        // Gets the amount of Sushi locked in the contract
        totalSushi = sushi.balanceOf(address(this));
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // If no xSushi exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSushi == 0) {
            _mint(msg.sender, _amount);
            xshushiBalance=_amount;
        } 
        // Calculate and mint the amount of xSushi the Sushi is worth. The ratio will change overtime, as xSushi is burned/minted and Sushi deposited + gained from fees / withdrawn.
        else {
            uint256 xshushiAmt = _amount.mul(totalShares).div(totalSushi);
            _mint(msg.sender, xshushiAmt);
            xshushiBalance=xshushiAmt;// xshushi in exchange for shushi
        }
        // Lock the Sushi in the contract
        sushi.transferFrom(msg.sender, address(this), _amount);
        ShopEnterTimestamp = block.timestamp;
    }

    function Unstake() public  returns (uint256) {
        
        uint256 Unstakevalue = 0;
        if ((block.timestamp-ShopEnterTimestamp)>2 && (block.timestamp-ShopEnterTimestamp)<4){
            Unstakevalue = (xshushiBalance.div(4));//25%
        }else if ((block.timestamp-ShopEnterTimestamp)>3 && (block.timestamp-ShopEnterTimestamp)<6){
            Unstakevalue = (xshushiBalance.div(2)); //50%
        }else if ((block.timestamp-ShopEnterTimestamp)>5 && (block.timestamp-ShopEnterTimestamp)<8){
            Unstakevalue = (xshushiBalance.mul(3)).div(4); //75%
        }else if ((block.timestamp-ShopEnterTimestamp)>7){
            Unstakevalue =xshushiBalance; //100%
        }
        return Unstakevalue;       
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unlocks the staked + gained Sushi and burns xSushi
    function leave(uint256 ValRetun) public  {
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Sushi the xSushi is worth
        uint256 InterstGained = (Unstake().mul(totalSushi)).div(totalShares); 
        uint256 TransferAmt = Unstake() + InterstGained; //invested sushi+interest
        // Taxation code
        uint256 TaxVal = 0;
        if ((block.timestamp-ShopEnterTimestamp)>2 && (block.timestamp-ShopEnterTimestamp)<4){
            TaxVal = (TransferAmt.mul(3)).div(4);//75%
            _burn(msg.sender, Unstake());
            sushi.transfer(msg.sender, TransferAmt-TaxVal);
        }else if ((block.timestamp-ShopEnterTimestamp)>3 && (block.timestamp-ShopEnterTimestamp)<6){
            TaxVal = TransferAmt.div(2);//50%
            _burn(msg.sender, Unstake());
            sushi.transfer(msg.sender, TransferAmt-TaxVal);
        }else if ((block.timestamp-ShopEnterTimestamp)>5 && (block.timestamp-ShopEnterTimestamp)<8){
            TaxVal = TransferAmt.div(4);//25%
            _burn(msg.sender, Unstake());
            sushi.transfer(msg.sender, TransferAmt-TaxVal);
        }else if ((block.timestamp-ShopEnterTimestamp)>7){
            TaxVal = TransferAmt; //0%
            _burn(msg.sender, Unstake());
            sushi.transfer(msg.sender, TransferAmt-TaxVal);
        }
        
        
    }
}
