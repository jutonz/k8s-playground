FROM jutonz/k8s-playground/dev/base

# Ruby
RUN export DEBIAN_FRONTEND="noninteractive" \
  && apt-add-repository ppa:brightbox/ruby-ng \
  && apt-get update -y && apt-get install -y --force-yes \
    ruby2.4 \
    ruby2.4-dev \
&& rm -rf /var/lib/apt/lists/* \
&& echo "gem: --no-document > $HOME/.gemrc" \
&& gem install bundler --no-document
