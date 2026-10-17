#!/bin/bash
# Downloads the region's Lightsail default key pair. Run by the deploy:finalize hook and `npm run key`.

COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_BLUE=$(tput setaf 4)
COLOR_MAGENTA=$(tput setaf 5)
COLOR_DEFAULT=$(tput sgr0)

REGION=${REGION:-${AWS_DEFAULT_REGION:-us-east-1}}
KEY_FILE_NAME=~/.ssh/hermes-agents.lightsail.$REGION.pem
STEP=1
STEP_COUNT=2

echo "${COLOR_MAGENTA}${STEP}/$STEP_COUNT:${COLOR_GREEN} Getting Lightsail default key pair of ${COLOR_BLUE}$REGION${COLOR_GREEN}...${COLOR_DEFAULT}"
mkdir -p ~/.ssh
if aws lightsail download-default-key-pair --region $REGION --query privateKeyBase64 --output text > $KEY_FILE_NAME.tmp \
    && [ -s $KEY_FILE_NAME.tmp ] && ! grep -q '^None$' $KEY_FILE_NAME.tmp; then
    mv $KEY_FILE_NAME.tmp $KEY_FILE_NAME
    echo "${COLOR_MAGENTA}${STEP}/$STEP_COUNT:${COLOR_GREEN} Generated ${COLOR_BLUE}$KEY_FILE_NAME${COLOR_GREEN} file.${COLOR_DEFAULT}"
else
    rm -f $KEY_FILE_NAME.tmp
    echo "${COLOR_MAGENTA}${STEP}/$STEP_COUNT:${COLOR_RED} Something went wrong getting the default key pair. Skipping further action.${COLOR_DEFAULT}"
    exit 1
fi
let STEP++

chmod 600 $KEY_FILE_NAME
echo "${COLOR_MAGENTA}${STEP}/$STEP_COUNT:${COLOR_GREEN} Set permissions to ${COLOR_BLUE}$KEY_FILE_NAME${COLOR_GREEN} file.${COLOR_DEFAULT}"
