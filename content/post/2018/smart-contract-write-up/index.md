+++
author = "Satoshi Tajima"
categories = [ "ja", "" ]
#categories = [ "en", "" ]
date = "2018-11-08T12:00:00+09:00"
description = ""
featured = ""
featuredalt = ""
featuredpath = ""
linktitle = ""
title = "CODE BLUE 2018 Smart Contract Hacking Challenge WriteUp"

+++


2018/10/29 ~ 2018/11/20 に開催された CODE BLUE 2018 に参加し、  
そこで行われていた [PolySwarm](https://polyswarm.io/) の [Smart Contract Hacking Challenge](https://codeblue.jp/2018/contests/detail_03/) に挑戦してみました。

結果、1位で解くことができたのでそのWriteUpを公開します。

# 前提知識

このコンテストに参加した時点の僕は

* 暗号通貨に興味があり、国内外の暗号通貨取引所で取引をしたことがある。
* Smart contractは趣味で勉強し、概要は理解している。
* 自分でSmart contractのコードを書いたり、実用的に利用したことはなく、 [CryptoZombies](https://cryptozombies.io/) を一通りやったことがある程度。

といった感じです。
だいたいこのあたりのレベルの人達に向けた記事になってます。  
このレベルから、Smart contractの実行やデバッグに必要なツールや知識を徐々に手に入れていき、  
最終的に問題を解くことができるようになるまでの話になります。  

Smart contractとは?  Solidityとは? といった内容は触れません。  
逆に、EVMに詳しい方にはもっと効率のよい解き方があれば教えてほしいなと思ってます。

# 問題

CODE BLUE の PolySwarm のブースに行き、  
Smart Contract Hacking Challenge に参加したい旨を伝えると、1枚の紙がもらえます。

紙には

* [Ethereumのコントラクトのアドレス](https://etherscan.io/address/0x64ba926175bc69ba757ef53a6d5ef616889c9999) (EtherscanのURL)
* EthereumのEOAのアドレス・秘密鍵

が記載されています。

このコントラクトがハックすべき対象です。

# 解き方

## コントラクトの確認

コントラクトの内容を確認するため、まずは Etherscan の [Codeタブ](https://etherscan.io/address/0x64ba926175bc69ba757ef53a6d5ef616889c9999#code) を見ます。

![image](/post/2018/smart-contract-write-up/64ba92.png)

ここで不思議だったのが、Human Readableなソースコードが表示されている点です。  
Ethereumのブロックチェーンには、コントラクトはバイトコードとして書き込まれているはずなので、  
このような形でソースコードが確認できるのはおかしいと思いました。  

調べてみると、 Etherscan には、 [Verify Contract Code](https://etherscan.io/verifyContract2) という仕組みがあり、  
あるアドレスを指定してコントラクトのソースコードをアップロードし、  
コンパイルされた結果がブロックチェーン上のものと一致すればこのように表示することができる仕組みがあるようです。

ということで、ここに表示されたソースコードを読んでいきます。  
173行なのでそれほど読むのは大変ではなく、コントラクトの概要は、

* CashMoney という数当てゲーム。
* 数字を予想する際にはコントラクトにに 0.001 ETH 以上を送金する必要がある。
* 数が当たると、送金した金額に加えて先着順でボーナスの ETH が返金される。
* 数が外れると、送金した ETH はコントラクトが没収。

というものでした。
もう少し詳しい仕様として、

* 予測する数字の範囲は 0 ~ 10。
* チャレンジできるのは、予めコントラクト作成者がプレイヤーとして指定したアドレス(冒頭の紙に書かれていたもの)からのみ。
* プレイヤーの情報 (プレイヤーNo. と 名前) を設定することができる。
* 同じアドレスが複数回ボーナスを獲得できないように、WinnerLogという別のコントラクトにログが記録される。

といったものであることもわかりました。

## 最初のトライ

正解の数字がどのように決められているのかを確認します。

すると、正解の数字は
```
uint256 private current;
```
として定義され、

```
function every_day_im_shufflin() internal {
    // EVERY DAY IM SHUFFLIN
    current = uint8(keccak256(abi.encodePacked(blockhash(block.number-2)))) % 11;
}
```
という関数で設定されているのがわかります。  
また、この every_day_im_shufflin() は、コントラクト作成時と、誰かが数字を当てた時によびだされているようです。

予想する数字が 0 ~ 10 であり、正解がシャッフルされるのが誰かが数字を当てたときだけなのであれば、  
総当たりで正解できてしまうのでは? と思って試してみることにしました。

このときは、Node.jsのweb3.jsを使ってこんなコードを書き、コントラクトを実行していました。  
https://gist.github.com/s-tajima/970901318960c038291ff90f4404fe35

ここから  
https://etherscan.io/tx/0xc9e32cf91c122a62c001e6a34b05e970e4c27eb0e807301b20953bc03601f0b8

ここまであたりがそのトライです。  
https://etherscan.io/tx/0xc7315ef6469d22c7c55d20c86bc80a59b8145d39ba74f24df96fc93782521660

結果としては、当然そんな簡単に解けてしまう問題であるわけはなく、  
0 ~ 10のすべての数字でトランザクションがRevertされてしまいます。


## Remix によるデバッグ

次の手を考える上で、コントラクトがどのように実行されているのかを知りたくなりました。  
[Remix](https://remix.ethereum.org/) という、SolidityのIDEがあるのを知っていたので、試しにそれを使ってみました。

![image](/post/2018/smart-contract-write-up/remix_01.png)

Etherscanで手に入れたソースコードを貼り付け、コントラクトのアドレスを指定すると、  
Remixからコントラクトを呼び出せるようになります。

また、Debuggerの機能を使うと、呼び出したコントラクトの実行状況を確認することができます。  
このデバッグ機能を使うと、Solidity上でprivateとして定義した変数も参照できます。

(privateという修飾子は、単なるスコープの定義であって、誰からも見えないようにするという設定ではないので、自分でコントラクトのコードを書くときには注意しましょう。)

Debuggerを利用し、正解の番号と予想した番号を比較している処理を確認すると、  
正解の番号(current)がなぜか `42` になっているのがわかりました。

![image](/post/2018/smart-contract-write-up/remix_02.png)

前述した current の設定方法(ある値を11で割った余り)では、ここが `42` になることはなさそうで、  
また、予想した番号が `10` より大きい値だとエラーになるようなコードもあったので、なにかがおかしいです。

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

![image](/post/2018/smart-contract-write-up/2e4d2a.png)

残念ながらこちらはソースコードが確認できません。  
そうです。このバイトコード or アセンブリ を読み解く必要があるのです。  
この手の解析は今までそんなに経験があるわけでもなくなかなかしんどそうだったので、  
デコンパイラを探してみました。

すると、 [Online Solidity Decompiler](https://ethervm.io/decompile) というのを見つけたのでこれを使ってみました。  
デコンパイルした結果がこちら。  
https://ethervm.io/decompile?address=0x2E4d2a597A2fcBdF6CC55eb5c973E76Aa19Ac410&network=

![image](/post/2018/smart-contract-write-up/decompilation.png)

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

![image](/post/2018/smart-contract-write-up/disassembly.png)

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

