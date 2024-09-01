# Use Ubuntu as the base image
FROM ubuntu:24.04

# Set environment variables to ensure non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory for the container
WORKDIR /var/www/html/xng.xngage.pimcorev11/

# Update package lists and install prerequisites
RUN apt-get update && apt-get install -y software-properties-common curl gnupg2 \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update && apt-get install -y \
    apache2 php8.2-fpm libapache2-mod-php8.2 php8.2-mbstring php8.2-curl php8.2-gd \
    php8.2-soap php8.2-intl php8.2-pgsql php8.2-mysql php8.2-mcrypt php8.2-ldap \
    php8.2-bcmath php8.2-xml php8.2-zip php8.2-mongodb php8.2-odbc unzip \
    && apt-get install -y nodejs \
    && apt-get install -y apache2-utils ssl-cert \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure no MPM module conflicts exist, then enable mpm_prefork (or mpm_event/worker as needed)
# RUN a2dismod mpm_event mpm_worker mpm_prefork || true \
# RUN   a2enmod mpm_prefork  # or mpm_event or mpm_worker as needed
# RUN   a2enmod mpm_event
# RUN   a2enmod mpm_worker


# Enable Apache modules and PHP-FPM configuration
RUN a2enmod rewrite ssl proxy_fcgi setenvif \
    && a2enconf php8.2-fpm

# Set PHP memory limit
RUN echo "memory_limit = 2048M" >> /etc/php/8.2/apache2/php.ini

# Copy application files
COPY . /var/www/html/xng.xngage.pimcorev11/

# Copy and extract configuration files
COPY ./dockersettings.zip /tmp/
RUN unzip /tmp/dockersettings.zip -d /tmp/ && \
    cp -r /tmp/sites-available/* /etc/apache2/sites-available/ \
    # && cp -r /tmp/sites-enabled/* /etc/apache2/sites-enabled/ \
    && cp /tmp/apache2.conf /etc/apache2/apache2.conf \
    && cp /tmp/ports.conf /etc/apache2/ports.conf \
# && cp /tmp/mods-available/* /etc/apache2/mods-available/ \
    && rm -rf /tmp/dockersettings.zip /tmp/*

# Set permissions for web files
RUN chown -R www-data:www-data /var/www/html/xng.xngage.pimcorev11/public

# Enable site configuration and disable default
RUN a2ensite xngage.conf && a2dissite 000-default.conf
# RUN service apache2 restart || apache2ctl restart

# Expose ports for HTTP and HTTPS
EXPOSE 80 

# Add a health check to monitor Apache service
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Run Apache in the foreground to keep the container running
CMD ["apache2ctl", "-D", "FOREGROUND"]
