FROM jutonz/k8s-playground-dev-ruby:6

WORKDIR /root/code
COPY . ./
RUN rm -r tmp/

CMD ["bundle", "exec", "rails", "server"]
