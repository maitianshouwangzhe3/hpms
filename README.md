# hpms
基于C/lua实现的高性能服务器

## 项目架构
![](./source/hpms.png "架构图")

## 编译
```
git submodule init
make linux
```
## 运行
```
// server
hpms example/echo-srv.lua
// client
hpms example/echo-cli.lua
```

## 性能测试