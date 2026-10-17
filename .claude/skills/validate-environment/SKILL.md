---
name: validate-environment
description: Quick pre-deploy check for hermes-agent-lightsail in a given stage — container and env variable names, local format/spell and read-only AWS checks. Use before giving the owner a deploy command; for a full review use the deploy-validator agent.
---

# Validate the environment before deploying hermes-agent-lightsail

All read-only. Run inside the container (never print secret values):

```bash
docker compose -f .docker/docker-compose.yml up -d     # from hermes-agent-lightsail/, if not running
docker exec HermesAgent sh -c "env | grep -E '^(ALLOWED_SSH_CIDR|SNAPSHOT_TIME_UTC|BEDROCK_MODEL_ID|HERMES_IMAGE_TAG|EXTRA_APT_PACKAGES|TELEGRAM_ALLOWED_USERS|AWS_DEFAULT_REGION)='"
docker exec HermesAgent sh -c 'for v in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY SERVERLESS_ACCESS_KEY TELEGRAM_BOT_TOKEN; do [ -n "$(printenv $v)" ] && echo "$v is set" || echo "$v MISSING"; done'
```

`node_modules/` must exist (`.docker/entrypoint.sh` runs `npm install` when the devcontainer
opens). The LLM is Bedrock and needs no key in `.envs` (credentials come from Secrets Manager after `deploy-infra`). A Telegram token requires `TELEGRAM_ALLOWED_USERS`.

## 1. Local

```bash
docker exec HermesAgent sh -c "cd /app && npm run format:check && npm run spell"
docker exec HermesAgent sh -c "cd /app/serverless/infrastructure && sls print --stage <stage> >/dev/null"  # uses the container's config.env
docker build app   # on the host, from hermes-agent-lightsail/: the dev container has no Docker CLI
```

## 2. Account

```bash
aws sts get-caller-identity --query Arn --output text
aws iam list-account-aliases --query 'AccountAliases[0]' --output text   # must be the stage's account
aws bedrock get-foundation-model-availability --model-id "${BEDROCK_MODEL_ID#us.}" --query agreementAvailability.status --output text  # must be AVAILABLE
aws ssm get-parameter --name /hermes-agents/LightsailPublicIp --query Parameter.Value --output text || echo "infra not deployed"
```

## 3. Report

- Missing keys → the owner fills `.envs/config.env` and rebuilds the container.
- IP changed (only if `ALLOWED_SSH_CIDR` is set) → `npm run myip`, update it, `npm run deploy-infra:dev`.
- Give: `npm run deploy-infra:dev` (if infra not deployed or changed) then `npm run deploy-app:dev`.
