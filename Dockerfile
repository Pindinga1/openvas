FROM pindinga1/openvas:latest

COPY ./images/* /usr/local/share/gvm/gsad/web/img/
COPY ./scripts/entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]