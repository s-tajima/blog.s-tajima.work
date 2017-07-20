+++
author = "Satoshi Tajima"
categories = [ "ja", "ldap" ]
date = "2017-07-20T12:00:00+09:00"
description = ""
featured = ""
featuredalt = ""
featuredpath = ""
linktitle = ""
title = "CentOSでslapdのauditlogを有効にする"

+++

# 概要

CentOSにてRPM(openldap-servers)でインストールしたslapdを使う際、auditlogの設定でハマったのでその対応のメモです。
実際に検証したのは CentOS 7系 の環境ですが、CentOS 6系の環境にも適用できる話だと思います。

結論としては、Static Configurationの場合は `moduleload auditlog` を, Dynamic Configurationの場合は `olcModuleLoad: auditlog` を設定すればよいことがわかりました。
わかってしまえば簡単な設定なのですが、そこにたどり着くまでが大変だったのでその過程を残しておきます。

# slapdのOverlayについて

slapdには、[Overlays](http://www.openldap.org/doc/admin24/overlays.html#Audit Logging)と呼ばれるLDAPサーバの機能を拡張するための機構があります。
slapdにて監査ログを取得する場合、Audit Logging overlayを使用することができます。

manの[slapd.conf](https://linux.die.net/man/5/slapd.conf), [slapo-auditlog](https://linux.die.net/man/5/slapo-auditlog) によると、 Static Configurationの場合、


```
overlay auditlog
```

にてauditlogのoverlayを有効にし、

```
auditlog <filename>  
```

にてauditlogの出力先を指定すればよさそうなことがわかります。

# 困ったこと

前述のように設定し、slapdを起動しようとすると

> overlay "auditlog" not found

というエラーによって起動に失敗します。

このエラーの解消方法を調べていると、いくつか紛らわしい情報が見つかります。

### openldap-servers-overlays

auditlogを始めとするoverlayの類は、`openldap-servers-overlays` というRPMをインストールすることで利用可能になるという記述が見つかります。しかし実際は、このRPMを使うのはCentOS 5系の話のようで、CentOS 7系の環境においてはこのRPMは存在しません。

### By default it is not built.

manの [slapd.overlays](https://linux.die.net/man/5/slapd.overlays) を見ると

> auditlog  
> Audit Logging. This overlay records changes on a given backend database to an LDIF log file. By default it is not built.

という記述が見つかります。  
ビルドオプションを変更してRPMをビルドしなおさなければならないように思えますが、実際はそうではありません。

### modulepath

このように、auditlogのmoduleはopenldap-serversによって既にインストールされていそうなことがわかります。
```
$ rpm -qpl openldap-servers-2.4.40-13.el7.x86_64.rpm | grep auditlog
/usr/lib64/openldap/auditlog-2.4.so.2
/usr/lib64/openldap/auditlog-2.4.so.2.10.3
/usr/lib64/openldap/auditlog.la
```

ではなぜこのmoduleが読み込まれていないのかを調べます。
関連しそうな設定として、`modulepath` がありました。しかし、このパラメータのデフォルトは `/usr/lib64/openldap` となっているようなので、これを変更することで解決することはなさそうです。


# 解決方法

`modulepath` と関連した設定として `moduleload` というパラメータがあります。
 `modulepath` で指定したパスに存在するmoduleは自動的に読み込まれるものと思い込んでしまいましたが、実際は `moduleload` にてmodule名を指定する必要があるようです。

ということで、最終的には以下のように設定することで、auditlogを出力することができるということがわかりました。

```
modulepath /usr/lib64/openldap # デフォルト値なので省略可
moduleload auditlog
overlay auditlog
auditlog <filename>  
```


以上、CentOSでslapdのauditlogを使う方法でした。

