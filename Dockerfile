# Generic SuiteCRM 8.10.x image — pinned, not floating :latest
# Publish: docker.io/markriggins/suitecrm:8.10.1
ARG SUITECRM_VERSION=8.10.1
ARG PHP_VERSION=8.3

FROM php:${PHP_VERSION}-apache-bookworm

ARG SUITECRM_VERSION
ENV SUITECRM_VERSION=${SUITECRM_VERSION} \
    APACHE_DOCUMENT_ROOT=/var/www/html/public \
    SUITECRM_APP_ROOT=/var/www/html

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip rsync \
      libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
      libzip-dev libicu-dev libxml2-dev libonig-dev \
      libcurl4-openssl-dev \
      cron \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
      gd mysqli pdo_mysql zip intl soap bcmath opcache \
    && a2enmod rewrite headers \
    && rm -rf /var/lib/apt/lists/*

RUN { \
      echo 'memory_limit=512M'; \
      echo 'upload_max_filesize=64M'; \
      echo 'post_max_size=64M'; \
      echo 'max_execution_time=300'; \
      echo 'date.timezone=UTC'; \
    } > /usr/local/etc/php/conf.d/suitecrm.ini

# Official pre-built package (not -dev)
WORKDIR /opt/suitecrm-seed
RUN set -eux; \
    curl -fsSL -o /tmp/suitecrm.zip \
      "https://github.com/SuiteCRM/SuiteCRM-Core/releases/download/v${SUITECRM_VERSION}/SuiteCRM-${SUITECRM_VERSION}.zip"; \
    unzip -q /tmp/suitecrm.zip -d /tmp/suitecrm-extract; \
    if [ -d "/tmp/suitecrm-extract/SuiteCRM-${SUITECRM_VERSION}" ]; then \
      cp -a "/tmp/suitecrm-extract/SuiteCRM-${SUITECRM_VERSION}/." /opt/suitecrm-seed/; \
    elif [ "$(find /tmp/suitecrm-extract -mindepth 1 -maxdepth 1 -type d | wc -l)" = "1" ]; then \
      cp -a "$(find /tmp/suitecrm-extract -mindepth 1 -maxdepth 1 -type d | head -1)"/. /opt/suitecrm-seed/; \
    else \
      cp -a /tmp/suitecrm-extract/. /opt/suitecrm-seed/; \
    fi; \
    rm -rf /tmp/suitecrm.zip /tmp/suitecrm-extract; \
    test -f /opt/suitecrm-seed/bin/console; \
    test -d /opt/suitecrm-seed/public; \
    echo "${SUITECRM_VERSION}" > /opt/suitecrm-seed/.suitecrm-version

COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf
COPY docker-entrypoint.sh /usr/local/bin/suitecrm-entrypoint.sh
RUN chmod +x /usr/local/bin/suitecrm-entrypoint.sh

WORKDIR /var/www/html
VOLUME ["/var/www/html"]
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/suitecrm-entrypoint.sh"]
CMD ["apache2-foreground"]
