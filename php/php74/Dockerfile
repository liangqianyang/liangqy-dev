# ============================================================
# PHP 7.4 FPM
# 包含：核心扩展、常用扩展、Swoole
# ============================================================
FROM php:7.4-fpm

# 维护者信息
LABEL maintainer="liangqy"
LABEL php.version="7.4"

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 更换 Debian 镜像源（加速）
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list || true

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
        libc-client-dev \
        libkrb5-dev \
        libmemcached-dev \
        librdkafka-dev \
        libonig-dev \
        libxslt-dev \
        libgmp-dev \
        libbz2-dev \
        libsodium-dev \
        libev-dev \
        autoconf \
        g++ \
        make \
        supervisor \
    && rm -rf /var/lib/apt/lists/*

# 安装 PHP 核心扩展（docker-php-ext-install 方式）
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-xpm \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
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
        imap \
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
        tokenizer \
        xml \
        xmlrpc \
        xsl \
        zip

# 安装 PECL 扩展
RUN pecl channel-update pecl.php.net \
    # Redis 扩展
    && pecl install redis-5.3.7 \
    && docker-php-ext-enable redis \
    # Memcached 扩展
    && pecl install memcached-3.2.0 \
    && docker-php-ext-enable memcached \
    # MongoDB 扩展
    && pecl install mongodb-1.16.2 \
    && docker-php-ext-enable mongodb \
    # RdKafka 扩展（librdkafka-dev 已在系统依赖中安装）
    && pecl install rdkafka-6.0.3 \
    && docker-php-ext-enable rdkafka \
    # Imagick 扩展（需 imagemagick 库）
    # && pecl install imagick && docker-php-ext-enable imagick \
    && rm -rf /tmp/pear

# 安装 Swoole（PHP 7.4 对应 swoole 4.8.x 最后稳定版）
RUN pecl install swoole-4.8.13 \
    && docker-php-ext-enable swoole \
    && rm -rf /tmp/pear

# 安装 Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# 创建日志目录
RUN mkdir -p /var/log/php /var/log/supervisor && chown www-data:www-data /var/log/php

WORKDIR /var/www/html

EXPOSE 9000

# 使用 supervisord 管理进程（supervisord.conf 通过 volume 挂载）
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
