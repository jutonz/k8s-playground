FROM nginx:1.13

COPY docker/prod/nginx/default.conf /etc/nginx/sites-available/default
COPY docker/prod/nginx/nginx.conf /etc/nginx/nginx.conf

# TODO setup letsencrypt

CMD "nginx"
