# Official Hermes image plus EXTRA_APT_PACKAGES, built on the server.
# Keep the base's ENTRYPOINT/CMD/USER: s6-overlay prepares /opt/data and drops privileges.
ARG HERMES_IMAGE_TAG=stable
FROM nousresearch/hermes-agent:${HERMES_IMAGE_TAG}

ARG EXTRA_APT_PACKAGES="git jq curl unzip"
RUN if [ -n "${EXTRA_APT_PACKAGES}" ]; then \
      apt-get -o Acquire::Retries=3 update \
      && apt-get -o Acquire::Retries=3 install -y --no-install-recommends ${EXTRA_APT_PACKAGES} \
      && rm -rf /var/lib/apt/lists/*; \
    fi

LABEL org.opencontainers.image.title="hermes-agent" \
      org.opencontainers.image.description="Hermes Agent on AWS Lightsail" \
      org.opencontainers.image.base.name="docker.io/nousresearch/hermes-agent"
