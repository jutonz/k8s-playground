#FROM postgres:9.6-alpine

#RUN apk --update add ruby && gem install bundler thor --no-document

#COPY . /root/code/
#RUN /root/code/bin/rake db:setup && rm -r /root/code

FROM jutonz/k8s-playground-dev-ruby

COPY . /tmp/
RUN cd /tmp && ./bin/rake db:setup && rm -r code
