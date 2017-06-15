FROM jutonz/k8s-playground-dev-ruby:6

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' \
 && wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add - \
 && apt-get update && apt-get install postgresql postgresql-contrib --yes \
&& rm -rf /var/lib/apt/lists/*

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.6/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.6/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf

WORKDIR /tmp

RUN service postgresql start \
  && sudo -u postgres psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" \
  && sudo -u postgres createdb -O docker docker \
  && service postgresql stop

COPY . /tmp/code
RUN service postgresql start \
  && echo "127.0.0.1 psql" >> /etc/hosts \
  && cd /tmp/code && bundle exec rake db:create db:migrate && rm -rf /tmp/code \
  && service postgresql stop

USER postgres
CMD ["/usr/lib/postgresql/9.6/bin/postgres", "--config-file=/etc/postgresql/9.6/main/postgresql.conf"]
