# Project Title

Use case in data tradings

## Getting Started
Download [genesis.json](https://github.com/RightMesh/SmartContracts/blob/master/genesis.json) and [genesisprivate.json](https://github.com/RightMesh/SmartContracts/blob/master/genesisprivate.json) and save them in ```$HOME/etherum```.
Use the following commands to create 3 peers in public chain and 5 peers in private chain:
```
geth --datadir "$HOME/ethereum/publicchaindeployer" init $HOME/ethereum/genesis.json
geth --datadir "$HOME/ethereum/publicchainbuyer" init $HOME/ethereum/genesis.json
geth --datadir "$HOME/ethereum/publicchainseller" init $HOME/ethereum/genesis.json
geth --datadir "$HOME/ethereum/privatechaindeployer" init $HOME/ethereum/genesisprivate.json
geth --datadir "$HOME/ethereum/privatechainbuyer" init $HOME/ethereum/genesisprivate.json
geth --datadir "$HOME/ethereum/privatechainseller" init $HOME/ethereum/genesisprivate.json
geth --datadir "$HOME/ethereum/privatechainfwder1" init $HOME/ethereum/genesisprivate.json
geth --datadir "$HOME/ethereum/privatechainfwder2" init $HOME/ethereum/genesisprivate.json
``` 
The deployer peers in both private and public chains would be the peers owned by us. Via deployer peers, we can deploy smart contracts in block chains.
### Prerequisites
* Run these peers, and make sure peers in each chain can see each other in the same chain.
* Create an account for each of the following peers: public smart contract deployer, public buyer, public seller, private smart contract deployer, private fwder1, and privte fwder2. 
* Copy the wallet files of public buyer and seller to private buyer's and seller's key stores, respectively.
* Start the miner for each account and make sure each account has enought Ethers.
* Please first load all the smart contracts in browser-solidity. We have used ```import``` key words to include the external files that we need in each smart contract. 

NOTE: When deploy a smart contract in Mist wallet, please first manually assemble all external files into one smart contract file. Then, copy and paste the assembled file into the smart contract editor in Mist.
### How to Use Smart Contracts in the Repo (Remeber to mine after each bullet)
1. Deploy the RightMeshToken smart contract into public chain via the smart contract deployer peer in public chain. The parameters used in the deployment are as follows:
```
Initial supply = 100000000000 
Token name = RightMeshToken 
Decimal units = 3 
Token symbol = $ 
```
2. From public smart contract deployer, call ```Transfer``` function in the deployed smart contract with the following arguments:
```
To = address of the deployed RightMeshToken smart contract
Value = 50000000000
``` 
3. From public smart contract deployer, call ```Set Prices``` function in the deployed smart contract with the following arguments:
```
New sell price = 900000000000
New buy price  = 1000000000000
``` 
4. Before buying data, the buyer needs to buy some RightMeshToken from us in public chain can withdraw some RightMeshToken from public chain to private chain. Thus, first watch the deployed RightMeshToken smart contract in the buyer peer in public chain. Then, execute ```Buy``` function with ```Send ether=50``` from buyer's public account. We let the buyer have more than 50 Ethers in his public account. 
5. After mining, let the buyer in public chain watch the token by offering the address of the deployed RightMeshToken smart contract. The buyer should observe his RightMeshToken balance in public chain is 50,000.000. Now, from the buyer's public account call function ```Withdraw First Stage``` with arguments ```Withdraw amount=20000000```.
6. After mining, observe the buyer's token balance in public chain has been updated to 30,000.000. It is our responsibility to keep the even balances between user's public and private chains. We will have a routine running on Amazon Server to handle the reimbursement in private chain. For now, we need to do that manually. So, deploy the RightMeshTokenPrivate smart contract from the private smart contract deployer with the following arguments:
```
Initial supply = 0 
Token name = RightMeshTokenPrivate 
Decimal units = 3 
Token symbol = $ 
```
7. After the deployment of RightMeshTokenPrivate, from private smart contract deployer's account, call function ```Withdraw Second Stage``` with the following argument:
```
User account = private buyer's acount (same as public buyer's account since we copied the wallet file)
Withdraw amount = 20000000
```
8. After mining, let the private buyer watch the RightMeshTokenPrivate at the deployed address, we should observe 20,000.000 RightMeshToken has been reimbursed to the user's account in private chain. Now, we are about to deploy data trading smart contract in private chain. First, deploy DataPool smart contract from private smart contract deployer. It requires no arguments.
9. We then deploy the DataStore smart contract with the following arguments from private smart contract deployer:
```
rmc token = address of the deployed RightMeshTokenPrivate smart contract
my data pool = address of the deployed DataPool smart contract
percent for fwders = 20
percent for left = 5
```
10. After mining, also from the private smart contract deployer, call function ```Add App Contract``` with the arugument
```
app contract = address of the deployed DataStore smart contract
```
11. When the above transaction is mined, we should see from the deployed RightMeshTokenPrivate that the first element in its ```App contracts``` array has been assigned with the deployed DataStore smart contract. Now, let the private seller watch the deployed DataPool and call ```Share``` function in it with the following arguments:
```
total kb = 1000000
price per kb = 20
```
12. After mining, when we provide the address of private seller's account to the hash map ```pool``` in the deployed DataPool instance, we can see the data sharing information has been logged. Now, from the private buyer's account call the function in the DataStore with the following arguments (add the DataStore to the watch contracts if necessary):
```
seller = address of private seller's account
amount kb = 20000
```
13. After mining, observe buyer's private balance has been deducted to 19,500.000. This is because the price set by the seller is 20, i.e., 0.02 RightMeshToken/KB. The charge to reward forwarders is 20% and we hold 5% charge for the usage of RightMesh Library. So, 20,000.000-0.02x20000x(1+20%+5%)=19,500.000. 
Moreover, from the deployed DataStore, copy both accounts of private seller and buyer and paste them into ```Ongoing data tradings```, we can observe the ```Total reserved data amt in kb```, ```Total reserved token amt```, ```Price per kb```, ```Data consumed in kb```, and ```Is entity``` have been saved in the log. Meanwhile, from the deployed DataPool instance, pasting the address of the private seller's account in the hash map ```Pool``` will show us that 20000 KB has been used/allocated from seller's sharing pool.
Now, the Internet data packets sent from/to the buyer can be handled by the seller. When a forwarder notice a new XOR code between the a seller-buyer pair, the forwarder needs to send a report to the blockchain to log its forwarding contributions. From each of the forwarder peers in private chain, let them watch the deployed DataStore and call the function ```Report New Xors``` with the following sets of arguments:
```
seller = ["address of private seller"]
buyer = ["address of private buyer"]
new xor = ["0x0000000000000000000000000000000000000001"]
```
and
```
seller = ["address of private seller"]
buyer = ["address of private buyer"]
new xor = ["0x0000000000000000000000000000000000000002"]
```
, respectively.

14. From private seller's account call function ```Finish Data Trading From SP``` with the following arguments:
```
Sellers = ["address of private seller"]
Group buyer counter for seller = [1]
Buyers = ["address of private buyer"]
Group xor counter for buyer = [2]
Fwder xor results = ["0x0000000000000000000000000000000000000001","0x0000000000000000000000000000000000000002"]
data amts in kb = [1000,1000] 
```
After mining, we should observe the balance of seller in private chain has been further increased with (1000+1000)x20=20.000 RightMeshToken. 
Moreover, let forwarders watch the deployed RightMeshTokenPrivate token in private chain. We should observe the rewards for forwarders have been given to those forwarders. In particular, the first forwarder who reported XOR code ```0x0000000000000000000000000000000000000001``` should received 44.000 RightMeshToken. The second forwarder who reported XOR code ```0x0000000000000000000000000000000000000002``` should receive 24.000 RightMeshToken. It makes sence because their received rewards are proportional to the data amounts they forwarded.   
Last but not least, since the buyer just used 17000 KB data, we should observe the rest 3000 KB data is given back to the seller's data pool and the extra RightMeshToken (i.e., 3000x20x1.25=75.000) held by DataStore should have been reimbursed to the buyer account in private chain. Since 17000 KB has been used by the buyer, we can see from seller's private account that he has earned 17000KB x 0.020RightMeshToken/KB=340.000 RightMeshTokens.

15. The data trading between the buyer and seller has been done, the forwarder and seller can now deposit their RightMeshTokens in private chain to their accounts in public chain. It is because they can only get back real Ethers in public chain. For example, assume seller wants to save its earned RightMeshToken to the public chain. From the seller's private account in private chain, call function ```Deposit First Stage``` and specify the amount of RightMeshToken want to deposit. We can deposit all of the 340.000 RightMeshTokens. However, if you enter an amount more than 340000 in the blank, the block chain will not allow you to execute that. Assume we have enterred 340000, after mining we can observe the balance of sell's private account has been updated to 0.000. 

16. It is our responsibility to keep user's accounts in both public and private chains even. There would be routine running on Amazon Server to handle it. For now, we need to do that manually. The only difference between widthdraw and deposit operations is that we need to pay for the gas when we reimburse RightMeshTokens into the public main chain. A simple solution to let the user pay for the reimbursement is that we charge the gas in terms of RightMeshTokens according to the current exchange rate with real Ether. For example, if exchange rate from Ether to RightMeshToken is 1,000.000 RightMeshToken/Ether and the reimbursement transaction consumes 0.001 Ether, we reimburse 339.000 RightMeshTokens to the seller's public account. The 1.000 RightMeshToken is returned to us. Now, call from the public smart contract deployer's account in public chain can call funciton ```Deposit Second Stage``` with the following arguments:
```
User account = address of seller's public account
Deposit amount = 339000
Deducted amount = 1000
```
Mining the transaction in public chain should reimburse 399.000 RightMeshTokens to the seller's public account. Seller now can change it back to real Ether and get out money (e.g., USD) by selling it. 

17. Desides the basic operations with demos given above, please feel free to call function ```Buy More Data``` before the function ```Finish Data Trading``` is called. ```Buy More Data``` is used by data buyers periodically to buy more data from their current sellers.

18. Note that multiple three-tuples can be used to invoke function ```Report New Xor``` when a forwarder wants to log more than one (seller, buyer, xor) tuple into blockchain. For example, consider a forwarder is a crossing node between two routes connecting (Seller-1, Buyer-1) and (Seller-2, Buyer-2), also assume its XOR codes on these routes are Xor-1 and Xor-2, respectively. Then, when the forwarder reports its contribution to the block chain, it can use the following arguments for function ```Report New Xor```:
```
seller = ["address of Seller-1","address of Seller-2"]
buyer = ["address of Buyer-1","address of Buyer-2"]
new xor = ["Xor-1","Xor-2"]
```

