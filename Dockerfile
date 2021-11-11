FROM debian:11-slim

ARG GIT_CONFIG_FILE
RUN set -x \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    openssl \
    rsync \
    git \
    diffutils \
    ssh \
    jq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN set -x \
  && groupadd --gid 1000 git \
  && useradd --uid 1000 --gid git --shell /bin/bash --create-home git

USER git
