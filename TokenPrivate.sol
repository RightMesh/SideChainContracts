pragma solidity ^0.4.11;


contract TokenPrivate {
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* This generates a public event on the block chain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function TokenPrivate(
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) {
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }
    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }
}