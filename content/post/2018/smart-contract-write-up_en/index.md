+++
author = "Satoshi Tajima"
categories = [ "en", "" ]
date = "2018-11-25T12:30:00+09:00"
description = ""
featured = ""
featuredalt = ""
featuredpath = ""
linktitle = ""
title = "CODE BLUE 2018 Smart Contract Hacking Challenge WriteUp (en)"

+++

I participated in CODE BLUE 2018 held from Oct 29, 2018, to Nov 02, 2018,   
and challenged the [Smart Contract Hacking Challenge](https://codeblue.jp/2018/en/contests/detail_03/) presented by [PolySwarm](https://polyswarm.io/).  
As a result, I solved it in 1st place, so I publish its WriteUp.

# Background

When I started to solve it, I ...

* Am interested in Crypto Currency and have traded that on some exchanges.
* Study Smart Contract as a hobby and understand the overview.
* Never written code for Smart Contract by myself or used it practically. (If anything, I've only done [CryptoZombies](https://cryptozombies.io/)). 

This article was written for a person at around this level.

From this level, gradually acquire the necessary tools and knowledge for running and debugging Smart contracts,
It is a story until it can finally solve the problem.

# Challenge

Going to PolySwarm booth in CODE BLUE, I got a piece of paper.
These are written on the paper.

* [An Ethereum Address of a Contract.](https://etherscan.io/address/0x64ba926175bc69ba757ef53a6d5ef616889c9999) (Etherscan URL)
* [An Ethereum EOA Address and private key

This Contract is a target for hacking.

# Solution

## Checking the Contract.

First of all, for checking the contract, view [Code Tab](https://etherscan.io/address/0x64ba926175bc69ba757ef53a6d5ef616889c9999#code) of Etherscan.

![image](/post/2018/smart-contract-write-up_en/64ba92.png)

I was wondering why a human-readable code is there.  
In the Ethereum blockchain, contracts should be written as bytecode,  
I thought it was strange that source code could be shown in this way.

After googling it, I knew Etherscan has a feature that named [Verify Contract Code](https://etherscan.io/verifyContract2).  
So someone who has the source code of a Contract can upload it,   
and be shown it if the compiled bytecode was identical to the one on the blockchain.

Now let's look at the code shown here.  
It's only 173 lines of code, it's not so hard to read.  
the Contract is ...

* Number guessing game named CashMoney.
* Need to send more than 0.001 ETH to the Contract for guessing a number.
* If the guess was correct, bonus ETH is refunded on a first-come-first-served basis in addition to the remitted amount.
* If the guess was incorrect, the Contract confiscates ETH.

and, in more details...

* The range of a guess is from 0 to 10.
* The only address that the contract creator previously designated as a player can challenge.
* You can set player number and name as player information.
* For preventing an address from getting bonus multiple times, a log is recorded to the other Contract that named WinnerLog.


## First try.

Next, I confirmed how the correct number is decided.

Then, the correct number is defined as below.
```
uint256 private current;
```

and set in this function.

```
function every_day_im_shufflin() internal {
    // EVERY DAY IM SHUFFLIN
    current = uint8(keccak256(abi.encodePacked(blockhash(block.number-2)))) % 11;
}
```

This every_day_im_shufflin () seems to be called when creating a contract and when someone hits a number.

The correct number is from 0 to 10, and it is shuffled only when someone hits,   
so I thought I could use bruteforce and try that.


At this time, I've written code like this and execute the Contract by using web3.js of Node.js.  
https://gist.github.com/s-tajima/970901318960c038291ff90f4404fe35

From here ...  
https://etherscan.io/tx/0xc9e32cf91c122a62c001e6a34b05e970e4c27eb0e807301b20953bc03601f0b8

to here is this try.  
https://etherscan.io/tx/0xc7315ef6469d22c7c55d20c86bc80a59b8145d39ba74f24df96fc93782521660

As a result, of course, it is not a problem that can be solved so easily,  
Transactions are reverted with all numbers from 0 to 10.

## Debugging with Remix.

To think about the next try, I'd now like to know how contracts are executed.  
I knew there was a Solidity IDE called [Remix](https://remix.ethereum.org/), so I tried using it for testing.

![image](/post/2018/smart-contract-write-up_en/remix_01.png)

Paste the source code you got from Etherscan and specify the address of the contract,  
and you will be able to call contracts from Remix.

Also, you can use the Debugger function to check the execution status of the called contract.  
With this debugging function, you can also refer to variables defined as private on Solidity.

(The private modifier is merely the definition of the scope, not the modifier to make it invisible to anyone, so be careful when writing the contract code yourself.)

By using Debugger and confirming the process which compares the correct answer number with the expected number,
I noticed that the current correct answer number  is somehow `42`.

![image](/post/2018/smart-contract-write-up_en/remix_02.png)

It is unlikely that this will be `42` in the current setting method described above (the remainder of dividing a certain value by 11).  
Also, some code that caused an error if the guessed number is larger than `10`, so something is strange.

As I track down the process, I found that the current correct number (which was 4 in this case) was rewritten at the timing of the following code.

```
Guess storage guess;
guess.playerNo = players[msg.sender].playerNo;
```

As a result of investigating, it turned out that it was a problem that guess was not initialized correctly.  
As Solidity's specification, manipulating the value for this incorrectly initialized guess.playerNo is an operation for slot 0.  
**In short, current is rewritten to the value of players [msg.sender].playerNo.**

At this time, since the value of playerNo was set to 42 (written on the paper passed on), that value was set.

OK then, set the value of players[msg.sender].playerNo to 10 or less.  
https://etherscan.io/tx/0x1b9a902a3faf65aaa8033435d3118ae844887a1861e4e8095530b3eaf1ced1eb#decodetab

And call the contract with it as the guessed number.  
https://etherscan.io/tx/0xd27020cbbab206982d6a66f67ea3c5c1c983806f2199ae330ae8785bdfb124c3

However, unfortunately, I still could not earn ETH.


## Decompiling WinnerLog

I rechecked the execution status with Remix, and I confirmed that the comparison part of the correct number and the guessed number had passed.  
And I found that it finished at the line that calling external WinnerLog contract.

```
winnerLog.logWinner(msg.sender, players[msg.sender].playerNo, players[msg.sender].name);
```

The contract currently being executed (0x64ba92 ...) also contains the source code of the WinnerLog contract, according to which the logWinner is defined as follows.

```
function logWinner(address addr, uint256 playerNo, bytes name) public onlyPlayer { 
        winners[addr] = true;
        winner_name_list.push(string(name));
        winner_addr_list.push(addr);
        emit NewWinner(msg.sender, string(name), playerNo);
}
```

At first glance, there seems to be no factor causing an error.  
But here is the next trap.

winnerLog is created in the constructor of the CashMoney contract as follows.

```
winnerLog = WinnerLog(winnerLog_);
```

At this time, the value of winnerLog_ is the address of another contract (0x2e4d2a ...).


**In other words, `logWinner` is not necessarily executed as per the above source code.
On the contrary, there is a possibility that the contract of 0x2e4d2a ... performs completely different processing.**

Let's check the contract of 0x2e4d2a ...  
https://etherscan.io/address/0x2e4d2a597a2fcbdf6cc55eb5c973e76aa19ac410#code

![image](/post/2018/smart-contract-write-up_en/2e4d2a.png)

Unfortunately, at this side, there is no source code I can see.  
That's right. We need to decipher this bytecode or assembly.  
Since this kind of analysis has not been experienced so far, it seems to be quite seeming, so I searched for a decompiler.

Then, I found Online Solidity Decompiler, so I tried using it.  
The result of decompiling is here.  
https://ethervm.io/decompile?address=0x2E4d2a597A2fcBdF6CC55eb5c973E76Aa19Ac410&network=

![image](/post/2018/smart-contract-write-up_en/decompilation.png)

It became a little better. However, it is still difficult to read.  
Also, since this code is not valid as Solidity, I can't deploy this and check its operation.


## Debugging assembly

I had no choice but to continue debugging as it is assembly.  
I referred to the ethervm.io for EVM's opcode and debugged using the Debugger function of Remix.

Continued various trial and error, and did such a thing.

* I checked the process of assembly  from end to beginning.
* Paying attention to the JUMPI (conditional branch) part, what kind of conditions are branching, where is the value used for the condition? In order to proceed to the opposite branch, check what kind of input should be done and where.

The point to be careful when doing Debug by Remix,  
Even after you call the WinnerLog contract from the CashMoney contract, the display of the assembly is still a CashMoney contract.  
I noticed that the opcode being displayed and the change contents of the stack and memory are inseparably different from each other, so it is strange. (Probably a bug.)  

Since it can not be helped, I advanced understanding the assembly of WinnerLog with Disassembly appearing in the above decompiler.

![image](/post/2018/smart-contract-write-up_en/disassembly.png)

As a result, I found that the second argument of the logWinner function: In short, It is `players [msg.sender] .name`. needs to be as follows.

* Must be 128 bytes.
* The character string that XORed the second half of 64 bytes and `262d2527212d2b2c362d362a451acdc070148815b4ba154481c9c2983d8370d6` becomes `546861742077617320766572792063617368206d6f6e6579206f6620796f752e` (It will become "That was very cash money of you." When converting to ASCII).

Here is a transaction that sets a value that satisfies such a condition.
https://etherscan.io/tx/0x8a6bef803e7f9d1ad1e1724440bcec6a6d9e996f0a129485fc36c327bee0f559

In this state, when guessing numbers ...
https://etherscan.io/tx/0x7775c55ef8fa67c1f3bc9363d6b2130cb6c9957f6da08099594ffa5a9df7c29f

The prize money of 5 ETH was sent to me.
