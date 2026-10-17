# Integrations — hermes-agent-lightsail

| Integration                              | Protocol                                                                | Direction                 | Auth                                                                                                                                                                      | Code                                                                                              | If unavailable                                                        |
| ---------------------------------------- | ----------------------------------------------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Telegram                                 | HTTPS long polling to the Bot API (no webhook, no open port)            | outbound (`gateway`)      | `TELEGRAM_BOT_TOKEN`; only `TELEGRAM_ALLOWED_USERS` may talk to the agent                                                                                                 | `app/docker-compose.yml`, `app/env.template`                                                      | the agent cannot be reached from Telegram; `chat` still works         |
| LLM provider (Amazon Bedrock)            | HTTPS API (Bedrock Converse)                                            | outbound (`gateway`)      | IAM user of `iam.yml`; its key is in Secrets Manager and ships as `AWS_*` in `app/.env`. The account must have accepted the model's Marketplace agreement (else HTTP 403) | `serverless/infrastructure/{iam,secrets-manager}.yml`, `app/env.template`, `scripts/lightsail.sh` | the agent answers with an error                                       |
| Hermes dashboard / Hermes Desktop        | HTTP on `127.0.0.1:9119`, reached with an SSH tunnel (`npm run tunnel`) | inbound (loopback only)   | session token created at dashboard start (`npm run token`; changes on every restart); verified on the server, not yet from the desktop app                                | `app/docker-compose.yml` (`dashboard`), `scripts/lightsail.sh tunnel`                             | no Desktop; Telegram and `chat` still work                            |
| SSH to the instance                      | SSH, TCP 22 from `ALLOWED_SSH_CIDR` (empty = any IPv4, PoC)             | inbound (deploy, ops)     | Lightsail default key pair of the region, downloaded to `~/.ssh/hermes-agents.lightsail.<region>.pem` in the dev container (`downloadSshKeyPair.sh`; the host's `~/.ssh-hermes` is mounted there)                                                                             | `scripts/lightsail.sh`, `serverless/infrastructure/lightsail.yml`                                 | no deploy or ops until the CIDR / key is fixed                        |
| SSM Parameter Store                      | AWS SDK / CLI                                                           | outbound (`lightsail.sh`) | IAM user of `.envs/aws.env`                                                                                                                                               | `serverless/infrastructure/ssm.yml`, `scripts/lightsail.sh`                                       | `Stack not found: deploy it first`                                    |
| Lightsail / CloudFormation / S3          | CloudFormation via Serverless Framework v4                              | outbound (`sls`)          | IAM user + `SERVERLESS_ACCESS_KEY`                                                                                                                                        | `serverless/infrastructure/*`                                                                     | no infrastructure changes                                             |
| Docker Hub (`nousresearch/hermes-agent`) | image pull on the instance                                              | outbound (instance)       | none                                                                                                                                                                      | `app/Dockerfile`                                                                                  | `docker compose up --build` fails; the previous release keeps running |

## Contracts to keep stable

- **Only SSH is exposed.** Telegram is outbound and the dashboard stays on loopback. Opening
  anything else (for example Hermes' `API_SERVER_*`) needs TLS + a key and an explicit port in
  `lightsail.yml`.
- **Secrets you write travel only in `app/.env`** (0600, rendered by `app/env.sh`, deleted locally on exit).
  Never in CloudFormation, `user-data.sh` or `serverless.yml`. The Bedrock key is the exception: CloudFormation creates it and stores it in Secrets Manager; `deploy` reads it from there.
- **A channel with a token requires its allowlist** (`deploy` refuses otherwise); never use
  `*_ALLOW_ALL_USERS`: the agent has a shell.
- **`app/env.template` variables** must be defined in `.envs/config.env`; empty ones are dropped.

## Telegram setup (the PoC channel)

1. In Telegram, **@BotFather** → `/newbot` → copy the token.
2. **@userinfobot** gives the owner's **numeric ID** (not the username).
3. `.envs/config.env`: `TELEGRAM_BOT_TOKEN=...` and `TELEGRAM_ALLOWED_USERS=<id>` (several, comma-separated). Rebuild the dev container to reload the environment.
4. `npm run deploy-app:dev`, then message the bot. If it does not answer: `npm run logs`.

The gateway uses long polling: no webhook, no port to open. In groups, BotFather's privacy mode is on by default (the bot only sees commands and replies). Only the IDs in `TELEGRAM_ALLOWED_USERS` can use the agent. What Hermes answers to anyone else (ignore or pairing code) is not verified: test it from another account.

