# docker-nfs-volume

ノードを超えてデータを共有できる、'nfs' と名前の付いた docker volume を作成するインストールスクリプトです。

docker swarm init, docker swarm join でノードを全登録したあとに以下のスクリプトを実行する感じで運用。

nfs + netshare plugin を利用、動作環境は ubuntu。

* docker volume netshare plugin
  * https://github.com/ContainX/docker-volume-netshare


## nfs サーバとして 'nfs' ボリュームをインストール

````
curl -sSL https://raw.githubusercontent.com/nunun/docker-nfs-volume/master/install.sh | sudo sh
````

ノードに nfs-server と netshare plugin をインストールし、/etc/exports を作成して nfs-server をリスタートします。

全て終わると nfs ボリュームができるので、このボリュームを他のコンテナでマウントして使って下さい。

nfs マウントを docker swarm 内のノードに制限するため、nfs サーバとなるノードは swarm manager でなければなりません。

また、swarm に新しくノードを追加する場合は、追加後にもう一度コマンドを叩いて /etc/exports を更新する必要があります。


## nfs クライアントとして 'nfs' ボリュームをインストール

````
curl -sSL https://raw.githubusercontent.com/nunun/docker-nfs-volume/master/install.sh | sudo sh -s <nfs-server ip>
````

ノードに netshare plugin をインストールします。

全て終わると nfs ボリュームができるので、このボリュームを他のコンテナでマウントして使って下さい。


## 既存の nfs サーバに接続する

既存の nfs サーバから 'nfs' ボリュームを作りたい場合は以下のようにします。

````
curl -sSL https://raw.githubusercontent.com/nunun/docker-nfs-volume/master/install.sh | sudo sh -s <nfs-server ip> <export path>

例)
curl -sSL https://raw.githubusercontent.com/nunun/docker-nfs-volume/master/install.sh | sudo sh -s 192.0.2.10 /exports/nfs
````

nfs サーバの /etc/exports の設定例は以下の通り。

````
/exports/nfs 192.0.2.100(rw,sync,no_subtree_check,no_root_squash)
````

## 動作確認

````
docker volume inspect nfs
docker run --rm -v nfs:/nfs alpine touch /nfs/hoge
docker run --rm -v nfs:/nfs alpine ls    /nfs
````


## アンインストール

nfs ボリュームを使用している全てのコンテナを停止してから行って下さい。

````
# nfs-client
docker volume rm --force nfs
sudo dpkg -r docker-volume-netshare
# nfs-server
sudo apt-get remove nfs-kernel-server
sudo rm -rf /exports/docker-nfs-volume
````

# 注意事項

* /etc/exports の更新で nfs-server をリスタートするので、ノード追加の際は多分スタックを全停止する必要があります。

* もしくは docker swarm join --availability=active,pause を巧みに使うことになります。

