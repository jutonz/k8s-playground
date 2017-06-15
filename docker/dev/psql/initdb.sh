set -x

/usr/lib/postgresql/9.6/bin/initdb -D /var/lib/postgresql/data/ --encoding=utf8

chown -Rf postgres:postgres /var/lib/postgresql/data
chmod -R 700 /var/lib/postgresql/data

service postgresql start
psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';"
createdb -O docker docker

cd /tmp/code
PG_HOST=127.0.0.1 bundle exec rake db:create db:migrate

service postgresql stop
