# docker-global-volume

ノードを超えてデータを共有できる、'global' と名前の付いた docker volume を作成するインストールスクリプトです。

docker swarm init, docker swarm join でノードを全登録したあとに以下のスクリプトを実行する感じで運用。

docker volume の共有には、nfs + netshare plugin を利用。

動作環境は ubuntu。

* docker volume netshare plugin
  * https://github.com/ContainX/docker-volume-netshare

## nfs サーバとして global ボリュームをインストール

````
curl -sSL https://raw.githubusercontent.com/nunun/docker-global-volume/master/install.sh | sudo sh
````

ノードに nfs-server と netshare plugin をインストールし、/etc/exports を作成して nfs-server をリスタートします。

全て終わると global ボリュームができるので、このボリュームを他のコンテナでマウントして使って下さい。

nfs マウントを docker swarm 内のノードに制限するため、nfs サーバとなるノードは swarm manager でなければなりません。

また、swarm に新しくノードを追加する場合は、追加後にもう一度コマンドを叩いて /etc/exports を更新する必要があります。

## nfs クライアントとして global ボリュームをインストール

````
curl -sSL https://raw.githubusercontent.com/nunun/docker-global-volume/master/install.sh | sudo sh -s <server-ip>
````

ノードに netshare plugin をインストールします。

全て終わると global ボリュームができるので、このボリュームを他のコンテナでマウントして使って下さい。

## 動作確認

````
docker volume inspect global
docker run --rm -v global:/global alpine touch /global/hoge
docker run --rm -v global:/global alpine ls /global
````

## アンインストール

global ボリュームを使用している全てのコンテナを停止してから行って下さい。

````
# nfs-client
docker volume rm --force global
sudo dpkg -r docker-volume-netshare
# nfs-server
sudo apt-get remove nfs-kernel-server
sudo rm -rf /exports/docker-global-volume
````

# 注意事項

* /etc/exports の更新で nfs-server をリスタートするので、ノード追加の際は多分スタックを全停止する必要があります。

* もしくは docker swarm join --availability=active,pause を巧みに使うことになります。

