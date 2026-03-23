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
RUN pecl channel-update pecl.php.net \
    && pecl install redis-6.0.2 \
    && docker-php-ext-enable redis \
    && pecl install memcached-3.2.0 \
    && docker-php-ext-enable memcached \
    && pecl install mongodb-1.19.0 \
    && docker-php-ext-enable mongodb \
    # RdKafka 扩展
    && pecl install rdkafka-6.0.3 \
    && docker-php-ext-enable rdkafka \
    && rm -rf /tmp/pear

# 安装 Swoole（PHP 8.4 支持 swoole 5.1+）
RUN pecl install swoole-5.1.3 \
    && docker-php-ext-enable swoole \
    && rm -rf /tmp/pear

# 安装 Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

RUN mkdir -p /var/log/php /var/log/supervisor && chown www-data:www-data /var/log/php

WORKDIR /var/www/html

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
