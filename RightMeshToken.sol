pragma solidity ^0.4.11;

import "./Owned.sol";
import "./Token.sol";

contract RightMeshToken is Owned, Token {
    uint256 public sellPrice;
    uint256 public buyPrice;
    address[] public appContracts;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the block chain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function RightMeshToken(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol
    ) Token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        if (frozenAccount[msg.sender]) throw;                // Check if frozen
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                        // Check if frozen
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        allowance[_from][msg.sender] -= _value;
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable {
        uint amount = msg.value / buyPrice;                // calculates the amount
        if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance
        balanceOf[this] -= amount;                         // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    }

    function sell(uint256 amount) {
        if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
        if (balanceOf[this] + amount < amount) throw;
        balanceOf[this] += amount;
        balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller's balance
        if (!msg.sender.send(amount * sellPrice)) {        // sends ether to the seller. It's important
            throw;                                         // to do this last to avoid recursion attacks
        } else {
            Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
        }
    }
    
    function withdrawFirstStage(uint256 withdrawAmount){
        if (balanceOf[msg.sender] < withdrawAmount ) throw;        // checks if the sender has enough to sell
        balanceOf[msg.sender] -= withdrawAmount;                   // subtracts the amount from seller's balance
    }
    
    //The function is called by us to give the reimbursement to a user's account in public chain 
    // when the user wants to save right mesh tokens from private chain to public chain.
    function depositSecondStage(address userAccount, uint256 depositAmount, uint256 deductedAmount) onlyOwner{
        //check the overflow of user's account in public chain
        if (balanceOf[userAccount] + depositAmount < depositAmount) throw;
        //check the overflow of our RMT account in public chain
        if (balanceOf[this] + deductedAmount < deductedAmount) throw;
        //add the depositAmount to the user's public account
        balanceOf[userAccount] += depositAmount;
        //add the depositAmount to our public account
        balanceOf[this]+=deductedAmount;
    }
}