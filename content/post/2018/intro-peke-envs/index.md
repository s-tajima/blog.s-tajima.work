+++
author = "Satoshi Tajima"
categories = [ "ja", "" ]
date = "2018-10-15T12:00:00+09:00"
description = ""
featured = ""
featuredalt = ""
featuredpath = ""
linktitle = ""
title = "ptraceを使ってプロセスの *現在の* 環境変数を参照する"

+++


ptraceを使って特定のプロセスの **現在の** 環境変数を参照するためのプログラムを書いてみたのでその紹介です。

## 背景

Linuxを使っていると、プロセスの環境変数を参照したいと思うことってありますよね。  
そんなとき、僕はよく `/proc/[PID]/environ` を参照します。  

```
$ strings /proc/1234/environ
LANG=ja_JP.UTF-8
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
.. snip ..
```
(権限がないプロセスを対象にする場合はroot権限が必要です。)  

しかし、 `/proc/[PID]/environ` で参照できるのはあくまで **プロセス実行時の** 環境変数のみであり、  
実行後に追加/変更されたものを参照することができません。  

つまり、このようにDotenv等によって追加された変数を参照することはできないということです。  

* 起動時にシェルから / 起動後にDotenvで 追加した環境変数を表示するスクリプト(env.rb)を実行。

```
$ cat env.rb
require 'dotenv'
Dotenv.load

puts "pid: #{$$}"
puts "STARTUP_KEY: #{ENV['STARTUP_KEY']}"
puts "DOTENV_ADDED_KEY: #{ENV['DOTENV_ADDED_KEY']}"
sleep 10

$ cat .env
DOTENV_ADDED_KEY=DOTENV_ADDED_VAL

$ STARTUP_KEY=STARTUP_VAL ruby env.rb
pid: 7716
STARTUP_KEY: STARTUP_VAL
DOTENV_ADDED_KEY: DOTENV_ADDED_VAL
# .. sleeping ..
```
* 別のシェルから `/proc/[PID]/environ` を確認。

```
$ strings /proc/7716/environ | grep _KEY=
STARTUP_KEY=STARTUP_VAL
```

今開いているシェルのプロセスに限って言えば、 `env` コマンドを使うことができます。  
`env` コマンドであれば、プロセス(シェル)起動後に追加された環境変数も参照できます。  

```
$ env | grep ADDED_KEY
$ export ADDED_KEY=ADDED_VALUE
$ env | grep ADDED_KEY
ADDED_KEY=ADDED_VALUE
```

では、それ以外のプロセスの **現在の** 環境変数を参照したい場合はどうすればよいでしょう。  
今回は、それを実現するためのプログラムを書いてみたという話です。  

尚、プログラムを書いてみたのはあくまで学習目的であり、  
同様のことを手軽にやるならgdbを使うことをおすすめします。  

## peke_envs

作成したプログラムはこちら。  
https://github.com/s-tajima/peke_envs  

先程の env.rb のプロセスに対して実行すると、このようにDotenvで追加した環境変数も表示されます。
```
$ ./peek 7716
.. snip ..
STARTUP_KEY=STARTUP_VAL
DOTENV_ADDED_KEY=DOTENV_ADDED_VAL
.. snip ..
```

尚、現時点ではすべてのプロセスを対象にできるわけではなく、  
libcをダイナミックリンクしているプロセスだけを対象にできます。  
理由は次に記載する動作の仕組みによるものです。  

*エラーハンドリングの不備により、対象のプロセスが停止状態のままになってしまう(SIGCONTを送れば再開できます) ケースがあるので、重要なプロセスを対象にするのは避けてください。*

## 動作の仕組み

*もしかしたら認識や表現が誤っている部分があるかもしれないですが、そのときはTwitterなどで教えてください。*

Linux上で稼働するプロセスは、POSIXに準拠しています。  
環境変数というのは、POSIXで定義されている値で environ というポインタから参照できます。  
現状、多くのプログラムはPOSIXに準拠するためにlibcというライブラリを使っています。  

よって、対象のプロセスにおいてlibcがマッピングされているアドレスを調べ、  そのlibcにおける environ ポインタのオフセットを調べ、  対象のプロセスにおいてenviron ポインタの値を参照し、  それを辿ることで環境変数の値が参照できます。  

肝となるのは ptrace(2) というシステムコールです。  
http://man.he.net/?topic=ptrace&section=all  

> The ptrace() system call provides a means by which one process (the "tracer") may observe and control the execution of another process (the "tracee"), and examine and change the tracee's memory and registers.

ドキュメントにある通り、 ptrace を使うと特定のプロセスのメモリ値を参照したり、書き換えたりすることができます。
操作の内容は、ptraceの第一引数で指定するのですが、 PTRACE_PEEKDATAで値の参照、PTRACE_POKEDATAで値の書き換えができます。これが peke_envsの名前の由来です。

この方法であれば、プロセスのメモリ **現在の** 状態を直接参照するので、起動後に追加された環境変数も参照できるのです。

straceやgdbも、内部的にはこのptraceを使って動作しています。


## これから

peke_envsは勉強のためにRustで書いてみました。  
Rustを書くのは初めてで、まだ慣れないところがあって思うようにかけてないところもありますが、  
少しずつ良くしていこうと思っています。  

また、現時点では環境変数を参照するところまでしかできていないのですが、  
変更や追加もできるようにしてみようと思っています。  
今のように環境変数のアドレスに対して直接操作(PEEKDATA/POKEDATA)するのではなく、  
対象のプロセスの `putenv()/setenv()` を呼び出すというアプローチをとってみようと思っています。  

## 余談

今回のように稼働中のプロセスの環境変数を操作してみようと思い至ったのは、Webアプリケーションにおけるデータベース等の認証情報の取り扱いについて考えたのがきっかけでした。  

AWS Secrets Manager や HashiCorp Vault を使うと、認証情報を定期的に自動的にローテートすることができるようになります。  
問題となるのは、Webアプリケーションからローテート後の認証情報を使えるようにするところなのですが、通常は Secrets ManagerのAPIを呼び出すための [SDK](https://aws.amazon.com/jp/tools/) や、Vaultの [クライアントライブラリ](https://www.vaultproject.io/api/libraries.html) を使って認証情報を取得する実装を書く必要があります。  
毎回そういった実装をアプリケーションに書いていくのは少し面倒だし、OSSなどでそのあたりを自由にコントロールできないというケースもあります。  
「Secrets ManagerやVaultによる認証情報のローテートを検知して、対象のプロセスの環境変数を自動的に書き換えてくれるような仕組み」が作れると、既存のアプリケーションはあくまで環境変数を読み込むだけでよく、また開発環境のため処理を分岐するといったこともせずに済むので楽なのではと考えました。  

結局、こんなやり方をしなくとも、少し雑ですが「認証情報のローテートを検知して、認証情報を環境変数にセットした上で対象のプロセスを再起動する」という仕組みでも十分なのではと考え直したので、peke_envsはあくまで趣味の勉強のためという範疇にとどまるでしょう。  
Rustやptrace(2)の勉強をするいい機会になりました。  
