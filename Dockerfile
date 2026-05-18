FROM caddy:latest

WORKDIR /app

COPY Caddyfile ./

COPY entrypoint.sh ./

RUN caddy fmt --overwrite Caddyfile
RUN chmod 755 entrypoint.sh

ENTRYPOINT ["/bin/sh"]

CMD ["entrypoint.sh"]
