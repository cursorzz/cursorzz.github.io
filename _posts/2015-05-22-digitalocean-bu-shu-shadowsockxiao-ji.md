---
layout: page
title: "digitalocean 部署shadowsock小记"
date: 2015-05-22
summary: |
tags: digitalocean shadowsock 翻墙
---

前段时间买了一个digital ocean的私有云用来搭建rails的服务, 突然想到能不能把它用来翻墙呢. 看了几个方案, 最后觉得shadowsock 的方案还是最简单的. 记一下shadowsock的安装方式

##On Digital Ocean

我的vps环境是ubuntu, 所以直接

```bash
apt-get install python-pip
pip install shadowsocks
```

创建一个showsocks的配置文件

```json
{
    "server":"你的服务器ip地址",
    "server_port":8388,
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"你设置的密码",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": false
}
```

然后起起来就行

```bash
ssserver -c /etc/shadowsocks.json

# in backgroud
ssserver -c /etc/shadowsocks.json -d start
ssserver -c /etc/shadowsocks.json -d stop
```

到此为止服务器上就设置好啦

### Client

客户端就更简单啦, 因为我的是mac, 所以到 [shadowsocks](http://sourceforge.net/projects/shadowsocksgui/) 下一个就好, 配置ip指向vps的ip, 设置相同的密码就可以happy了







