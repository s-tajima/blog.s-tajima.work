+++
author = "Satoshi Tajima"
#categories = [ "en", "" ]
#date = "2018-11-08T12:30:00+09:00"
description = ""
featured = ""
featuredalt = ""
featuredpath = ""
linktitle = ""
#title = "CODE BLUE 2018 Smart Contract Hacking Challenge WriteUp (en)"

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

I was wondering why human readable code is there.  
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


At this time, I've wrote code like this and execute the Contract by using web3.js of Node.js.  
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

処理を追っていくと、正しく設定されたcurrentの値(このときは4でした)が以下の処理のタイミングで書き換えられていることがわかりました。

```
Guess storage guess;
guess.playerNo = players[msg.sender].playerNo; // ここでなぜかcurrentの値が変更される
```

調べてみると、guessが正しく初期化されていないことが問題になっていることがわかりました。  
Solidityの仕様として、この正しく初期化されていない guess.playerNo に対しての値の操作は slot 0 に対する操作ということになるようです。   
**つまり current が players[msg.sender].playerNo の値に書き換えられます。**

このとき、playerNoの値は 42 (渡された紙に書いてありました) にしてあったので、その値が設定されたようです。

ここまでわかればあとは簡単です。
players[msg.sender].playerNo を 10以下の値にして、  
https://etherscan.io/tx/0x1b9a902a3faf65aaa8033435d3118ae844887a1861e4e8095530b3eaf1ced1eb#decodetab

かつそれを予想した番号としてコントラクトを呼び出せばよいのです。  
https://etherscan.io/tx/0xd27020cbbab206982d6a66f67ea3c5c1c983806f2199ae330ae8785bdfb124c3

しかし、残念ながらこれでもまだ ETH を獲得することはできませんでした。


## WinnerLog のデコンパイル

再度 Remixで実行状況を確認すると、正解の番号と予想した番号の比較の部分は無事に通過していました。

しかしその後、以下の外部コントラクト(WinnerLog)の呼び出しのところで処理が終わっていることがわかりました。
```
winnerLog.logWinner(msg.sender, players[msg.sender].playerNo, players[msg.sender].name);
```

現在実行しているコントラクト(0x64ba92...) には、WinnerLogコントラクトのソースコードも記載されていて、それによると logWinner は以下のような定義になっています。

```
function logWinner(address addr, uint256 playerNo, bytes name) public onlyPlayer { 
        winners[addr] = true;
        winner_name_list.push(string(name));
        winner_addr_list.push(addr);
        emit NewWinner(msg.sender, string(name), playerNo);
}
```

これだけ見ると、特にエラーになるような要因もなさそうです。
が、ここに次の罠があります。

winnerLog は、CashMoneyコントラクトのconstructorで以下のように作成されています。
```
winnerLog = WinnerLog(winnerLog_);
```
このとき `winnerLog_` の値は、とある別のコントラクトのアドレス(0x2e4d2a...) が指定されています。  
**つまり、`logWinner` は必ずしも上記のソースコードの通りに実行されているとは限らず、  
それどころか 0x2e4d2a... のコントラクトでは全く別の処理をしている可能性があります。**

では、0x2e4d2a... のコントラクトを確認してみましょう。  
https://etherscan.io/address/0x2e4d2a597a2fcbdf6cc55eb5c973e76aa19ac410#code

![image](/post/2018/smart-contract-write-up_en/2e4d2a.png)

残念ながらこちらはソースコードが確認できません。  
そうです。このバイトコード or アセンブリ を読み解く必要があるのです。  
この手の解析は今までそんなに経験があるわけでもなくなかなかしんどそうだったので、  
デコンパイラを探してみました。

すると、 [Online Solidity Decompiler](https://ethervm.io/decompile) というのを見つけたのでこれを使ってみました。  
デコンパイルした結果がこちら。  
https://ethervm.io/decompile?address=0x2E4d2a597A2fcBdF6CC55eb5c973E76Aa19Ac410&network=

![image](/post/2018/smart-contract-write-up_en/decompilation.png)

少しはマシになりました。しかし、まだ読み解くのは難しいです。  
また、このコードはSolidityとしてValidなものではないので、これをデプロイして動作を確認してみることもできません。


## アセンブリのデバッグ

仕方なく、アセンブリのままでデバッグを進めることにしました。  
EVMのオペコードは [ethervm.ioのもの](https://ethervm.io/) を参考にしました。

デバッグは、RemixのDebugger機能を使いました。  
いろいろと試行錯誤しながら進めたのですが、  

* アセンブリの処理を最後から遡りながら見ていく。
* JUMPI (条件分岐) の部分に注目し、どんな条件の分岐なのか、条件に使われた値はどこからきているのか。反対の分岐に進むためにはどこでどんな入力をすればいいのかを確認する。

というのをがんばりました。

ハマりどころとしては、RemixによるDebugをする際、  
CashMoneyコントラクトからWinnerLogコントラクトをCallした後も、アセンブリの部分はCashMoneyコントラクトのままなところです。  
表示されているオペコードと、スタックやメモリの変更内容がどうも食い違うのでおかしいなと気付きました。(おそらくバグ。)   
仕方ないので、WinnerLogのアセンブリは先述のデコンパイラで一緒に出てくる Disassembly を見ながら進めました。  

![image](/post/2018/smart-contract-write-up_en/disassembly.png)

結果として、logWinner関数の第2引数、つまり players[msg.sender].name を、

* 128byte にすること。
* 後半の64byteと `262d2527212d2b2c362d362a451acdc070148815b4ba154481c9c2983d8370d6` をXORした文字列が `546861742077617320766572792063617368206d6f6e6579206f6620796f752e`(ASCII に変換すると `That was very cash money of you.` になります。) になるようにすること。

が必要であることがわかりました。
(あっさり書いてますがかなり頑張りました。)

そんな条件を満たした値をセットしたトランザクションがこちら。  
https://etherscan.io/tx/0x8a6bef803e7f9d1ad1e1724440bcec6a6d9e996f0a129485fc36c327bee0f559

この状態で、番号を予想すると...  
https://etherscan.io/tx/0x7775c55ef8fa67c1f3bc9363d6b2130cb6c9957f6da08099594ffa5a9df7c29f

見事に賞金の 5ETH が送金されてきます。(トランザクションIDが 777 で始まっていて縁起がいいですね。)

# 最後に

以上、Smart Contract Hacking ChallengeのWriteUpでした。  
PolySwarm の皆さん、とてもよいChallengeをありがとうございました。  
せっかくなので、今度は自分でSmart Contractでも書いてみようかなと思います。

