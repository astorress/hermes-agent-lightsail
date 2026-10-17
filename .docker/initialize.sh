#!/bin/bash
# Runs on the host before the dev container is created (initializeCommand).

COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_BLUE=$(tput setaf 4)
COLOR_MAGENTA=$(tput setaf 5)
COLOR_DEFAULT=$(tput sgr0)

EXEC_PATH=$(dirname $(readlink -f "$0"))
HOME_PATH=$EXEC_PATH/..
ENVS_PATH=$HOME_PATH/.envs
STEP=1
STEP_COUNT=1

# docker compose fails if an env_file is missing
for ENV_NAME in aws sls config; do
  if [ ! -f "$ENVS_PATH/$ENV_NAME.env" ]; then
    echo "${COLOR_YELLOW}WARNING: ${COLOR_BLUE}.envs/$ENV_NAME.env${COLOR_YELLOW} does not exist: create it (variables in the README glossary) before opening the container.${COLOR_DEFAULT}"
  fi
done
echo "${COLOR_MAGENTA}${STEP}/$STEP_COUNT:${COLOR_GREEN} Checked ${COLOR_BLUE}.envs${COLOR_GREEN} files.${COLOR_DEFAULT}"
