+++
author = "Satoshi Tajima"
categories = ["ja", "aws"]
date = "2017-05-11T23:21:25+09:00"
description = ""
featured = ""
featuredalt = ""
featuredpath = ""
linktitle = ""
title = "AWSのAMIをゼロから作る autoknitterの紹介"

+++

# TL; DR

* AWSでは自分で作成したAMIを使いたい。
* PackerのEBS Surrogate Builderを使うと便利にAMIを作成できる。
* EBS Surrogate Builderをより簡単に使えるように autoknitter という参照実行を公開した。

# 背景

AWSのEC2を使う上で、どのAMIを利用するかというのはとても重要な選択の1つです。

細かい選択肢は色々ありますが、大きく分けると

1. Community AMIsにて提供されているAMIを利用する
2. AWS Marketplaceにて提供されているAMIを利用する
3. 自分たちでAMIを作成する

というパターンがあると思います。

AWSへのロックインを避けたい、 AWS以外の環境でも同じOSを利用したいといった要件から、CentOSを利用したい場合を考えてみます。

まず、1のCommunity AMIsで CentOS を検索してみます。

![choose-ami-community](/post/2017/intro-autoknitter/choose-ami-community.png)

このようにたくさんのAMIが出てきます。  
しかし、基本的にはこれらは *だれが作ったのか* も *どうやって作ったのか* もわからないAMIです。
悪意のあるAMIが公開されていない保証がないため使うにはリスクが伴います。

AWSとしてもこのような [ガイドライン](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/building-shared-amis.html) を公開していますが、個人的には利用は避けたいところです。

次に、2のAWS Marketplaceにて CentOS を検索してみます。

![choose-ami-marketplace](/post/2017/intro-autoknitter/choose-ami-marketplace.png)

こちらもいくつかのAMIが出てきます。  
今度は Centos.org が提供するAMIも出てきました。
Centos.org が提供するAMIであれば、Community AMIsの時のようなリスクは伴わないと考えてもよさそうです。
しかしこれを利用するには注意が必要で、このAMIから作成されたEBSはRoot Volumeとして以外はアタッチできないという制限を受けることになります。  

サポートケースを起票すればその制限を解除してもらうこともできるようですが、障害対応時等、緊急度の高いときにはそんな余裕がないこともありそうなのでこの選択肢も避けたいところです。

参考: https://www.quora.com/Amazon-EC2/Amazon-EC2-Is-it-possible-to-rescue-an-EBS-volume-which-has-marketplace-codes

最後の手段として、3の通り自分たちでAMIをビルドすることになります。

# Packer, EBS Surrogate Builderの紹介

[Packer](https://www.packer.io/) には、AWSのAMIを作成するためのBuilderが実装されています。  

[Amazon AMI Builder](https://www.packer.io/docs/builders/amazon.html) に記載されている通り、そのためのBuilderは複数用意されているのですが、
今回はその中でも [EBS Surrogate Builder](https://www.packer.io/docs/builders/amazon-ebssurrogate.html) を利用してAMIを作成します。  

EBS Surrogate BuilderによるAMI作成の仕組みについて説明します。

![amazon-ebssurrogate.png](/post/2017/intro-autoknitter/amazon-ebssurrogate.png)

1. まずAMI構築の作業用インスタンス(Source Instance)が起動されます。
2. Source Instanceにアタッチされた、AMIのルートボリュームとして利用するEBS(AMI Root Device)に対して、OSのイメージを書き込みます。
3. AMI Root Deviceのスナップショットを作成し、そのスナップショットからAMIを作成します。

EBS Surrogate Builderを使うことで、

* AMI作成の手順をコードで記述することで、自動化され再現性のある状態になる。
* 元となるAMIを必要とせず、空のEBSからAMIを作成できる。
* 作業用のインスタンスを毎回自動起動/ターミネートできる。

といった条件でAMIを作成することができます。  

EBS Surrogate Builderはとても便利な手段なのですが、AMI Root Deviceに対してOSのイメージを書き込むための手順を実装するのが一番の手間になります。

# autoknitter

EBS Surrogate Builderをより簡単に使えるように、autoknitterというリポジトリを公開しました。 

https://github.com/s-tajima/autoknitter

autoknitterはPackerのEBS Surrogate Builderを利用するための参考実装です。
セットアップ後、このように `make build` するだけでAMIが作成できるようになっています。

```text
$ make build
./bin/packer build \
	-var-file ./variables.json \
	-var-file ./resources/centos/6.9/variables.json \
	./template.json
amazon-ebssurrogate output will be in this color.

==> amazon-ebssurrogate: Prevalidating AMI Name...

.. snip ..

Build 'amazon-ebssurrogate' finished.

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebssurrogate: AMIs were created:

ap-northeast-1: ami-XXXXXXXX
```

現在対応しているディストリビューションはCentOS 6.9のみですが、今後色々なバリエーションを増やしていく予定です。
