# docker-volume-global

ノードを超えてデータを共有できる、'global' と名前の付いた docker volume を作成するインストールスクリプトです。

docker swarm init, docker swarm join でノードを登録したあとに以下のスクリプトを実行するイメージ。

docker volume の共有には、nfs + netshare plugin を利用。

動作環境は ubuntu。

## nfs サーバとしてインストール

````
curl -sSL https://raw.githubusercontent.com/nunun/docker-volume-global/master/install.sh | sudo sh
````

nfs-server と netshare plugin をインストールし、/etc/exports を作成してサービスをリスタートします。

全て終わると global ボリュームができるので、このボリュームを他のコンテナでマウントして使います。

マウントは docker swarm のノードに制限されているため、

新しくノードを追加した場合は、もう一度コマンドを叩いて /etc/exports を更新する必要があります。

## nfs クライアントとしてインストール。

````
curl -sSL https://raw.githubusercontent.com/nunun/docker-volume-global/master/install.sh | sudo sh -s <server-ip>
````

netshare plugin をインストールします。

全て終わると global ボリュームができるので、このボリュームを他のコンテナでマウントして使います。

## 動作確認

````
docker run --rm -v global:/global alpine touch /global/hoge
docker run --rm -v global:/global alpine ls /global
````
