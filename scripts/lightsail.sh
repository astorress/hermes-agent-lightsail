#!/bin/bash
set -euo pipefail

COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_BLUE=$(tput setaf 4)
COLOR_MAGENTA=$(tput setaf 5)
COLOR_DEFAULT=$(tput sgr0)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
SERVICE_PREFIX="hermes-agents"
KEY_FILE=~/.ssh/hermes-agents.lightsail.$REGION.pem
REMOTE_DIR=/opt/hermes
DASHBOARD_PORT=9119
SSH_OPTS=(-i "$KEY_FILE" -o StrictHostKeyChecking=accept-new -o LogLevel=ERROR)

step() { echo "${COLOR_MAGENTA}$1/$2:${COLOR_GREEN} $3${COLOR_DEFAULT}"; }
fail() { echo "${COLOR_RED}$1${COLOR_DEFAULT}" >&2; exit 1; }

ensure_key() {
  [ -f "$KEY_FILE" ] || REGION=$REGION bash "$ROOT/serverless/infrastructure/downloadSshKeyPair.sh"
}
public_ip() {
  aws ssm get-parameter --name "/$SERVICE_PREFIX/LightsailPublicIp" \
    --query 'Parameter.Value' --output text ||
    fail "Stack not found: deploy it first (npm run deploy-infra:dev)."
}
target() { ensure_key; echo "ubuntu@$(public_ip)"; }
hermes() { echo "docker exec ${1:-} -u hermes hermes hermes"; }

