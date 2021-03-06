FROM jutonz/k8s-playground-dev-ruby:8

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' \
 && wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add - \
 && apt-get update && apt-get install postgresql postgresql-contrib --yes \
&& rm -rf /var/lib/apt/lists/*

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.6/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.6/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf
#RUN echo "data_directory = '/var/lib/postgresql/data'" >> /etc/postgresql/9.6/main/postgresql.conf

RUN mkdir -p /var/lib/postgresql/data && chown -R postgres /var/lib/postgresql
RUN mkdir -p /var/run/postgresql/9.6-main.pg_stat_tmp && chown -R postgres /var/run/postgresql/9.6-main.pg_stat_tmp
RUN usermod -aG sudo postgres

COPY . /tmp/code
WORKDIR /tmp/code
RUN service postgresql start \
 && sudo -u postgres psql -c "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" \
 && PG_HOST=localhost bundle exec rails db:create db:migrate \
 && service postgresql stop

COPY docker/dev/psql/initdb.sh docker/dev/psql/startdb.sh /etc/
RUN chmod +x /etc/initdb.sh && chown postgres:postgres /etc/initdb.sh
RUN chmod +x /etc/startdb.sh && chown postgres:postgres /etc/startdb.sh

CMD ["/bin/bash", "-c", "/etc/startdb.sh"]
