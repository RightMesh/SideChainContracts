pragma solidity ^0.4.11;

contract MultiOwned {

    address[] public owners;

    function MultiOwned() {
        owners.push(msg.sender);
    }

    modifier onlyMultiOwner {
        if (indexOfOwner(msg.sender)>=owners.length) throw;
        _;
    }

    function grantOwnership(address newOwner) onlyMultiOwner {
        if(indexOfOwner(newOwner)>=owners.length){
            owners.push(newOwner);
        }
    }

    function removeOwnership(address ownerToRemove) onlyMultiOwner {
        rmOwnershipByAddress(ownerToRemove);
    }

    function indexOfOwner(address owner) internal constant returns(uint) {
        uint i = 0;
        while (i<owners.length&&owners[i] != owner) {
            i++;
        }
        return i;
    }

    function rmOwnershipByAddress(address ownerToRemove) internal {
        uint i = indexOfOwner(ownerToRemove);
        rmOwnershipByIndex(i);
    }

    function rmOwnershipByIndex(uint i) internal {
        if(i>=owners.length) return;
        while (i<owners.length-1) {
            owners[i] = owners[i+1];
            i++;
        }
        delete owners[i];
        owners.length--;
    }
}