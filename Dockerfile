# syntax=docker/dockerfile:1

# ======================================
# Stage 1: Base Image - Common dependencies
# ======================================
FROM php:8.3-apache AS base

# Metadata
LABEL maintainer="recruitment@example.com"
LABEL description="PHP 8.3 Apache with PDO MySQL and Redis - Production Ready"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    netcat-traditional \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    opcache

# Install Redis extension via PECL
RUN pecl install redis-6.0.2 \
    && docker-php-ext-enable redis

# Enable Apache modules
RUN a2enmod rewrite headers expires deflate

# Configure Apache
RUN sed -i 's!/var/www/html!/var/www/html/src!g' /etc/apache2/sites-available/000-default.conf
ENV APACHE_DOCUMENT_ROOT=/var/www/html/src

# Copy custom Apache configuration
COPY docker/apache/apache2.conf /etc/apache2/apache2.conf
COPY docker/apache/security.conf /etc/apache2/conf-available/security.conf

# Set working directory
WORKDIR /var/www/html

# ======================================
# Stage 2: Composer Dependencies
# ======================================
FROM base AS composer-build

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy composer files
COPY composer.json composer.lock* ./

# Install dependencies (production mode)
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

# ======================================
# Stage 3: Production Image
# ======================================
FROM base AS production

# Copy application code
COPY --chown=www-data:www-data . /var/www/html

# Copy vendor from composer-build stage
COPY --from=composer-build --chown=www-data:www-data /var/www/html/vendor /var/www/html/vendor

# Copy production PHP configuration
COPY docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Create startup script to load environment variables
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Expose port
EXPOSE 80

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]

# ======================================
# Stage 4: Development Image (with Xdebug)
# ======================================
FROM base AS development

# Install Xdebug
RUN pecl install xdebug-3.3.1 \
    && docker-php-ext-enable xdebug

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy application code
COPY --chown=www-data:www-data . /var/www/html

# Install ALL dependencies (including dev)
RUN composer install \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

# Copy development PHP configuration
COPY docker/php/php-dev.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Create startup script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port
EXPOSE 80

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
