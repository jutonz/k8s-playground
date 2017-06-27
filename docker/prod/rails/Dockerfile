FROM jutonz/k8s-playground-dev-ruby:8

WORKDIR /root/code
COPY . ./
RUN rm -r tmp/

COPY docker/prod/rails/init.sh /etc/
CMD ["/bin/bash", "-c", "/etc/init.sh"]
