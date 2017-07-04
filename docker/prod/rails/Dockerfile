FROM jutonz/k8s-playground-dev-ruby:9

WORKDIR /root/code
COPY . ./
RUN rm -r tmp/

COPY docker/prod/rails/init.sh /etc/
CMD ["/bin/bash", "-c", "/etc/init.sh"]
