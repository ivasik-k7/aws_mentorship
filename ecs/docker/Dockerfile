FROM nginx:1.25-alpine as builder

RUN apk add --no-cache curl

RUN rm -rf /etc/nginx/conf.d/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/

RUN adduser -D -u 1000 -g nginx nginxuser && \
    mkdir -p /var/cache/nginx /var/run/nginx && \
    chown -R nginxuser:nginx /var/cache/nginx /var/log/nginx /var/run/nginx && \
    chmod -R 775 /var/cache/nginx /var/run/nginx

FROM nginx:1.25-alpine

COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/share/nginx/html /usr/share/nginx/html
COPY --from=builder /var/cache/nginx /var/cache/nginx
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

RUN mkdir -p /var/run/nginx /var/log/nginx && \
    chown -R nginxuser:nginx /var/cache/nginx /var/log/nginx /var/run/nginx && \
    chmod -R 775 /var/cache/nginx /var/run/nginx && \
    touch /var/log/nginx/access.log /var/log/nginx/error.log && \
    chown nginxuser:nginx /var/log/nginx/access.log /var/log/nginx/error.log

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
    CMD curl -f http://localhost/ || exit 1

# USER nginxuser

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]