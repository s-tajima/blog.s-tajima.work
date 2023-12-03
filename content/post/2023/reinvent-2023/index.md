+++
author = "Satoshi Tajima"
categories = [ "ja", "aws", "reinvent" ]
#categories = [ "en", "" ]
date = "2023-12-03T23:00:00+09:00"
description = ""
featured = ""
featuredalt = ""
featuredpath = ""
linktitle = ""
images = ["post/2023/reinvent-2023/ogp.png"]
title = "re:Invent 2023 参加記録"
tags = [ "." ]

+++

AWS re:Invent 2023 の参加記録です。  
re:Inventへの参加は[2014年](https://s-tajima.hateblo.jp/entry/2014/11/17/134926)、2016年に続いて、今回が7年ぶり3回目です。  
私が働くFinatextホールディングスからは、合計3人での参加でした。  

# Expo

今回は、Expoを周って面白そうなサービスを探すことをメインとしてみました。  
30以上のブースで話してサービス説明を聞きました。  
その中から、今回始めて知ったものを中心に抜粋してご紹介します。(簡単なメモなので、細かいところは間違ってるかもしれません。)  

## [StackHawk](https://www.stackhawk.com/)

* APIのセキュリティテストのためのSaaS。
* 内部的にZAPがベースになっていて、OWAP Top 10の脆弱性を中心に検知可能。
* CI/CDに組み込んで実行可能。
* REST APIだけでなく、GraphQLやgRPCも対象にできる。
* GUIだけでなく、CLIによる操作も可能。
* APIの定義をOpenAPI Specificationなどから読み込むことも可能。

## [Gremlin](https://www.gremlin.com/)

* 可用性向上を支援するためのSaaS。
* カオスエンジニアリングや、可用性に影響する設定のレビュー・修正を行うツールを提供する。
* GameDayを開催することもできる模様。

## [Cohesity](https://www.cohesity.com/)

* 自然災害や、ランサムウェアから企業データを保護するためのバックアップ・リカバリのSaaS。
* オンプレミス・SaaS・IaaS等、様々な環境に対応している。

## [Qwiet AI](https://qwiet.ai/)

* SASTやContainer ScanningやSecrets Detectionを行うツール。
* Qwiet(Quiet)にも現れている通り、アラートのFalse Positive減らすことに多くの労力を注いでいるのが特徴。

## [veza](https://www.veza.com/)

* いわゆるIGAを実現するための製品。
* vezaを使うと、社員は一度IdP等の認証情報でログインをするだけで、その後追加の認証を必要とせず様々な社内システムにアクセスできるようになる。
* アクセスできる対象も、AWS等のIaaS、SalesforceのようなSaaS、DB、SSH等様々なものに対応。

## [rootly](https://rootly.com/)

* SlackのAppとして動くインシデントの管理ツール。
* すべての操作がSlackのUIからのChatOps(やボタンのクリック等)で完結する。
* インシデントを起票して、RunBookを表示したり、ロールを定義して人をアサインしたりできる。

## [granica](https://granica.ai/)

* 口頭の説明によると、独自の圧縮技術によってS3等のストレージコストを最適化できるツールらしい。
* (資料ベースではこちらがフォーカスされていたが)関連して、そのデータの機密情報をマスキングするなどのプライバシー保護の機能も提供しているとのこと。

## [Border0](https://www.border0.com/)

* AWSのマネジメントコンソールや、Web App、SSH Server、Database などに対するゲートウェイを提供するサービス。
* IdPと連携し、Border0にログインするだけでその先のサービスには手軽に接続できるようになる。
* 監査機能もある。

## [Gatling](https://gatling.io/)

* 負荷試験のツールです。
* 負荷試験の仕組みは[OSS](https://github.com/gatling/gatling)としても提供しつつ、結果を閲覧したりするSaaSも提供しています。

## [TSRI](https://tsri.com/)

* Generative AIを使って、コードの変換を行うサービス。
* 言語自体を別のものにしたり、同一の言語の中で新しいバージョンに対応した記述に書き換えるといったことが可能。
* 残念ながらGoが対応言語に入っていなかった。

## [LaunchDarkly](https://launchdarkly.com/)

* Feature Toggleをより簡単にリッチに実装するためのサービス。
* A/Bテストやカナリアリリースをよりやりやすくする。
* 様々な言語に対応し、Webアプリだけでなくスマホのネイティブアプリにも対応。

## [Lacework](https://www.lacework.com/)

* メインはいわゆるCNAPPとして、クラウドやサーバーやアプリケーションで発生したイベントを記録し、インシデント等の調査をサポートするツール
* CNAPP以外にも、CIEMやCSPM的な機能も持ち合わせている。
* 後述のGameDayでも色々な機能を使ってみることができた。

## [Arpio](https://arpio.io/)

* AWSのDR環境の構築を支援するためのツール。
* 既存のAWSの設定をスキャンし、ワンクリックで別のリージョンやアカウントにDR環境を構築できるようにする。
* VPCのようなコストのかからないリソースだけ事前に作成しておき、EC2/RDS等のコストのかかるリソースはフェイルオーバー時に作成するなどの対応もできる。
* デモを見た感じ完成度はそれなりに高そうで、多くのAWSサービスをカバーしていた。
* とても便利そうではある一方で、IaCとの相性が気になったので後ほどよく調べたい。

## [Anjuna](https://www.anjuna.io/)

* コンフィデンシャル・コンピューティングのためのPlatform。
* TEEとして、AWS Nitro Enclavesなどにも対応しているので、特別なホストを用意することなく利用可能。
* anjuna build コマンドで既存のコンテナイメージを変換することで簡単に利用できるようになる。

## [StrongDM](https://www.strongdm.com/)

* Infrastructure Access Platform
* StrongDMにログインすると、企業内の様々なシステムにアクセスできるようになる。
* すべてのアクセスをStrongDM経由にすることで、監査や承認がしやすくなる。
* Slack連携ができて、ChatOpsでアクセスのリクエストや承認もできるようだった。

## [BigID](https://bigid.com/)

* データの安全な管理をサポートするDSPMの製品
* 企業が保有するデータの検知や分類を支援したり、そのアクセス許可設定を検査して自動修復をしたりする。
* データストアは、様々なSaaS/IaaS/PaaS/オンプレミスの環境に対応。

## [Imperva](https://www.imperva.com/)

* 色々なサービスを複合的に提供しているが、おそらくメインはWAF/CDN。

## [CodiumAI](https://www.codium.ai/)

* AIを用いた、テストコードの自動生成のためのサービス。
* IDEと統合したり、Pull Requestベースでテストコードを追加できる。
* すべての言語をサポートはしているが、特定の機能はPythonやTypeScript等、一部の言語のみで利用可能。

# EBC (Executive Briefing Center)

出国前にAWSの方にアレンジしてもらい、Amazon Cognitoに関するセッションに参加することができました。  
セッションの具体的な内容はNDAのために記載できませんが、Cognitoに関して、当社からは利用状況の説明や機能に関する要望について話をしつつ、AWSからは内部のアーキテクチャや今後のマイルストーン、現在の開発体制等についての話をしてもらいました。

# Keynote

一般論としてはメインコンテンツですが、他の紹介記事が沢山あるので簡単にまとめます。  

多くの人の想定どおり、全体的にGenerative AI/LLMの話が大半を占めていました。  
一方で、個人的に一番良かったのは、WernerのThe Frugal Architectの話です。  
関連した内容は、 [Cost-Aware Architectures](https://medium.com/21st-century-architectures/cost-aware-architectures-8c07ed78d4d4) として10年以上前から提唱はされていたようで、かつ私も2017年に[AWS Summit Tokyo](https://aws.amazon.com/jp/blogs/news/ctonight-2017-spring-aws-summit-tokyo/) でこの話を聞いてずっと頭の中にある内容でした。今回、それがより体系的になり、かつ説明もしやすくなる材料として https://thefrugalarchitect.com/ のWebサイトが公開されたことを嬉しく思います。

# GameDay

AWS GameDay Championship: Network Topology Titans に参加しました。  
おなじみのUnicorn.Rentalsのエンジニアとして、ネットワーク関連のAWSサービスを活用して要求を満たせるシステムを構築したり、設定の修復をしていきます。  
前述のLaceworkも主催に加わっており、いくつか問題はLaceworkを活用してセキュリティ上の問題を調査・解決するものでした。  

# Workshop

BIZ302-R1 Amazon Connect: Deliver dynamic & personalized routing across channels に参加しました。  
Amazon Connectを使って、顧客のプロファイルに合わせて様々な処理を自動実行する仕組みを構築しました。  
Amazon Connectは、Keynoteで発表されたAmazon Qとの連携もできるようになり、注目しています。  

AWSはAWS Workshop Studioという、ワークショップなどのための使い捨てのAWS環境を払い出す仕組みを持っています。  
メタな感想ですが、これが参加のハードルを下げてくれる(自分のAWSアカウントだと、終了後の片付けが面倒だったり、意図せず費用がかかりすぎる心配がある)のでとてもありがたいです。  
GameDayの環境もこのWorkshop Studioが使われていました。  

# その他

## 移動

re:Inventの会場はとてつもなく広く、複数のホテルにまたがっているため、複数の移動方法を把握して場面に応じて最適な方法を選択することが大事です。

### 徒歩

会場の中の基本的な移動は徒歩です。  
1つのホテルでもとてつもなく広く、かなりの距離を歩くことになります。   
Google Fitによると、他の移動手段も組み合わせた上ですら、毎日10km以上歩いていた模様です。  

![walk](/post/2023/reinvent-2023/walk.png)

### Shuttle

シャトルバスのことです。  
会場のホテル間の移動はこれが便利です。  
各ホテルからピストン輸送をしていて、あまり待つことなく利用することができました。  
最後のre:Playも、会場までのShuttleが出ていたのでこれを使って移動しました。  

### [Las Vegas Monorail](https://www.lvmonorail.com/)

ラスベガスの町中を走るモノレールです。  
re:Inventの参加者は、指定の時間内であればこのモノレール無料で利用できることになっていました。  
"ことになっていた" というのは、実際には運営上の連携不足によるものか、無料で乗れることと乗れないことがありました。  
無料で乗れなかった場合は、券売機でチケットを購入して乗ることになります。  
乗り場がかなりわかりにくいところにあり、探すのが大変でした。  

### Rideshare

UberやLyftなどのことです。  
以前は地図で指定した場所どこにでも呼べた気がするのですが、今回使ってみたらホテルやショッピングセンター等では指定された場所以外には呼べない仕様になっていました。大抵、「Rideshare」と書かれた案内板があるので、その場所で待つことになります。  
日中はスムーズに使えることが多かったですが、夕方以降は、待合所はかなりの人と車で混雑していました。  

### タクシー

re:Invent会場においては使わなかったのですが、ハリー・リード国際空港(LAS)からホテルの移動に使いました。  
空港からホテルの移動は[定額制になっていて](https://lasvegasthenandnow.com/airport-to-hotel-taxi-flat-rates-take-effect-does-it-matter/)、Rideshareのように呼んでから待つ必要もなくすぐ乗れました。  

## ホテル

[The Signature at MGM Grand](https://signaturemgmgrand.mgmresorts.com/en.html) に泊まりました。  
re:Inventの公式サイトから予約できる中では新しい方のホテルで、2006のオープンのようです。  
(今までに泊まったことのあるラスベガスの他のホテルと比べると)たしかに部屋は新しい雰囲気でした。  
また、部屋にはキッチンがついていて、料理もできそうでした。  
部屋はとても良かったのですが、ShuttleやLas Vegas Monorailの乗り場から遠いのが若干のネックでした。  


## ネットワーク

私は日本のキャリアではahamoを契約しています。それほど話題になっていない(気がする)のですが、ahamoは[海外の特定の国では追加の料金や手続き不要でデータ通信ができる](https://ahamo.com/services/roaming-data/index.html)というメリットがあります。当然、アメリカはその対象国になっています。  
ahamo契約後、初めての海外渡航だったのですが、本当にそのままデータ通信できた(場合によっては端末の設定を一部変更する必要があります)ので、とても便利でした。別途SIMを用意したり、モバイルルーターをレンタルしなくて良いのはとても楽ですね。  

---

以上、AWS re:Invent 2023のまとめでした。  
今年参加できなかった人や、来年以降参加する人の参考になればと思います。  

