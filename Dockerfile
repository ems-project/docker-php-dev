ARG VERSION_ARG=""

FROM docker.io/elasticms/base-php-fpm:${VERSION_ARG}

ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

LABEL eu.elasticms.base-php-dev.build-date=$BUILD_DATE_ARG \
      eu.elasticms.base-php-dev.name="" \
      eu.elasticms.base-php-dev.description="" \
      eu.elasticms.base-php-dev.url="https://hub.docker.com/repository/docker/elasticms/base-php-dev" \
      eu.elasticms.base-php-dev.vcs-ref=$VCS_REF_ARG \
      eu.elasticms.base-php-dev.vcs-url="https://github.com/ems-project/base-php-dev" \
      eu.elasticms.base-php-dev.vendor="sebastian.molle@gmail.com" \
      eu.elasticms.base-php-dev.version="$VERSION_ARG" \
      eu.elasticms.base-php-dev.release="$RELEASE_ARG" \
      eu.elasticms.base-php-dev.schema-version="1.0" 

USER root

ENV HOME=/home/default \
    PATH=/opt/bin:/usr/local/bin:/usr/bin:$PATH

RUN echo "Install and Configure required extra PHP packages ..." \
    && apk add --update --no-cache --virtual .build-deps $PHPIZE_DEPS autoconf \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
       | tr ',' '\n' \
       | sort -u \
       | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
       )" \
    && apk add --virtual .php-dev-phpext-rundeps $runDeps \
    && apk add --virtual .php-dev-rundeps npm \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
    && echo "Download and install Composer ..." \
    && curl -sSfLk https://getcomposer.org/installer -o /tmp/composer-setup.php \
    && curl -sSfLk https://composer.github.io/installer.sig -o /tmp/composer-setup.sig \
    && COMPOSER_INSTALLER_SHA384SUM=$(cat /tmp/composer-setup.sig) \
    && echo "$COMPOSER_INSTALLER_SHA384SUM /tmp/composer-setup.php" | sha384sum -c \
    && php /tmp/composer-setup.php --disable-tls --install-dir=/usr/local/bin \
    && rm /tmp/composer-setup.php /tmp/composer-setup.sig \
    && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer.phar /usr/local/bin/composer \
    && mkdir /home/default/.composer \
    && chown 1001:0 /home/default/.composer \
    && chmod -R ug+rw /home/default/.composer \
    && echo "Install NPM ..." \
    && apk --update add npm \
    && rm -rf /var/cache/apk/* /home/default/.composer \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chown -Rf 1001:0 /home/default \
    && chmod -R ug+rw /home/default \
    && find /home/default -type d -exec chmod ug+x {} \; 

USER 1001

ENTRYPOINT ["container-entrypoint"]

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD bash -c '[ -S /var/run/php-fpm/php-fpm.sock ]'

CMD ["php-fpm", "-F", "-R"]
