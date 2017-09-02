pragma solidity ^0.4.6;
import "./Owned.sol";

contract Remittance is Owned{
    /**
     * Remittance contract facilitates transfer of money from 
     * 'remitter' to 'beneficiary' through a 'money transmitter'.
     *  Beneficiary can claim his remittance from the money transmitter by 
     *  producing a 'secrect' given to him, by the remitter.
     *  Money transmitter in turn withdraws the money from RemittanceService
     *  by producing his secret along with beneficiary's secrect.
     *  Remitter can withdraw unclimed money afer a specified 'deadline'. 
     *  Deadline is set by owner of the service (not per remittance) 
     *  Owner of this RemittanceService get a 'commission'.
     *  RemittanceService has a default money transmitter, but
     *  remitter can also specify his own money transmitter during remittance.
     */
     
     uint public commisionInWei;
     uint public dedlineInBlocks;
     address defaultMoneyTransmitter;

     struct RemittanceStruct {
         uint amountToRemit;
         address remitter;
         address money_transmitter;
         uint blockNumber; // when the remittance was made
     }
     
     mapping(bytes32 => RemittanceStruct) remittancesMap;
     mapping(bytes32 => bool) public usedSecretsMap;// anyone can check if a secret has been used before

    event LogRemit(bytes32 hashedSecret, uint amount);
    event LogWithdraw(address who, uint howmuch);
    event LogReClaim(address who, uint howmuch); 

    function Remittance(uint _commisionInWei, // paid to owner of this Remittance contract 
                               uint  _dedlineInBlocks,  // deadline for withdrawal
                               address _money_trasmitter) { 
        commisionInWei = _commisionInWei;
        dedlineInBlocks = _dedlineInBlocks;
        defaultMoneyTransmitter = _money_trasmitter;
    }
    
    function remit(bytes32 hashedSecret)
    public
    payable
    {
        remit(hashedSecret, defaultMoneyTransmitter);
    }
    
    // remitter can specify his own money transmitter service to be used
    function remit(bytes32 hashedSecret, address _money_transmitter)
    public
    payable
    returns (bool success)
    {
        // check to prevent password re-use
        require(usedSecretsMap[hashedSecret] == false);
        require(msg.value > commisionInWei);

        RemittanceStruct memory remittance = RemittanceStruct(
                                            {
                                             amountToRemit: msg.value-commisionInWei,
                                             remitter:  msg.sender,
                                             money_transmitter: _money_transmitter,
                                             blockNumber: block.number
                                            });

        remittancesMap[hashedSecret] = remittance;
        usedSecretsMap[hashedSecret] = true;
        owner.transfer(commisionInWei);
        LogRemit(hashedSecret, remittance.amountToRemit);
        return true;
    }
    
    function withdraw(bytes32 hashedSecret1, bytes32 hashedSecret2)
    public
    returns (bool success)
    {
        bytes32 combinedHash = keccak256(hashedSecret1, hashedSecret2);
        RemittanceStruct memory remittance = remittancesMap[combinedHash];
        // make sure the money transmitter is the one claiming, not anyone with password
        require(remittance.money_transmitter == msg.sender);
        require(remittance.amountToRemit > 0);
        delete  remittancesMap[combinedHash]; // free up memory
        msg.sender.transfer(remittance.amountToRemit);
        LogWithdraw(msg.sender, remittance.amountToRemit);
        return true;
    }
    
    // method for remmiter to claim any balance after deadline
    function reClaim(bytes32 hashedSecret) 
    public
    returns (bool success)
    {
        RemittanceStruct memory remittance = remittancesMap[hashedSecret];
        require(remittance.remitter == msg.sender);
        require(block.number > remittance.blockNumber + dedlineInBlocks);
        require(remittance.amountToRemit > 0);
        msg.sender.transfer(remittance.amountToRemit);
        LogReClaim(msg.sender, remittance.amountToRemit);
        return true;
    }
    
    function changeDeadline(uint _dedlineInBlocks)
    public
    returns (bool success)
    {
        require(_dedlineInBlocks > 0);
        dedlineInBlocks = _dedlineInBlocks;
        return true;
    }
    
    function changeCommision(uint _commisionInWei)
    onlyOwner
    returns (bool success)
    {
        require(_commisionInWei >= 0);
        commisionInWei = _commisionInWei;
        return true;
    }
    
    function changeMoneyTransmitter(address _money_trasmitter)
    onlyOwner
    returns (bool success)
    {
        defaultMoneyTransmitter = _money_trasmitter;
        return true;
    }
    
}
