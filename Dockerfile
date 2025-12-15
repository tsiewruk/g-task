# syntax=docker/dockerfile:1

# ======================================
# Stage 1: Base (system + PHP extensions)
# ======================================
FROM php:8.3-apache AS base

# Install system dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev libonig-dev libxml2-dev libzip-dev \
    git curl netcat-traditional zip unzip \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install -j$(nproc) pdo pdo_mysql mbstring exif pcntl bcmath opcache

# Install Redis
RUN --mount=type=cache,target=/tmp/pear \
    pecl install redis-6.0.2 && docker-php-ext-enable redis

# Configure Apache
RUN a2enmod rewrite headers expires deflate \
    && sed -i 's!/var/www/html!/var/www/html/src!g' /etc/apache2/sites-available/000-default.conf

COPY docker/apache/apache2.conf /etc/apache2/apache2.conf
COPY docker/apache/security.conf /etc/apache2/conf-available/security.conf

ENV APACHE_DOCUMENT_ROOT=/var/www/html/src
WORKDIR /var/www/html

# ======================================
# Stage 2: Composer dependencies (production)
# ======================================
FROM base AS composer-deps

COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer
COPY composer.json composer.lock* ./

RUN --mount=type=cache,target=/root/.composer \
    composer install --no-dev --no-scripts --no-interaction --prefer-dist --optimize-autoloader

# ======================================
# Stage 3: Composer dependencies (dev) - inherits from prod
# ======================================
FROM composer-deps AS composer-deps-dev

RUN --mount=type=cache,target=/root/.composer \
    composer install --no-scripts --no-interaction --prefer-dist --optimize-autoloader

# ======================================
# Stage 4: Production
# ======================================
FROM base AS production

# Copy production PHP config
COPY docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Copy entrypoint
COPY docker/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy vendor and app code
COPY --from=composer-deps --chown=www-data:www-data /var/www/html/vendor ./vendor
COPY --chown=www-data:www-data ./src ./src

RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]

# ======================================
# Stage 5: Development (with Xdebug)
# ======================================
FROM base AS development

# Install Xdebug
RUN --mount=type=cache,target=/tmp/pear \
    pecl install xdebug-3.3.1 && docker-php-ext-enable xdebug

# Install Composer for runtime
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy development PHP config
COPY docker/php/php-dev.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Copy entrypoint
COPY docker/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy vendor with dev dependencies
COPY --from=composer-deps-dev --chown=www-data:www-data /var/www/html/vendor ./vendor

# Copy app code
COPY --chown=www-data:www-data ./src ./src

RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
