ARG WP_CLI_IMAGE=wordpress:cli
FROM $WP_CLI_IMAGE as cli

FROM debian:jessie-slim

COPY etc/apt/apt.conf.d/no-install-suggests-recommends.apt.conf /etc/apt/apt.conf.d/
COPY etc/apt/apt.conf.d/disable-validity-check.apt.conf /etc/apt/apt.conf.d/
COPY etc/apt/sources.list.d/jessie-backports.list /etc/apt/sources.list.d/
RUN apt-get update \
	&& apt-get install -y php5-cli php5-fpm php5-curl php5-mysql php5-gd php5-mcrypt ssmtp sudo less mysql-client gosu \
	&& find /var/cache/apt /var/lib/apt -type f -delete \
	&& mkdir -p /run/php \
	&& true

COPY --from=cli /usr/local/bin/wp /usr/local/bin/wp
COPY php-cli.ini /etc/php5/cli/conf.d/99-docker.conf
COPY php-fpm-pool-www.conf /etc/php5/fpm/pool.d/zz-www.conf
COPY scripts/adjust-user scripts/adjust-term scripts/entrypoint scripts/exec /usr/local/share/container/scripts/
COPY entrypoint/php /usr/local/share/container/entrypoint/
COPY bin/container-user bin/local-user /usr/local/share/container/bin/

ENV CONTAINER_USER www-data
ENV CONTAINER_GROUP www-data

EXPOSE 9000
ENTRYPOINT ["/usr/local/share/container/scripts/entrypoint"]
CMD ["/usr/sbin/php5-fpm", "-F"]
