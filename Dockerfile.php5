ARG VERSION=latest
ARG IMAGE_PREFIX=docker.brainfood.com/shared
ARG WP_CLI_IMAGE=wordpress:cli
FROM $WP_CLI_IMAGE as wordpress-cli

FROM $IMAGE_PREFIX/jessie-slim-base:$VERSION AS image-base

RUN true \
	&& ulimit -n 2048 \
	&& apt-get update \
	&& apt-get install -y php5-cli php5-fpm php5-curl php5-mysql php5-gd php5-mcrypt less mysql-client \
	&& find /var/cache/apt /var/lib/apt -type f -delete \
	&& mkdir -p /run/php \
	&& true

FROM $IMAGE_PREFIX/jessie-slim-script:$VERSION AS script-base

COPY --from=wordpress-cli /usr/local/bin/wp /usr/local/bin/wp
COPY php-cli.ini /etc/php5/cli/conf.d/99-docker.conf
COPY php-fpm-pool-www.conf /etc/php5/fpm/pool.d/zz-www.conf
COPY entrypoint/php /usr/local/share/container/entrypoint/

ENV CONTAINER_USER www-data
ENV CONTAINER_GROUP www-data

EXPOSE 9000
ENTRYPOINT ["/usr/local/share/container/scripts/entrypoint"]
CMD ["/usr/sbin/php5-fpm", "-F"]

FROM image-base AS final-output
COPY --from=script-base / /
