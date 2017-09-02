pragma solidity ^0.4.6;

contract Owned {
    
    address public owner;

    event LogKilled();

    function Owned() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }
    
    function kill() 
    onlyOwner
    {
        LogKilled();
        selfdestruct(owner);
    }
    
    function transferOwnership (address newOwner)
    onlyOwner
    {
        require(newOwner != address(0));
        owner = newOwner;
    }
    
}



