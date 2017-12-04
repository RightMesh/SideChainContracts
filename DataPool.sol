pragma solidity ^0.4.11;

import "./Owned.sol";

contract DataPool is Owned {
    struct Share{
        uint256 totalKB;      //number of kilo Bytes
        uint16 pricePerKB;    //price per kilo Bytes
        uint256 hasUsed;      //number of kilo Bytes has been used or allocated
        bool isEntity;
    }
    mapping (address =>Share) public pool;

    function share(uint256 _totalKB,uint16 _pricePerKB){
        if(pool[msg.sender].isEntity){
            pool[msg.sender].totalKB+=_totalKB;
            pool[msg.sender].pricePerKB=_pricePerKB;
        }
        else{
            pool[msg.sender]=Share(_totalKB,_pricePerKB,0,true);
        }
    }

    function allocate(address _seller, uint64 _amountInKB) returns (bool) {
        if(!pool[_seller].isEntity||(pool[_seller].totalKB-pool[_seller].hasUsed<_amountInKB)){
            return false;
        }
        else{
            pool[_seller].hasUsed+=_amountInKB;
            return true;
        }
    }

    function restore(address _seller, uint64 _amountInKB) {
        if(!pool[_seller].isEntity){
            throw;
        }
        else if(pool[_seller].hasUsed<_amountInKB){
            throw;
        }else{
            pool[_seller].hasUsed-=_amountInKB;
        }
    }

    function getPrice(address _seller) constant returns (uint16){
        if(pool[_seller].isEntity){
            return pool[_seller].pricePerKB;
        }
        else{
            throw;
        }
    }
}