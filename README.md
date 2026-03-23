# liangqy 本地开发环境

基于 Docker Compose 的一站式 PHP 开发环境。

## 包含服务

| 服务 | 镜像版本 | 宿主机端口 | 说明 |
|------|---------|-----------|------|
| Nginx | 1.27.4-alpine | 80 / 443 | Web 服务器 |
| MySQL | 9.0 | 3306 | 关系型数据库 |
| Redis | 7.2-alpine | 6379 | 缓存 / 消息队列 |
| PHP 7.4 | php:7.4-fpm | 9074 | Swoole 4.8 / rdkafka / Composer / Supervisor |
| PHP 8.3 | php:8.3-fpm | 9083 | Swoole 5.1 / rdkafka / Composer / Supervisor |
| PHP 8.4 | php:8.4-fpm | 9084 | Swoole 5.1 / rdkafka / Composer / Supervisor |
| Elasticsearch | 8.13.0 | 9200 / 9300 | 搜索引擎 |
| Kibana | 8.13.0 | 5601 | ES 可视化客户端 |
| ClickHouse | 24.3 | 8123 / 9000 | 列式数据库 |
| Kafka | 3.7 (KRaft) | 19092 | 消息队列（无 Zookeeper） |
| Kafka UI | latest | 8080 | Kafka 可视化管理界面 |

## 目录结构

```
liangqy-dev/
├── docker-compose.yml      # 主编排文件
├── .env                    # 环境变量（端口、密码等，不提交 Git）
├── .env.example            # 环境变量示例（提交 Git）
├── .gitignore
├── www/                    # 代码目录（挂载到所有 PHP 容器）
├── nginx/
│   ├── nginx.conf          # Nginx 主配置
│   ├── conf.d/             # 站点配置目录
│   │   └── default.conf    # 默认站点（含多版本切换示例）
│   ├── ssl/                # SSL 证书目录
│   └── logs/               # Nginx 日志
├── mysql/
│   ├── conf.d/my.cnf       # MySQL 自定义配置
│   ├── init/               # 初始化 SQL 脚本（首次启动自动执行）
│   └── logs/               # MySQL 日志
├── redis/
│   └── redis.conf          # Redis 配置（含 AOF 持久化）
├── php/
│   ├── php74/
│   │   ├── Dockerfile      # PHP 7.4 镜像构建
│   │   ├── php.ini         # PHP 配置
│   │   ├── php-fpm.conf    # FPM Pool 配置
│   │   ├── extensions.ini  # 扩展参数配置（热修改，重启生效）
│   │   └── supervisord.conf# Supervisor 进程配置（热修改，重启生效）
│   ├── php83/              # 同上，PHP 8.3
│   ├── php84/              # 同上，PHP 8.4
│   └── logs/               # PHP 日志（php74 / php83 / php84 子目录）
├── elasticsearch/
│   ├── elasticsearch.yml   # ES 配置
│   ├── jvm.options         # JVM 堆内存配置
│   ├── kibana.yml          # Kibana 配置
│   └── logs/               # ES 日志
├── clickhouse/
│   ├── config.xml          # ClickHouse 主配置
│   ├── users.xml           # 用户和权限配置
│   └── conf.d/             # 自定义扩展配置目录
└── kafka/
    ├── kafka.env           # Kafka 全部配置（热修改，重启生效）
    └── logs/               # Kafka 日志
```

## 快速开始

### 1. 初始化配置

```bash
cp .env.example .env
vim .env   # 按需修改端口、密码等
```

### 2. 首次构建并启动

```bash
# 构建 PHP 镜像（含所有扩展）并启动全部服务
docker compose up -d --build

# 仅启动基础服务（跳过 PHP 构建等待）
docker compose up -d nginx mysql redis
```

### 3. 查看服务状态

```bash
docker compose ps
docker compose logs -f [service_name]
```

### 4. 停止 / 删除容器

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
docker exec -it dev-kafka bash
```

### PHP 版本切换

Nginx 站点配置中修改 `fastcgi_pass` 指向不同 PHP upstream：

```nginx
fastcgi_pass php74;   # PHP 7.4
fastcgi_pass php83;   # PHP 8.3
fastcgi_pass php84;   # PHP 8.4
```

### 添加新 PHP 扩展

**方法一：修改 `extensions.ini`（调整已安装扩展的参数，无需重建）**

编辑 `php/phpXX/extensions.ini`，修改参数后重启容器：

```bash
docker compose restart php83
```

**方法二：安装新 PECL 扩展（需重新构建镜像）**

在对应版本的 `Dockerfile` 中追加安装命令：

```dockerfile
RUN pecl install yourextension && docker-php-ext-enable yourextension
```

```bash
docker compose build php83 && docker compose up -d php83
```

### 管理后台进程（Supervisor）

每个 PHP 容器由 Supervisor 管理，`php-fpm` 作为主进程运行。

**新增后台进程**（如 Laravel Queue Worker），编辑对应版本的 `supervisord.conf`，追加 `[program:xxx]` 段，重启容器即生效：

```bash
docker compose restart php83
```

**查看进程状态：**

```bash
docker exec -it dev-php83 supervisorctl status
```

### Composer

Composer 2.x 已内置于所有 PHP 容器：

```bash
docker exec -it dev-php83 composer install -d /var/www/html/your-project
docker exec -it dev-php83 bash -c "cd /var/www/html/your-project && composer require package/name"
```

### 新增 Nginx 站点

在 `nginx/conf.d/` 目录新建 `yoursite.conf`（参考 `default.conf`），重载 Nginx：

```bash
docker compose restart nginx
```

### Elasticsearch 操作

```bash
# 查看集群健康
curl -u elastic:es123456 http://localhost:9200/_cluster/health?pretty

