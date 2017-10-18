FROM php:7.1.9-alpine

ENV BUILD_DEPS \
                cmake \
                autoconf \
                g++ \
                gcc \
                make \
                pcre-dev \
                openssl-dev
ENV REDIS_VERSION 3.1.3
ENV IGBINARY_VERSION 2.0.4
ENV CFLAGS "-O3"
ENV CPPFLAGS "-O3"
ENV CXXFLAGS "-O3"

RUN apk update && apk add --no-cache --virtual .build-deps $BUILD_DEPS \
    && apk add --no-cache git libstdc++

# Install XDebug
RUN pecl install xdebug \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable xdebug \
    && php -m | grep xdebug

# Install igbinary
RUN pecl install gender \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable gender \
    && php -m | grep gender

# Install composer
WORKDIR /tmp
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

# Install igbinary
RUN pecl install igbinary-$IGBINARY_VERSION \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable igbinary \
    && php -m | grep igbinary

# Install redis driver
RUN mkdir -p /tmp/pear \
    && cd /tmp/pear \
    && pecl bundle redis-$REDIS_VERSION \
    && cd redis \
    && phpize . \
    && ./configure --enable-redis-igbinary \
    && make \
    && make install \
    && cd ~ \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis \
    && php -m | grep redis

# Install libcld2
WORKDIR /usr/local
RUN git clone https://github.com/CLD2Owners/cld2 libcld2 \
    && cd libcld2/internal \
    && ./compile_libs.sh

# Install cld2-php-ext
WORKDIR /tmp
RUN git clone https://github.com/fntlnz/cld2-php-ext.git -b php7-support cld2-php-ext \
    && cd cld2-php-ext \
    && phpize . \
    && ./configure --with-cld2=/usr/local/libcld2 \
    && make \
    && make install \
    && cd ~ \
    && rm -rf /tmp/cld2-php-ext \
    && docker-php-ext-enable cld2 \
    && php -m | grep cld2


# Remove builddeps
RUN apk del .build-deps

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php", "-a"]