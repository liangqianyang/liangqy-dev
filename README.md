# liangqy 本地开发环境

基于 Docker Compose 的一站式 PHP 开发环境。

## 包含服务

| 服务 | 镜像版本 | 端口 | 说明 |
|------|---------|------|------|
| Nginx | 1.27.4-alpine | 80 / 443 | Web 服务器 |
| MySQL | 9.0 | 3306 | 关系型数据库 |
| Redis | 7.2-alpine | 6379 | 缓存 / 队列 |
| PHP 7.4 | php:7.4-fpm | 9074 | 含 Swoole 4.8 |
| PHP 8.3 | php:8.3-fpm | 9083 | 含 Swoole 5.1 |
| PHP 8.4 | php:8.4-fpm | 9084 | 含 Swoole 5.1 |
| Elasticsearch | 8.13.0 | 9200 / 9300 | 搜索引擎 |
| Kibana | 8.13.0 | 5601 | ES 可视化客户端 |
| ClickHouse | 24.3 | 8123 / 9000 | 列式数据库 |

## 目录结构

```
liangqy-dev/
├── docker-compose.yml      # 主编排文件
├── .env                    # 环境变量（端口、密码等）
├── www/                    # 代码目录（挂载到所有 PHP 容器）
├── nginx/
│   ├── nginx.conf          # Nginx 主配置
│   ├── conf.d/             # 站点配置目录
│   │   └── default.conf    # 默认站点
│   ├── ssl/                # SSL 证书目录
│   └── logs/               # Nginx 日志
├── mysql/
│   ├── conf.d/my.cnf       # MySQL 自定义配置
│   ├── init/               # 初始化 SQL 脚本
│   └── logs/               # MySQL 日志
├── redis/
│   └── redis.conf          # Redis 配置
├── php/
│   ├── php74/
│   │   ├── Dockerfile      # PHP 7.4镜像构建
│   │   ├── php.ini         # PHP 配置
│   │   ├── php-fpm.conf    # FPM Pool 配置
│   │   └── extensions.ini  # 扩展配置（可热修改）
│   ├── php83/              # 同上，PHP 8.3
│   ├── php84/              # 同上，PHP 8.4
│   └── logs/               # PHP 日志（按版本分目录）
├── elasticsearch/
│   ├── elasticsearch.yml   # ES 配置
│   ├── jvm.options         # JVM 堆内存配置
│   └── kibana.yml          # Kibana 配置
└── clickhouse/
    ├── config.xml          # ClickHouse 主配置
    ├── users.xml           # 用户和权限配置
    └── conf.d/             # 自定义扩展配置目录
```

## 快速开始

### 1. 修改配置（可选）

编辑 `.env` 文件调整端口、密码等：

```bash
vim .env
```

### 2. 创建代码目录

```bash
mkdir -p www
```

### 3. 首次构建并启动

```bash
# 构建 PHP 镜像并启动所有服务
docker compose up -d --build

# 仅启动特定服务（避免等待 PHP 构建）
docker compose up -d nginx mysql redis
```

### 4. 查看服务状态

```bash
docker compose ps
docker compose logs -f [service_name]
```

### 5. 停止 / 删除容器（数据不会丢失）

```bash
docker compose down        # 停止并删除容器（数据保留）
docker compose down -v     # ⚠️ 同时删除 named volumes（数据会丢失）
```

---

## 常用操作

### 进入容器

```bash
docker exec -it dev-php83 bash
docker exec -it dev-mysql bash
docker exec -it dev-redis redis-cli -a redis123456
```

### PHP 版本切换

Nginx 站点配置中修改 `fastcgi_pass` 指向不同 PHP upstream：

```nginx
fastcgi_pass php74;   # PHP 7.4
fastcgi_pass php83;   # PHP 8.3
fastcgi_pass php84;   # PHP 8.4
```

### 添加新 PHP 扩展

**方法一：修改配置文件（已安装 SO 的扩展）**

编辑对应版本的 `php/phpXX/extensions.ini`，取消 `extension=xxx.so` 注释，重启容器：

```bash
docker compose restart php83
```

**方法二：Dockerfile 安装新 PECL 扩展**

在对应 Dockerfile 中追加：

```dockerfile
RUN pecl install yourextension && docker-php-ext-enable yourextension
```

重新构建：

```bash
docker compose build php83
docker compose up -d php83
```

### 新增 Nginx 站点

在 `nginx/conf.d/` 目录新建 `yoursite.conf`，参考 `default.conf` 格式，重启 Nginx：

```bash
docker compose restart nginx
```

### Elasticsearch 操作

```bash
# 查看集群健康
curl -u elastic:es123456 http://localhost:9200/_cluster/health?pretty

# 查看所有索引
curl -u elastic:es123456 http://localhost:9200/_cat/indices?v

# Kibana 浏览器访问
open http://localhost:5601
# 用户名: elastic  密码: es123456（见 .env）
```

### ClickHouse 操作

```bash
# HTTP 接口查询
curl http://localhost:8123/?query=SELECT+version()

# 进入 clickhouse-client
docker exec -it dev-clickhouse clickhouse-client --password clickhouse123456

# 查看数据库列表
docker exec -it dev-clickhouse clickhouse-client --password clickhouse123456 --query "SHOW DATABASES"
```

---

## 数据持久化说明

| 数据类型 | 存储方式 | 位置 |
|---------|---------|------|
| MySQL 数据 | Named Volume | `mysql-data` |
| Redis 数据 | Named Volume | `redis-data` |
| ES 数据 | Named Volume | `es-data` |
| ClickHouse 数据 | Named Volume | `clickhouse-data` |
| 各服务日志 | Bind Mount | 本地对应 `logs/` 目录 |
| 代码 | Bind Mount | `./www/` |

> Named Volume 数据存储在 Docker 管理目录下，不会因容器删除而丢失。
> 执行 `docker compose down -v` 才会删除 volumes，请谨慎操作。

---

## 网络说明

所有服务通过 `dev-network`（172.20.0.0/16）互相通信，容器间使用**服务名**作为主机名：

- MySQL: `mysql:3306`
- Redis: `redis:6379`
- PHP 7.4: `php74:9000`
- Elasticsearch: `elasticsearch:9200`
- ClickHouse: `clickhouse:8123`（HTTP）/ `clickhouse:9000`（TCP）

---

## 常见问题

**Q: ES 启动后 Kibana 无法连接？**  
A: Kibana 依赖 ES 健康检查，ES 初次启动较慢（1-2分钟），稍等后 `docker compose logs kibana` 查看状态。

**Q: PHP 构建时下载扩展很慢？**  
A: 可在 Dockerfile 中配置 PECL 镜像或使用国内网络代理。

**Q: MySQL 提示权限拒绝？**  
A: 检查 `mysql/logs/` 目录权限，或确认 `.env` 中密码配置与代码中一致。

**Q: ClickHouse 9000 端口与 ES TCP 端口冲突？**  
A: 默认 ClickHouse TCP 映射为宿主机 `9000`，ES TCP 映射为 `9300`，无冲突。若有冲突，在 `.env` 中修改 `CLICKHOUSE_TCP_PORT`。
