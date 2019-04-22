FROM debian:jessie-slim

COPY no-install-suggests-recommends.apt.conf /etc/apt/apt.conf.d
RUN apt-get update \
	&& apt-get install -y php5-cli php5-fpm php5-curl php5-mysql php5-gd ssmtp sudo less mysql-client \
	&& find /var/cache/apt /var/lib/apt -type f -delete \
	&& mkdir -p /run/php \
	&& true

COPY --from=wordpress:cli /usr/local/bin/wp /usr/local/bin/wp
COPY etc/php5/cli/conf.d/php-cli.ini /etc/php5/cli/conf.d/99-docker.conf
COPY php-fpm-pool-www.conf /etc/php5/fpm/pool.d/zz-www.conf
COPY scripts/adjust-user scripts/adjust-term scripts/entrypoint scripts/exec /usr/local/share/container/scripts/
COPY entrypoint/php /usr/local/share/container/entrypoint/
COPY bin/wp /usr/local/share/container/bin/

ENV CONTAINER_USER www-data
ENV CONTAINER_GROUP www-data

EXPOSE 9000
ENTRYPOINT ["/usr/local/share/container/scripts/entrypoint", "php"]
CMD ["/usr/sbin/php5-fpm", "-F"]
