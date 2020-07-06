+++
author = "Satoshi Tajima"
categories = [ "ja", "" ]
date = "2020-07-05T12:00:00+09:00"
description = ""
featured = ""
featuredalt = ""
featuredpath = ""
linktitle = ""
title = "GoでNIST SP 800-63Bに則ったPassword Validatorを作りました"

+++

インターネットのサービスを利用する上で、どんなパスワードを設定するかというのはアカウントを安全に保護する上で重要な要素になります。
日常的にデータ漏洩がおこり、多くのパスワードリストが出回る現代においては、少し頭を捻って考えたくらいのパスワードだと、突破されてしまうリスクは非常に高いでしょう。

いちサービス利用者としては、パスワードマネージャーを使いサイトごとに個別のランダムな文字列をパスワードに設定しておくことで、そのリスクを低減することができます。
サービスの提供者としては、適切なパスワードのバリデーションルールを設けることで、利用者が危険なパスワードを設定してしまうことを防ぐ事ができます。

しかし、 "パスワードのバリデーションルール" というのはサービスによってバラバラで、中にはかえって安全なパスワードを設定するのを阻むバリデーションルールも存在しています。

『NIST Special Publication 800-63B Digital Identity Guidelines (NIST SP 800-63B)』というガイドライン(数年前に「パスワードの定期変更は不要」というくだりで話題になったあの資料です) には、Memorized Secrets(つまりパスワードのこと)の設定時・変更時において、どのような基準でそれを受け入れるべきかというのが書かれています。このガイドライン自体は、アメリカの政府機関に向けたものなので、日本でサービスを提供する上では何ら強制力はないのですが、非常に参考になるものです。

今回、この NIST SP 800-63B に書かれた推奨事項に則ったGo製のパスワードバリデーターを作成したので紹介します。
https://github.com/s-tajima/nspv

---

# nspvによるバリデーション

## パスワードの文字列長

NIST SP 800-63B には、 

> Verifiers SHALL require subscriber-chosen memorized secrets to be at least 8 characters in length.   
> Verifiers SHOULD permit subscriber-chosen memorized secrets at least 64 characters in length.

ということで、

* パスワードは最低8文字であることをもとめなければならず
* パスワードは最低64文字を許容するべきである

と書かれています。

これは特に難しいことではなく、単純に文字列長を確認することで実現します。

## よく使われる、漏洩したことのあるパスワード

この項目がとても重要です。

> verifiers SHALL compare the prospective secrets against a list that contains values known to be commonly-used, expected, or compromised. For example, the list MAY include, but is not limited to:  
> 
> * Passwords obtained from previous breach corpuses.  
> * Dictionary words.  
> * Repetitive or sequential characters (e.g. ‘aaaaaa’, ‘1234abcd’).  

ということで、

* よく使われていたり、推測可能だったり、侵害されたパスワードではないことを確認しなければならない

と書かれています。

これを実現するために、 [Have I Been Pwned](https://haveibeenpwned.com/) の [PwnedPasswords API](https://haveibeenpwned.com/API/v3#PwnedPasswords) を利用しています。

PwnedPasswords API は、k-匿名化という手法を使って、APIにパスワード自体を送信することなく、そのパスワードが侵害されたものかを確認することができます。


## コンテキストから推測可能なパスワード

上記のリストには、

> * Context-specific words, such as the name of the service, the username, and derivatives thereof.

ということで、

* サービス名やユーザーネームのような、コンテキストに特化した単語と、その派生

も禁止しなければならないと書かれています。

これは、任意のカスタム辞書を登録できるようにし、その文字列とパスワードのレーベンシュタイン距離をとることで、推測可能なパスワードになっていないかを判定します。

# nspvの使い方

## ベーシックな使い方

nspvのベーシックな使い方はこのとおりです。

```go
v := nspv.NewValidator()
v.SetDict([]string{"nist-sp-800-63"})

result, err := v.Validate("_sup3r_comp1ex_passw0rd_")
if err != nil {
    // HIBPのAPIへのリクエストが失敗した等、バリデーションの実行に問題があった場合は err が返ります。
}
if result != nspv.Ok {
    // バリデーションの失敗は result で表現します。
}
fmt.Println(result.String()) // Ok
```

## カスタムした使い方

```go
v := nspv.NewValidator()
v.SetHibpThreshold(3) // PwnedPasswords API が返すパスワードの漏洩回数もとに、一定回数まで許容することができます。
v.SetLevenshteinThreshold(4) // カスタム辞書とのレーベンシュタイン距離のしきい値を変更することができます。

v.Validate("_sup3r_comp1ex_passw0rd_")
```

---

最後に一番大事なこととして、 NIST SP 800-63B には

> Verifiers SHOULD NOT impose other composition rules (e.g., requiring mixtures of different character types or prohibiting consecutively repeated characters) for memorized secrets.

ということで、一般的に使われる "複数の文字種を混ぜることを求める" "連続して繰り返される文字を禁止する" のような、追加のルールを強制すべきではないとも書かれています。
よって、nspvは上記3つの観点以外ではパスワードのバリデーションを行いません。

一般消費者向けサービスとしては[FIDO2](https://fidoalliance.org/fido2/)やSlackのMagic Link のようなPasswordLess Authenticationが広まっていったり、企業においてはSSOのような仕組みが広がることで、パスワード自体を設定する必要のあるサービスというのは徐々に減っていくとは思います。
しかし、それができずどうしてもパスワードが必要になる場面において、少しでも "マシな" パスワードが設定されることの助けになったらいいなと思っています。
