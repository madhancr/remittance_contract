const Remittance = artifacts.require("./Remittance.sol");

contract("Remittance", accounts => {
	const gasPrice = 10;		
	const acc = web3.eth.accounts;
	const alice = acc[1]
	const bob 	= acc[2]
    const carol	= acc[3]	
    const comission = 10000;
    const deadlineBlocks = 100;

	var instance;

	var amount = web3.toBigNumber(web3.toWei(1, "ether"));


    const pw1 = web3.sha3('xyzzy')
    const pw2 = web3.sha3('foobar')
    const pwHash = web3.sha3(pw1.substr(2) + pw2.substr(2), { encoding: 'hex' })

	beforeEach(() => {
		return Remittance.new(comission, deadlineBlocks, carol).then(thisInstance => {
			instance = thisInstance;
		});
	});
	// basic test case 	
	it("should remit and withdraw", function() {
		var alice_oldbal = web3.eth.getBalance(alice);
		var carol_oldbal = web3.eth.getBalance(carol);

		return instance.remit(pwHash,  {from: alice, value: amount, gasPrice: gasPrice})
		.then(tx => {
			alice_oldbal = alice_oldbal
			.minus(tx.receipt.gasUsed * gasPrice)
			.minus(amount)

			return instance.usedSecretsMap(pwHash);
		})
		.then(isPwdUsed => {
			assert.equal(true, isPwdUsed, "Used passwrd check failed")
			assert.deepEqual(web3.eth.getBalance(instance.address), amount.minus(comission), "Contract did not receive funds.")
			return instance.withdraw(pw1, pw2, {from: carol, gasPrice: gasPrice})
		})
		.then(tx => {
			carol_bal = carol_oldbal
            .minus(tx.receipt.gasUsed * gasPrice)
            .minus(comission)
			.plus(amount)

			assert.deepEqual(alice_oldbal, web3.eth.getBalance(alice), "Remitter account balance is incorrect")
			assert.deepEqual(web3.eth.getBalance(carol), carol_bal, "Money Transmitter account balance in incorrect")
		})		
	});

});
