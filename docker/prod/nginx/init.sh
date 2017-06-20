set -x
set -e

touch /var/log/nginx/k8s.access.log

service nginx start

tail -f /var/log/nginx/k8s.access.log