cmd="${1:-}"
case "$cmd" in
  key)
    REGION=$REGION bash "$ROOT/serverless/infrastructure/downloadSshKeyPair.sh"
    ;;
  ip)
    public_ip
    ;;
  myip)
    echo "$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')/32"
    ;;
  deploy)
    STEPS=5
    step 1 $STEPS "Rendering ${COLOR_BLUE}app/.env${COLOR_GREEN} from app/env.template."
    # BEDROCK_AWS_* keeps the deployer's AWS_* from reaching the server.
    creds="$(aws secretsmanager get-secret-value --secret-id "/$SERVICE_PREFIX/BedrockCredentials" \
      --query SecretString --output text)" ||
      fail "Bedrock credentials not found: deploy the stack first (npm run deploy-infra:<stage>)."
    export BEDROCK_AWS_ACCESS_KEY_ID="$(jq -r .access_key_id <<< "$creds")"
    export BEDROCK_AWS_SECRET_ACCESS_KEY="$(jq -r .secret_access_key <<< "$creds")"
    export BEDROCK_AWS_REGION="$(jq -r .region <<< "$creds")"
    MODEL="${BEDROCK_MODEL_ID:-us.anthropic.claude-haiku-5-5}"
    bash "$ROOT/app/env.sh"
    trap 'rm -f "$ROOT/app/.env"' EXIT
    grep -q '^AWS_ACCESS_KEY_ID=' "$ROOT/app/.env" || fail "The Bedrock secret has no access key."
    if grep -q '^TELEGRAM_BOT_TOKEN=' "$ROOT/app/.env" &&
      ! grep -q '^TELEGRAM_ALLOWED_USERS=' "$ROOT/app/.env"; then
      fail "TELEGRAM_ALLOWED_USERS is required with a bot token: the agent has shell access."
    fi

    step 2 $STEPS "Checking the instance."
    host="$(target)"
    ssh "${SSH_OPTS[@]}" "$host" "test -f $REMOTE_DIR/.bootstrapped" ||
      fail "The instance is still bootstrapping (cloud-init). Retry in a few minutes."

    release="$(date -u +%Y%m%d%H%M%S)"
    step 3 $STEPS "Uploading release ${COLOR_BLUE}$release${COLOR_GREEN}."
    COPYFILE_DISABLE=1 tar -C "$ROOT/app" --exclude=env.sh --exclude=env.template \
      --exclude=.gitignore -czf - . |
      ssh "${SSH_OPTS[@]}" "$host" "mkdir -p $REMOTE_DIR/releases/$release && tar -xzf - -C $REMOTE_DIR/releases/$release && chmod 600 $REMOTE_DIR/releases/$release/.env"

    step 4 $STEPS "Building and starting the containers."
    ssh "${SSH_OPTS[@]}" "$host" "cd $REMOTE_DIR/releases/$release && docker compose up -d --build && ln -sfn $REMOTE_DIR/releases/$release $REMOTE_DIR/current && ls -1dt $REMOTE_DIR/releases/* | tail -n +4 | xargs -r rm -rf"
    sleep 10
    ssh "${SSH_OPTS[@]}" "$host" "$(hermes) config set model.provider bedrock && $(hermes) config set model.default '$MODEL' && $(hermes) config set bedrock.region '$BEDROCK_AWS_REGION'" ||
      echo "WARN: could not set the Bedrock model; run: npm run model (choose AWS Bedrock, $MODEL)" >&2

    # Replaces the whole `skills.external_dirs` list; /opt/skills is the only one used.
    ssh "${SSH_OPTS[@]}" "$host" "$(hermes) config set skills.external_dirs '[\"/opt/skills\"]'" ||
      echo "WARN: could not set skills.external_dirs; add '/opt/skills' under skills.external_dirs in /opt/hermes/data/config.yaml" >&2

    step 5 $STEPS "Checking the gateway."
    sleep 10
    ssh "${SSH_OPTS[@]}" "$host" "docker inspect -f '{{.State.Status}}' hermes | grep -qx running" ||
      { ssh "${SSH_OPTS[@]}" "$host" "docker logs --tail 50 hermes" || true; fail "The gateway is not running. Fix it and deploy again, or: npm run rollback"; }
    echo "${COLOR_GREEN}Deployed release $release.${COLOR_DEFAULT}"
    ;;
  rollback)
    host="$(target)"
    ssh "${SSH_OPTS[@]}" "$host" "set -e; prev=\$(ls -1dt $REMOTE_DIR/releases/* | sed -n 2p); [ -n \"\$prev\" ] || { echo 'No previous release.'; exit 1; }; cd \$prev && docker compose up -d --build && ln -sfn \$prev $REMOTE_DIR/current && echo \"Rolled back to \$prev\""
    ;;
  releases)
    ssh "${SSH_OPTS[@]}" "$(target)" "ls -1dt $REMOTE_DIR/releases/*; echo current: \$(readlink $REMOTE_DIR/current)"
    ;;
  status)
    ssh "${SSH_OPTS[@]}" "$(target)" "cd $REMOTE_DIR/current && docker compose ps && $(hermes) gateway status || true"
    ;;
  logs)
    exec ssh "${SSH_OPTS[@]}" "$(target)" "cd $REMOTE_DIR/current && docker compose logs -f --tail 100 gateway"
    ;;
  chat)
    exec ssh "${SSH_OPTS[@]}" -t "$(target)" "$(hermes -it)"
    ;;
  model)
    exec ssh "${SSH_OPTS[@]}" -t "$(target)" "$(hermes -it) model"
    ;;
  ssh)
    exec ssh "${SSH_OPTS[@]}" "$(target)"
    ;;
  tunnel)
    echo "Dashboard on http://localhost:$DASHBOARD_PORT (Ctrl-C to close)"
    echo "From the dev container, forward that port in VS Code (Ports tab) to use it on your Mac."
    exec ssh "${SSH_OPTS[@]}" -N -L "$DASHBOARD_PORT:127.0.0.1:$DASHBOARD_PORT" "$(target)"
    ;;
  token)
    # The dashboard embeds its session token in its page; it changes on every restart.
    ssh "${SSH_OPTS[@]}" "$(target)" "curl -fsS http://127.0.0.1:$DASHBOARD_PORT/" |
      sed -n 's/.*__HERMES_SESSION_TOKEN__="\([^"]*\)".*/\1/p' | grep . ||
      fail "Session token not found: is the dashboard up? (npm run status)"
    ;;
  *)
    echo "usage: $0 deploy|rollback|releases|status|logs|chat|model|ssh|tunnel|token|ip|key|myip" >&2
    exit 2
    ;;
esac
