# global ボリュームの作成

docker swarm init か docker swarm join したあとに以下のスクリプトを実行すると、

'global' と名前の付いた nfs ボリューム (オーバーノードなボリューム) を作成できます。

推奨動作環境は ubuntu 16.04。(apt-get 利用につき)

## nfs サーバとして global ボリュームを作成

````
curl -sSL https://raw.githubusercontent.com/nunun/docker-volume-global/master/install.sh | sudo sh
````

※ nfs サーバとして動作させる場合は、そのノードが swarm manager である必要があります。
また、/etc/exports を容赦なく上書きします。

## nfs クライアントとして global ボリュームを作成

````
curl -sSL https://raw.githubusercontent.com/nunun/docker-volume-global/master/install.sh | sudo sh -s <server-ip>
````

## 動作確認

````
docker run --rm -v global:/global alpine touch /global/hoge
docker run --rm -v global:/global alpine ls /global
````
