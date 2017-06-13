FROM ubuntu:16.04

RUN DEBIAN_FRONTEND="noninteractive" \
&& apt-get update -y && apt-get install -y \
  software-properties-common \
  wget \
  locales \
&& rm -rf /var/lib/apt/lists/*

USER root
ENV HOME /root
WORKDIR /root

# Configure locale
RUN locale-gen en_US.utf8 && update-locale LANG=en_US.utf8 LC_ALL=en_US.utf8

# Common stuff which is unlikely to change
RUN export DEBIAN_FRONTEND="noninteractive" \
&& apt-get update -y && apt-get install -y \
  build-essential \
  vim \
  git \
  curl \
  libcurl3 \
  libcurl3-gnutls \
  libcurl4-openssl-dev \
  libsqlite3-dev \
  libmagic-dev \
  graphviz \
  python-pip \
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  sysv-rc-conf \
  libyaml-dev \
  python-dev \
  python3-dev \
  htop \
  sudo \
  libpq-dev \
&& rm -rf /var/lib/apt/lists/*
