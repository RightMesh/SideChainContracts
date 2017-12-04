pragma solidity ^0.4.11;

import "./TokenPrivate.sol";
import "./Owned.sol";

contract RightMeshTokenPrivate is Owned, TokenPrivate {
    address[] public appContracts;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function RightMeshTokenPrivate(
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol
    ) TokenPrivate (tokenName, decimalUnits, tokenSymbol) {}

    function addAppContract(address _appContract) onlyOwner {
        if(indexOfAppContract(_appContract)==appContracts.length){
            appContracts.push(_appContract);
        }
    }

    function removeAppContract(address _contract) onlyOwner {
        rmAppContractByAddr(_contract);
    }

    function indexOfAppContract(address _appContract) internal constant returns(uint) {
        uint i = 0;
        while (i<appContracts.length&&appContracts[i] != _appContract) {
            i++;
        }
        return i;
    }

    function rmAppContractByAddr(address _appContract) internal {
        uint i = indexOfAppContract(_appContract);
        rmAppContractByIndex(i);
    }

    function rmAppContractByIndex(uint i) internal {
        if(i>=appContracts.length) return;
        while (i<appContracts.length-1) {
            appContracts[i] = appContracts[i+1];
            i++;
        }
        delete appContracts[i];
        appContracts.length--;
    }

    function holdByAppContract (address _user, uint256 _amount) {
        if(indexOfAppContract(msg.sender)>=appContracts.length) throw;
        if (balanceOf[_user] < _amount) throw;
        if (balanceOf[msg.sender] + _amount< balanceOf[msg.sender]) throw;
        balanceOf[_user]-=_amount;
        balanceOf[msg.sender] += _amount;
        Transfer(_user, msg.sender, _amount);
    }

    function returnByAppContract(address _user, uint256 _amount) {
        if(indexOfAppContract(msg.sender)>=appContracts.length) throw;
        if(balanceOf[msg.sender]<_amount) throw;
        if(balanceOf[_user]+_amount<balanceOf[_user]) throw;
        balanceOf[msg.sender] -= _amount;
        balanceOf[_user] += _amount;
        Transfer(msg.sender, _user, _amount);
    }

    function contractSuperTransfer(address _to, uint256 _amount) {
        if(indexOfAppContract(msg.sender)>=appContracts.length) throw;
        if(balanceOf[msg.sender]<_amount) throw;
        if(balanceOf[_to]+_amount<balanceOf[_to]) throw;
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        Transfer(msg.sender, _to, _amount);
    }
    function contractSuperTransferInBatch(address[] receivers, uint256 [] amounts){
        if(receivers.length!=amounts.length) throw;
        if(indexOfAppContract(msg.sender)>=appContracts.length) throw;
        uint256 total=0;
        for(uint i=0;i<receivers.length;i++){
            total+=amounts[i];
        }
        if(balanceOf[msg.sender]<total) throw;
        for(i=0;i<receivers.length;i++){
            if(balanceOf[receivers[i]]+amounts[i]<balanceOf[receivers[i]]) throw;
            balanceOf[msg.sender] -= amounts[i];
            balanceOf[receivers[i]] += amounts[i];
            Transfer(msg.sender, receivers[i], amounts[i]);
        }
    }
    function depositFirstStage(uint256 depositAmount){
        if (balanceOf[msg.sender] < depositAmount ) throw;        // checks if the sender has enough to sell
        balanceOf[msg.sender] -= depositAmount;                   // subtracts the amount from seller's balance
    }
    
    function withdrawSecondStage(address userAccount, uint256 withdrawAmount) onlyOwner{
        if (balanceOf[userAccount] + withdrawAmount < withdrawAmount) throw;
        balanceOf[userAccount] += withdrawAmount;                   // subtracts the amount from seller's balance
    }
}