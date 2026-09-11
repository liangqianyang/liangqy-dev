# ============================================================
# PHP 8.4 FPM
# 包含：核心扩展、常用扩展、Swoole
# ============================================================
FROM php:8.4-fpm

LABEL maintainer="liangqy"
LABEL php.version="8.4"

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 更换 Debian 镜像源
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
    sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list 2>/dev/null || true

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        curl \
        wget \
        unzip \
        zip \
        vim \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libxpm-dev \
        libzip-dev \
        libicu-dev \
        libxml2-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        libmemcached-dev \
        librdkafka-dev \
        libonig-dev \
        libxslt-dev \
        libgmp-dev \
        libbz2-dev \
        libsodium-dev \
        autoconf \
        g++ \
        make \
        supervisor \
    && rm -rf /var/lib/apt/lists/*

# 安装 PHP 核心扩展
# 注意：PHP 8.4 移除了 imap、xmlrpc 等扩展
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-xpm \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        bz2 \
        calendar \
        exif \
        ftp \
        gd \
        gettext \
        gmp \
        iconv \
        intl \
        mbstring \
        mysqli \
        opcache \
        pcntl \
        pdo \
        pdo_mysql \
        shmop \
        simplexml \
        soap \
        sockets \
        sodium \
        sysvmsg \
        sysvsem \
        sysvshm \
        xml \
        xsl \
        zip

# 安装 PECL 扩展
# 说明：国内服务器直连 pecl.php.net 偶发超时/重置，pecl 单次请求失败会报
# "does not have REST info xml available"。改为 curl --retry 下载源码包后
# 从本地 tgz 安装（不依赖 REST 接口），并拆分 RUN 层：重试时只需重跑失败的扩展
RUN pecl channel-update pecl.php.net || true

RUN curl -fsSL --connect-timeout 15 --retry 5 --retry-all-errors --retry-delay 3 \
        -o /tmp/redis.tgz https://pecl.php.net/get/redis-6.1.0.tgz \
    && pecl install /tmp/redis.tgz \
    && docker-php-ext-enable redis \
    && rm -f /tmp/redis.tgz

RUN curl -fsSL --connect-timeout 15 --retry 5 --retry-all-errors --retry-delay 3 \
        -o /tmp/memcached.tgz https://pecl.php.net/get/memcached-3.2.0.tgz \
    && pecl install /tmp/memcached.tgz \
    && docker-php-ext-enable memcached \
    && rm -f /tmp/memcached.tgz

RUN curl -fsSL --connect-timeout 15 --retry 5 --retry-all-errors --retry-delay 3 \
        -o /tmp/mongodb.tgz https://pecl.php.net/get/mongodb-1.20.0.tgz \
    && pecl install /tmp/mongodb.tgz \
    && docker-php-ext-enable mongodb \
    && rm -f /tmp/mongodb.tgz

# RdKafka 扩展
RUN curl -fsSL --connect-timeout 15 --retry 5 --retry-all-errors --retry-delay 3 \
        -o /tmp/rdkafka.tgz https://pecl.php.net/get/rdkafka-6.0.3.tgz \
    && pecl install /tmp/rdkafka.tgz \
    && docker-php-ext-enable rdkafka \
    && rm -f /tmp/rdkafka.tgz && rm -rf /tmp/pear

# 安装 Swoole（PHP 8.4 需要 swoole 6.0+，6.x 才正式支持 PHP 8.4）
# -D 传入编译期选项，开启 openssl(SWOOLE_SSL)/sockets/http2/mysqlnd 支持
# 只需 SSL 时删掉其余选项即可
RUN pecl install -D 'enable-sockets="yes" enable-openssl="yes" enable-http2="yes" enable-mysqlnd="yes"' swoole-6.0.0 \
    && docker-php-ext-enable swoole \
    && rm -rf /tmp/pear

# 安装 Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

RUN mkdir -p /var/log/php /var/log/supervisor && chown www-data:www-data /var/log/php

WORKDIR /var/www/html

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
