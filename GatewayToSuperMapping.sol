pragma solidity ^0.4.11;

import "./MultiOwned.sol";

contract SuperAndGatewayMapping is MultiOwned{

    mapping(address=>address) public gatewayPeerToSuperPeerMapping;
    function registerGatewayPeer(address gatewayPeer) onlyMultiOwner {
        if(msg.sender!=gatewayPeerToSuperPeerMapping[gatewayPeer]){
            gatewayPeerToSuperPeerMapping[gatewayPeer]=msg.sender;
        }
    }

    function unRegisterGatewayPeer(address gatewayPeer) onlyMultiOwner {
        if(msg.sender==gatewayPeerToSuperPeerMapping[gatewayPeer]){
            gatewayPeerToSuperPeerMapping[gatewayPeer]=address(0);
        }
    }
}