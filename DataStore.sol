pragma solidity ^0.4.11;

import "./Owned.sol";
import "./RightMeshTokenPrivate.sol";
import "./DataPool.sol";
import "./MultiOwned.sol";

contract DataStore is Owned, MultiOwned {
    RightMeshTokenPrivate public rightMeshTokenPrivate;
    DataPool public dataPool;
    uint16 public percentForFwders;
    uint16 public percentForLeft;
    struct XorInstanceLog{
        bool isEntity;
        uint64 dataAmtInKB;
        address[] fwdersWithTheSameXorArray;
        uint8 fwdersWithTheSameXorCounter;
        mapping (address=>bool) hasFwderInList;
    }
    struct DataTradingInstance{
        uint64 totalReservedDataAmtInKB;
        uint256 totalReservedTokenAmt;
        uint16 pricePerKB;
        uint64 dataConsumedInKB;
        bool isEntity;
        address [] xorArray;
        uint8 xorCounter;
        mapping (address=>XorInstanceLog) xorToInstanceLogMapping;
    }
    //change to private later
    //seller address => (buyer address => DataTradingInstance)
    mapping(address => mapping(address => DataTradingInstance)) public ongoingDataTradings;
    //buyer address => seller address
    mapping(address => address) public buyerToSellerMapping;

    function DataStore(address _rmcToken, address _myDataPool, uint16 _percentForFwders, uint16 _percentForLeft){
        rightMeshTokenPrivate=RightMeshTokenPrivate(_rmcToken);
        dataPool=DataPool(_myDataPool);
        percentForFwders=_percentForFwders;
        percentForLeft=_percentForLeft;
    }
    function buyData(address _seller, uint64 _amountInKB) {
        uint16 pricePerKB=dataPool.getPrice(_seller);
        uint256 requiredBalance=isAffordable(msg.sender,pricePerKB,_amountInKB);
        if(requiredBalance>0){
            DataTradingInstance storage dataTradingInstance=ongoingDataTradings[_seller][msg.sender];
            if(
            (!dataTradingInstance.isEntity)
            &&dataPool.allocate(_seller,_amountInKB)
            ){
                rightMeshTokenPrivate.holdByAppContract(msg.sender,requiredBalance);
                var newDataTradingInstance=DataTradingInstance(_amountInKB,requiredBalance,pricePerKB,0,true,new address[](0),0);
                ongoingDataTradings[_seller][msg.sender]=newDataTradingInstance;
                buyerToSellerMapping[msg.sender]=_seller;
            }else{
                throw;
            }
        }else{
            throw;
        }
    }

    function isAffordable(address _buyer, uint16 _sellerPricePerKB, uint64 _amountInKB) returns (uint256){
        uint256 requiredBalance=_sellerPricePerKB*_amountInKB*(100+percentForFwders+percentForLeft)/100;
        if(rightMeshTokenPrivate.balanceOf(_buyer)>requiredBalance){
            return requiredBalance;
        }
        else{
            return 0;
        }
    }

    function buyMoreData(address _seller, uint64 _amountInKB) {
        DataTradingInstance storage dataTradingInstance=ongoingDataTradings[_seller][msg.sender];
        //get the current data trading instance for the particular seller and
        //buyer pair
        if(dataTradingInstance.isEntity){
            uint256 requiredBalance=isAffordable(msg.sender,dataTradingInstance.pricePerKB,_amountInKB);
            if(
            (requiredBalance>0)
            &&(dataPool.allocate(_seller,_amountInKB))
            &&(dataTradingInstance.totalReservedDataAmtInKB+_amountInKB>=dataTradingInstance.totalReservedDataAmtInKB)
            &&(dataTradingInstance.totalReservedTokenAmt+requiredBalance>=dataTradingInstance.totalReservedTokenAmt)
            ){
                rightMeshTokenPrivate.holdByAppContract(msg.sender,requiredBalance);
                dataTradingInstance.totalReservedDataAmtInKB+=_amountInKB;
                dataTradingInstance.totalReservedTokenAmt+=requiredBalance;
            }
            else{
                throw;
            }
        }
        else{
            throw;
        }
    }


    //Will be called periodically by the buyer's device
    function periodicalConfirmationFromBuyer(address _seller, address[] _fwderXorResults, uint64[] _dataAmtsInKB) {
        if(_fwderXorResults.length!=_dataAmtsInKB.length){
            throw;
        }
        uint64 dataAmtConfirmedInKB=0;
        DataTradingInstance storage dataTradingInstance=ongoingDataTradings[_seller][msg.sender];
        if(dataTradingInstance.isEntity){
            for(uint i=0;i<_fwderXorResults.length;i++){
                if(dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[i]].isEntity){
                    dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[i]].dataAmtInKB+=_dataAmtsInKB[i];
                    
                }else{
                    var newXorInstanceLog=XorInstanceLog(true,_dataAmtsInKB[i],new address[](0),0);
                    dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[i]]=newXorInstanceLog;
                    dataTradingInstance.xorArray.push(_fwderXorResults[i]);
                    dataTradingInstance.xorCounter++;
                }
                dataAmtConfirmedInKB+=_dataAmtsInKB[i];
            }
        }else{
            throw;
        }
        if((dataTradingInstance.dataConsumedInKB+dataAmtConfirmedInKB)>dataTradingInstance.totalReservedDataAmtInKB){
            rightMeshTokenPrivate.contractSuperTransfer(_seller,(dataTradingInstance.totalReservedDataAmtInKB-dataTradingInstance.dataConsumedInKB)*dataTradingInstance.pricePerKB);
            dataTradingInstance.dataConsumedInKB=dataTradingInstance.totalReservedDataAmtInKB;
        }else{
            dataTradingInstance.dataConsumedInKB+=dataAmtConfirmedInKB;
            rightMeshTokenPrivate.contractSuperTransfer(_seller,dataAmtConfirmedInKB*dataTradingInstance.pricePerKB);
        }
    }

    function periodicalConfirmationFromSeller(address [] _buyerArray, uint8 [] _counterArray, address[] _fwderXorResults, uint64[] _dataAmtsInKB){
        if(_fwderXorResults.length!=_dataAmtsInKB.length){
            throw;
        }
        uint8 j;
        uint64 dataAmtConfirmedForEachBuyerInKB;
        uint16 totalRecordsWithProcessedBuyers=0;
        for(uint i=0;i<_buyerArray.length;i++){
            DataTradingInstance storage dataTradingInstance=ongoingDataTradings[msg.sender][_buyerArray[i]];
            if(dataTradingInstance.isEntity){
                j=0;
                dataAmtConfirmedForEachBuyerInKB=0;
                for(;j<_counterArray[i];j++){
                    uint innerIndex=totalRecordsWithProcessedBuyers+j;
                    if(dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[innerIndex]].isEntity){
                        dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[innerIndex]].dataAmtInKB+=_dataAmtsInKB[innerIndex];
                        
                    }else{
                        var newXorInstanceLog=XorInstanceLog(true,_dataAmtsInKB[innerIndex],new address[](0),0);
                        dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[innerIndex]]=newXorInstanceLog;
                        dataTradingInstance.xorArray.push(_fwderXorResults[innerIndex]);
                        dataTradingInstance.xorCounter++;
                    }
                    dataAmtConfirmedForEachBuyerInKB+=_dataAmtsInKB[innerIndex];
                }
                totalRecordsWithProcessedBuyers+=j;
            }else{
                throw;
            }
            if((dataTradingInstance.dataConsumedInKB+dataAmtConfirmedForEachBuyerInKB)>dataTradingInstance.totalReservedDataAmtInKB){
                rightMeshTokenPrivate.contractSuperTransfer(msg.sender,(dataTradingInstance.totalReservedDataAmtInKB-dataTradingInstance.dataConsumedInKB)*dataTradingInstance.pricePerKB);
                dataTradingInstance.dataConsumedInKB=dataTradingInstance.totalReservedDataAmtInKB;
                
            }else{
                dataTradingInstance.dataConsumedInKB+=dataAmtConfirmedForEachBuyerInKB;
                rightMeshTokenPrivate.contractSuperTransfer(msg.sender,dataAmtConfirmedForEachBuyerInKB*dataTradingInstance.pricePerKB);
            }
            dataAmtConfirmedForEachBuyerInKB=0;
        }
    }
 
    function reportNewXors(address [] _sellers, address [] _buyers, address [] _newXors)  {
        if((_sellers.length!=_buyers.length)||(_buyers.length!=_newXors.length)) throw;
        for(uint i=0;i<_newXors.length;i++){
            DataTradingInstance storage dataTradingInstance=ongoingDataTradings[_sellers[i]][_buyers[i]];
            if(dataTradingInstance.isEntity){
                if(dataTradingInstance.xorToInstanceLogMapping[_newXors[i]].isEntity){
                    if(!dataTradingInstance.xorToInstanceLogMapping[_newXors[i]].hasFwderInList[msg.sender]){
                        dataTradingInstance.xorToInstanceLogMapping[_newXors[i]].fwdersWithTheSameXorArray.push(msg.sender);
                        dataTradingInstance.xorToInstanceLogMapping[_newXors[i]].fwdersWithTheSameXorCounter++;
                        dataTradingInstance.xorToInstanceLogMapping[_newXors[i]].hasFwderInList[msg.sender]=true;
                    }else{
                        //A forwarder is expected to just report the XOR code once for each seller-buyer pair.
                        throw;
                    }
                }else{
                    var newXorInstanceLog=XorInstanceLog(true,0,new address[](0),0);
                    dataTradingInstance.xorToInstanceLogMapping[_newXors[i]]=newXorInstanceLog;
                    dataTradingInstance.xorArray.push(_newXors[i]);
                    dataTradingInstance.xorCounter++;
                    dataTradingInstance.xorToInstanceLogMapping[_newXors[i]].fwdersWithTheSameXorArray.push(msg.sender);
                    dataTradingInstance.xorToInstanceLogMapping[_newXors[i]].fwdersWithTheSameXorCounter++;
                    dataTradingInstance.xorToInstanceLogMapping[_newXors[i]].hasFwderInList[msg.sender]=true;
                }
            }else{
                throw;
            }
        }
    }

    //Will be triggered when a seller receives a finish-buy signal from the buyer
    //Will be called by the seller instead of the buyer
    function finishDataTradingFromSeller(address _buyer, address[] _fwderXorResults, uint64[] _dataAmtsInKB) {
        if(_fwderXorResults.length!=_dataAmtsInKB.length){
            throw;
        }
        uint64 dataAmtConfirmedInKB=0;
        DataTradingInstance storage dataTradingInstance=ongoingDataTradings[msg.sender][_buyer];
        if(dataTradingInstance.isEntity){
            for(uint i=0;i<_fwderXorResults.length;i++){
                if(dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[i]].isEntity){
                    dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[i]].dataAmtInKB+=_dataAmtsInKB[i];
                }else{
                    //The amount of data here will not give any rewards to any forwarders. This is because we are going to provide rewards to forwarders, buy however, this XOR has not ever been seen claimed by any forwards before.
                    var newXorInstanceLog=XorInstanceLog(true,_dataAmtsInKB[i],new address[](0),0);
                    dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[i]]=newXorInstanceLog;
                    dataTradingInstance.xorArray.push(_fwderXorResults[i]);
                    dataTradingInstance.xorCounter++;
                }
                dataAmtConfirmedInKB+=_dataAmtsInKB[i];
            }
        }else{
            throw;
        }
        uint256 weightedSumPaymentForForwarders=0;
        uint numberofPayee=2;
        for(i=0;i<dataTradingInstance.xorCounter;i++){
            weightedSumPaymentForForwarders+=dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].dataAmtInKB*dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].fwdersWithTheSameXorCounter;
            numberofPayee+=dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].fwdersWithTheSameXorCounter;
        }
        if((dataTradingInstance.dataConsumedInKB+dataAmtConfirmedInKB)>dataTradingInstance.totalReservedDataAmtInKB){
            dataAmtConfirmedInKB=dataTradingInstance.totalReservedDataAmtInKB-dataTradingInstance.dataConsumedInKB;
            dataTradingInstance.dataConsumedInKB=dataTradingInstance.totalReservedDataAmtInKB;
        }else if((dataTradingInstance.dataConsumedInKB+=dataAmtConfirmedInKB)<dataTradingInstance.totalReservedDataAmtInKB){
            dataPool.restore(msg.sender,dataTradingInstance.totalReservedDataAmtInKB-dataTradingInstance.dataConsumedInKB);
            numberofPayee++;
        }else{
            //do nothing
        }
    
        address [] memory forwarders=new address[](numberofPayee);
        uint256 [] memory rewards=new uint256[](numberofPayee);
        forwarders[0]=msg.sender;
        rewards[0]=dataAmtConfirmedInKB*dataTradingInstance.pricePerKB;
        forwarders[1]=rightMeshTokenPrivate.owner();
        rewards[1]=dataTradingInstance.dataConsumedInKB*dataTradingInstance.pricePerKB*percentForLeft/100;
        uint counter=2;
        for(i=0;i<dataTradingInstance.xorCounter;i++){
            for(uint j=0;j<dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].fwdersWithTheSameXorCounter;j++){
                forwarders[counter]=dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].fwdersWithTheSameXorArray[j];
                dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].hasFwderInList[dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].fwdersWithTheSameXorArray[j]]=false;
                rewards[counter]=dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].dataAmtInKB*dataTradingInstance.dataConsumedInKB*dataTradingInstance.pricePerKB*percentForFwders/100/weightedSumPaymentForForwarders;
                counter++;
            }
            dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].isEntity=false;
        }
        dataTradingInstance.isEntity=false;
        buyerToSellerMapping[_buyer]=address(0);
        if(counter==numberofPayee-1){
            forwarders[counter]=_buyer;
            rewards[counter]=(dataTradingInstance.totalReservedDataAmtInKB-dataTradingInstance.dataConsumedInKB)*dataTradingInstance.pricePerKB*(100+percentForFwders+percentForLeft)/100;
        }
        rightMeshTokenPrivate.contractSuperTransferInBatch(forwarders, rewards);
    }

    function finishDataTradingFromSP(address [] _sellers, uint8 [] _groupBuyerCounterForSeller, address [] _buyers, uint8 [] _groupXorCounterForBuyer, address[] _fwderXorResults, uint64[] _dataAmtsInKB) onlyMultiOwner {
        if(_groupBuyerCounterForSeller.length!=_sellers.length) throw;
        if(_groupXorCounterForBuyer.length!=_buyers.length) throw;
        if(_fwderXorResults.length!=_dataAmtsInKB.length) throw;
        uint i;
        uint temp=0;
        for(i=0;i<_groupXorCounterForBuyer.length;i++){
            temp+=_groupXorCounterForBuyer[i];
        }
        if(_fwderXorResults.length!=temp) throw;
        uint j;
        uint counter1=0;
        uint k;
        uint counter2=0;
        for(i=0;i<_sellers.length;i++){
            for(j=0;j<_groupBuyerCounterForSeller[i];j++){
                address [] memory _fwderXorResultsSubArray= new address[](_groupXorCounterForBuyer[counter1]);
                uint64 [] memory _dataAmtsInKBSubArray= new uint64[](_groupXorCounterForBuyer[counter1]);
                for(k=0;k<_groupXorCounterForBuyer[counter1];k++){
                    _fwderXorResultsSubArray[k]=_fwderXorResults[counter2];
                    _dataAmtsInKBSubArray[k]=_dataAmtsInKB[counter2];
                    counter2++;
                }
                finishDataTradingFromSPHelper(_sellers[i],_buyers[counter1],_fwderXorResultsSubArray,_dataAmtsInKBSubArray);
                counter1++;
            }
        }
    }

    function finishDataTradingFromSPHelper(address _seller, address _buyer, address[] _fwderXorResults, uint64[] _dataAmtsInKB) internal {
        uint64 dataAmtConfirmedInKB=0;
        DataTradingInstance storage dataTradingInstance=ongoingDataTradings[_seller][_buyer];
        if(dataTradingInstance.isEntity){
            for(uint i=0;i<_fwderXorResults.length;i++){
                if(dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[i]].isEntity){
                    dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[i]].dataAmtInKB+=_dataAmtsInKB[i];
                }else{
                    //The amount of data here will not give any rewards to any forwarders. This is because we are going to provide rewards to forwarders, buy however, this XOR has not ever been seen claimed by any forwards before.
                    var newXorInstanceLog=XorInstanceLog(true,_dataAmtsInKB[i],new address[](0),0);
                    dataTradingInstance.xorToInstanceLogMapping[_fwderXorResults[i]]=newXorInstanceLog;
                    dataTradingInstance.xorArray.push(_fwderXorResults[i]);
                    dataTradingInstance.xorCounter++;
                }
                dataAmtConfirmedInKB+=_dataAmtsInKB[i];
            }
        }else{
            throw;
        }
        uint256 weightedSumPaymentForForwarders=0;
        uint numberofPayee=2;
        for(i=0;i<dataTradingInstance.xorCounter;i++){
            weightedSumPaymentForForwarders+=dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].dataAmtInKB*dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].fwdersWithTheSameXorArray.length;
            numberofPayee+=dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].fwdersWithTheSameXorCounter;
        }
        if((dataTradingInstance.dataConsumedInKB+dataAmtConfirmedInKB)>dataTradingInstance.totalReservedDataAmtInKB){
            dataAmtConfirmedInKB=dataTradingInstance.totalReservedDataAmtInKB-dataTradingInstance.dataConsumedInKB;
            dataTradingInstance.dataConsumedInKB=dataTradingInstance.totalReservedDataAmtInKB;
        }else if((dataTradingInstance.dataConsumedInKB+=dataAmtConfirmedInKB)<dataTradingInstance.totalReservedDataAmtInKB){
            dataPool.restore(_seller,dataTradingInstance.totalReservedDataAmtInKB-dataTradingInstance.dataConsumedInKB);
            numberofPayee++;
        }else{
            //do nothing
        }

        address [] memory forwarders=new address[](numberofPayee);
        uint256 [] memory rewards=new uint256[](numberofPayee);
        forwarders[0]=_seller;
        rewards[0]=dataAmtConfirmedInKB*dataTradingInstance.pricePerKB;
        forwarders[1]=rightMeshTokenPrivate.owner();
        rewards[1]=dataTradingInstance.dataConsumedInKB*dataTradingInstance.pricePerKB*percentForLeft/100;
        uint counter=2;
        for(i=0;i<dataTradingInstance.xorCounter;i++){
            for(uint j=0;j<dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].fwdersWithTheSameXorCounter;j++){
                forwarders[counter]=dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].fwdersWithTheSameXorArray[j];
                dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].hasFwderInList[dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].fwdersWithTheSameXorArray[j]]=false;
                rewards[counter]=dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].dataAmtInKB*dataTradingInstance.dataConsumedInKB*dataTradingInstance.pricePerKB*percentForFwders/100/weightedSumPaymentForForwarders;
                counter++;
            }
            dataTradingInstance.xorToInstanceLogMapping[dataTradingInstance.xorArray[i]].isEntity=false;
        }
        dataTradingInstance.isEntity=false;
        buyerToSellerMapping[_buyer]=address(0);
        if(counter==numberofPayee-1){
            forwarders[counter]=_buyer;
            rewards[counter]=(dataTradingInstance.totalReservedDataAmtInKB-dataTradingInstance.dataConsumedInKB)*dataTradingInstance.pricePerKB*(100+percentForFwders+percentForLeft)/100;
        }
        rightMeshTokenPrivate.contractSuperTransferInBatch(forwarders, rewards);
    }

    function setPercentages(uint16 _percentForFwders, uint16 _percentForLeft) onlyOwner {
        percentForFwders=_percentForFwders;
        percentForLeft=_percentForLeft;
    }
}