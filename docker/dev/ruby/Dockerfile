FROM jutonz/k8s-playground-dev-base:5

# Install ruby
RUN export DEBIAN_FRONTEND="noninteractive" \
  && apt-add-repository ppa:brightbox/ruby-ng \
  && apt-get update -y && apt-get install -y --force-yes \
    ruby2.4 \
    ruby2.4-dev \
    nodejs \
&& rm -rf /var/lib/apt/lists/* \
&& echo "gem: --no-document > $HOME/.gemrc" \
&& gem install bundler --no-document

# Install gems
COPY Gemfile Gemfile.lock /tmp/
RUN bundle --gemfile /tmp/Gemfile
