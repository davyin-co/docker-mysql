# 介绍
基于[官方dockerfile](https://github.com/docker-library/mysql/blob/master/8.4/Dockerfile.oracle)改造，适配oraclelinux:8 .

## 原因：
- 官方镜像在MySQL 8.4.0版本之后，都是基于oraclelinux:9进行构建，但是在一些硬件比较老的机器上，会遇到CPU兼容性问题，使用oraclelinux:8构建的镜像可以正常运行。

相关报错信息为：
`Fatal glibc error: CPu does not support x86-64-v2`

## 改动了什么？
1. 基础镜像由oraclelinux:9-slim改为oraclelinux:8-slim
2. 修改镜像安装包，从community version获取，而不是官方的docker minimal docker版本。