# Dependencies — hermes-agent-lightsail

## Nothing is read from other projects

`hermes-agent-lightsail` is standalone: it creates its own Lightsail instance, static IP, firewall, snapshot and SSM
parameters. It imports nothing from other stacks or folders of the repository.

## Deploy order

**`serverless/infrastructure` → `app/`**: the app release is uploaded over SSH to the instance the
stack created, and `scripts/lightsail.sh` finds that instance through SSM. If the SSM parameter
`/hermes-agents/LightsailPublicIp` does not exist, the infrastructure is not deployed.

| Parameter                                                     | Published by                            | Read by                |
| ------------------------------------------------------------- | --------------------------------------- | ---------------------- |
| `/hermes-agents/LightsailPublicIp`                            | `serverless/infrastructure` (`ssm.yml`) | `scripts/lightsail.sh` |
| `/hermes-agents/LightsailInstanceName`                        | `serverless/infrastructure` (`ssm.yml`) | nothing yet            |

## Node dependencies (`package.json`)

`devDependencies`: `serverless-deployment-bucket` (S3 bucket for the CloudFormation template, per
stage), `@serverless/safeguards-plugin` (`allowed-stages`, `allowed-regions`, `framework-version`),
`serverless-scriptable-plugin` (the `deploy:finalize` hook that downloads the SSH key), `prettier`,
`cspell` + `@cspell/dict-es-es`. Plugins are local to the project; the Dockerfile installs only the
`serverless` CLI globally. `package-lock.json` is committed.

## Dev container (`.docker/Dockerfile`)

`python:3.13` + `node:24` base, AWS CLI v2, `serverless`, `cfn-lint` + `cfn-lint-serverless`, Claude
Code, `git`, `git-lfs`, `jq`, `gettext` (envsubst, used by `app/env.sh`), `openssh-client` (deploy
over SSH). No Python code lives here: Python is only there for `cfn-lint`.

## What runs on the instance (`app/`)

- Image `nousresearch/hermes-agent:${HERMES_IMAGE_TAG}` (default `stable`, which was Hermes Agent
  v0.22.2 on 2026-10-15; pin a version beyond a PoC) plus the Debian packages of `EXTRA_APT_PACKAGES`. Keep its `ENTRYPOINT`/`CMD`/`USER`.
- Docker CE and the compose plugin are installed by `user-data.sh` on first boot.
- Built on the server by `docker compose up -d --build`; at larger scale publish the image in ECR.

## Third-party services at run time

Amazon Bedrock, the only LLM provider (Claude Haiku, `us.anthropic.claude-haiku-5-5` by default; the account must have accepted that model's AWS Marketplace agreement, region `us-east-1`; the agent's IAM user and its Secrets Manager secret come from the stack) and optionally Telegram (see
`integrations.md`).
