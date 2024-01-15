# janus-docker

ビルド

```bash
sudo docker build -t janus-gateway .
```

ラン

```bash
sudo docker run -itd -p 8088:8088 -p 8089:8089 -p 8000:8000 -p 7088:7088 --name janus-gateway -d janus-gateway
```

http://localhost:8000