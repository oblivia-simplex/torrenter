#! /usr/bin/env bash

mkdir -p /av/.transmission/{config,downloads,watch,vpn,logs,av}
chown -R miles:av /av/.transmission/

docker container run -d \
  --name=torrenter \
  --device /dev/net/tun \
  --cap-add=NET_ADMIN \
  --cap-add=MKNOD \
  --cap-add=NET_BROADCAST \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  -e PUID=2000 \
  -e PGID=1001 \
  -e TZ=Etc/UTC \
  -p 9091:9091 \
  -p 8080:8080 \
  -p 8080:8080/udp \
  -p 51413:51413 \
  -p 51413:51413/udp \
  -v /av/.transmission/config:/config \
  -v /av/.transmission/downloads:/downloads \
  -v /av/.transmission/watch:/watch \
  -v /av/.transmission/vpn:/vpn \
  -v /av/.transmission/logs:/logs \
  -v /av/TV:/av/TV \
  -v /av/Movies:/av/Movies \
  -v /av/Music:/av/Music \
  -v /av/Comics:/av/Comics \
  -v /av/Audiobooks:/av/Audiobooks \
  --restart unless-stopped \
  torrenter:latest