# 查看所有索引
curl -u elastic:es123456 http://localhost:9200/_cat/indices?v

# Kibana 可视化界面
open http://localhost:5601
# 账号: elastic  密码: 见 .env 中 ES_PASSWORD
```

### Kafka 操作

```bash
# 查看所有 Topic
docker exec -it dev-kafka kafka-topics.sh --bootstrap-server localhost:9092 --list

# 创建 Topic
docker exec -it dev-kafka kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create --topic my-topic \
  --partitions 3 --replication-factor 1

# 生产消息（测试）
docker exec -it dev-kafka kafka-console-producer.sh \
  --bootstrap-server localhost:9092 --topic my-topic

# 消费消息（测试）
docker exec -it dev-kafka kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 --topic my-topic --from-beginning

# Kafka UI 可视化界面
open http://localhost:8080
```

**PHP 中连接 Kafka（rdkafka 扩展）：**

```php
// 容器内通过服务名访问
$conf = new RdKafka\Conf();
$conf->set('metadata.broker.list', 'kafka:9092');

// 宿主机脚本访问
$conf->set('metadata.broker.list', 'localhost:19092');
```

**修改 Kafka 配置：** 编辑 `kafka/kafka.env`，重启容器生效：

```bash
docker compose restart kafka
```

### ClickHouse 操作

```bash
# HTTP 接口查询
curl http://localhost:8123/?query=SELECT+version()

# 进入 clickhouse-client
docker exec -it dev-clickhouse clickhouse-client --password clickhouse123456

# 查看数据库列表
docker exec -it dev-clickhouse clickhouse-client \
  --password clickhouse123456 --query "SHOW DATABASES"
```

---

## 数据持久化说明

| 数据 | 存储方式 | 位置 |
|------|---------|------|
| MySQL 数据 | Named Volume | `mysql-data` |
| Redis 数据 | Named Volume | `redis-data` |
| ES 数据 | Named Volume | `es-data` |
| ClickHouse 数据 | Named Volume | `clickhouse-data` |
| Kafka 消息数据 | Named Volume | `kafka-data` |
| 各服务日志 | Bind Mount | 本地对应 `logs/` 目录 |
| 代码 | Bind Mount | `./www/` |

> Named Volume 不会因 `docker compose down` 而删除，执行 `docker compose down -v` 才会清除，请谨慎操作。

---

## 容器内网络（服务名访问）

所有服务通过 `dev-network`（172.20.0.0/16）互联，容器间使用**服务名**作为主机名：

| 服务 | 容器内地址 |
|------|-----------|
| MySQL | `mysql:3306` |
| Redis | `redis:6379` |
| PHP 7.4 | `php74:9000` |
| PHP 8.3 | `php83:9000` |
| PHP 8.4 | `php84:9000` |
| Elasticsearch | `elasticsearch:9200` |
| ClickHouse (HTTP) | `clickhouse:8123` |
| ClickHouse (TCP) | `clickhouse:9000` |
| Kafka | `kafka:9092` |

---

## 常见问题

**Q: ES 启动后 Kibana 无法连接？**  
A: Kibana 依赖 ES 健康检查，ES 初次启动较慢（约 1-2 分钟），稍等后查看日志：`docker compose logs -f kibana`

**Q: Kafka UI 显示无法连接集群？**  
A: Kafka 首次启动需要约 30 秒完成 KRaft 初始化，等待后刷新页面即可。

**Q: PHP 构建时 PECL 安装扩展很慢？**  
A: 可在宿主机配置 HTTP 代理，或修改 Dockerfile 使用国内镜像。

**Q: MySQL 提示权限拒绝？**  
A: 确认 `.env` 中密码与代码配置一致，或执行 `docker compose logs mysql` 查看报错详情。

**Q: ClickHouse TCP 端口 9000 与其他服务冲突？**  
A: 默认 ClickHouse 宿主机 TCP 端口为 `9000`，ES TCP 为 `9300`，Kafka 外部端口为 `19092`，无冲突。如需调整，修改 `.env` 中对应变量后重启服务。
