FROM ubuntu:xenial
MAINTAINER ian@phpb.com

ENV DOCKER_GITLAB_IMAGE_VERSION=9.0.0-rc4
ENV GITLAB_VERSION=9.0.0-rc4 \
    RUBY_VERSION=2.3 \
    GOLANG_VERSION=1.8 \
    GITLAB_SHELL_VERSION=5.0.0 \
    GITLAB_WORKHORSE_VERSION=1.4.1 \
    GITLAB_PAGES_VERSION=0.4.0 \
    GITLAB_MONITOR_VERSION=1.2.0 \
    GITLAB_GITALY_VERSION=0.3.0 \
    GITLAB_USER="git" \
    GITLAB_HOME="/home/git" \
    GITLAB_LOG_DIR="/var/log/gitlab" \
    GITLAB_CACHE_DIR="/etc/docker-gitlab" \
    RAILS_ENV=production \
    DEBIAN_FRONTEND=noninteractive

ENV GITLAB_INSTALL_DIR="${GITLAB_HOME}/gitlab" \
    GITLAB_SHELL_INSTALL_DIR="${GITLAB_HOME}/gitlab-shell" \
    GITLAB_WORKHORSE_INSTALL_DIR="${GITLAB_HOME}/gitlab-workhorse" \
    GITLAB_PAGES_INSTALL_DIR="${GITLAB_HOME}/gitlab-pages" \
    GITLAB_MONITOR_INSTALL_DIR="${GITLAB_HOME}/gitlab-monitor" \
    GITLAB_GITALY_INSTALL_DIR="${GITLAB_HOME}/gitaly" \
    GITLAB_DATA_DIR="${GITLAB_HOME}/data" \
    GITLAB_BUILD_DIR="${GITLAB_CACHE_DIR}/build" \
    GITLAB_RUNTIME_DIR="${GITLAB_CACHE_DIR}/runtime"

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG http_proxy
ARG https_proxy

RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends \
 && echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends \
 && apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    net-tools \
    sudo \
    unzip \
    vim.tiny \
    wget

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E1DD270288B4E6030699E45FA1715D88E1DF1F24 \
 && echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6 \
 && echo "deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu xenial main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B3981E7A6852F782CC4951600A6F0A3C300EE8C \
 && echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu xenial main" >> /etc/apt/sources.list \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
 && wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
 && echo 'deb https://deb.nodesource.com/node_7.x xenial main' > /etc/apt/sources.list.d/nodesource.list \
 && apt-get update \
 && apt-get -yy upgrade

RUN apt-get install -y \
    curl \
    gettext-base \
    git-core \
    libpq5 \
    libyaml-0-2 \
    libssl1.0.0 \
    libgdbm3 \
    libreadline6 \
    libncurses5 \
    libffi6 \
    libkrb5-3 \
    libxml2 \
    libxslt1.1 \
    libcurl3 \
    libicu55 \
    logrotate \
    locales \
    nginx \
    nodejs \
    openssh-server \
    postgresql-client \
    python2.7 \
    python-docutils \
    redis-tools \
    ruby${RUBY_VERSION} \
    supervisor \
    zlib1g \
 && rm -rf /var/lib/apt/lists/*

RUN update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && locale-gen en_US.UTF-8 \
 && dpkg-reconfigure locales

RUN gem install bundler --no-ri --no-rdoc

COPY assets/build/ ${GITLAB_BUILD_DIR}/
RUN bash ${GITLAB_BUILD_DIR}/install.sh

COPY assets/runtime/ ${GITLAB_RUNTIME_DIR}/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 22/tcp 80/tcp 443/tcp

VOLUME ["${GITLAB_DATA_DIR}", "${GITLAB_LOG_DIR}"]
WORKDIR ${GITLAB_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
