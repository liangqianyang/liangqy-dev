-- 初始化脚本（容器首次启动时自动执行）
-- 可在此添加初始数据库、用户授权等操作

-- 创建开发用数据库（如在 .env 中已通过 MYSQL_DATABASE 创建则无需重复）
-- CREATE DATABASE IF NOT EXISTS `another_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 授权开发用户访问所有数据库（仅限本地开发，生产环境请收紧权限）
GRANT ALL PRIVILEGES ON *.* TO 'developer'@'%';
FLUSH PRIVILEGES;
