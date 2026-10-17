######## BASE IMAGE ########
FROM python:3.13-slim-bookworm AS python-base
FROM node:24-bookworm-slim AS img-base

# Arguments
ARG USER=hermes
ARG USER_HOME=/home/$USER
ARG VOLUME=/app
ARG SHELL=/bin/bash

COPY --from=python-base /usr/local/ /usr/local/
RUN ldconfig
RUN pip3 install --upgrade pip

RUN apt-get update
RUN npm install -g npm

# Inital OS configuration
RUN apt-get install -y locales \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen
RUN apt-get install -y sudo lsb-release git git-lfs curl zip unzip jq gettext openssh-client less

# Install VSCode extensions dependencies
RUN pip3 install cfn-lint cfn-lint-serverless
RUN npm install -g @anthropic-ai/claude-code \
    && node "$(npm root -g)/@anthropic-ai/claude-code/install.cjs" \
    && claude --version

# Install CLI utilities
RUN case "$(dpkg --print-architecture)" in \
        "amd64") AWSCLI_ARCH="x86_64" ;; \
        "arm64"|"aarch64") AWSCLI_ARCH="aarch64" ;; \
        *) echo "Unsupported architecture" && exit 1 ;; \
    esac; \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install Serverless framework
RUN npm install -g serverless

# Set up non root user
RUN echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN useradd -ms $SHELL $USER
RUN mkdir -p $VOLUME \
    && chown -R $USER:$USER $VOLUME

# SSH folder (docker-compose.yml mounts ~/.ssh-hermes here: keeps the Lightsail key between rebuilds)
RUN mkdir -p $USER_HOME/.ssh \
    && chmod 700 $USER_HOME/.ssh \
    && chown -R $USER:$USER $USER_HOME/.ssh

# Preserve bash history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && echo $SNIPPET >> "/root/.bashrc" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USER /commandhistory \
    && echo $SNIPPET >> "$USER_HOME/.bashrc"

# Lets the non-root user update global npm packages
RUN chown -R $USER:$USER /usr/local/lib/node_modules /usr/local/bin


######## HERMES AGENT DEV IMAGE ########
FROM img-base AS img-hermes

USER $USER
