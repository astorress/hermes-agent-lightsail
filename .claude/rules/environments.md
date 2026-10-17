# Environments — hermes-agent-lightsail

Variables reach the dev container through `.docker/docker-compose.yml` (`env_file`:
`.envs/aws.env`, `sls.env`, `config.env`). They are git-ignored and there are no example files: the variables are described in the README
glossary. `.docker/initialize.sh` (no params yet) only warns about the missing ones before the
container starts (compose fails if an `env_file` is missing). After editing them, **rebuild the
container**.

| File                                    | Holds                                                                                                                                                                                                                                                                                                                                                                                                                      |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `aws.env`                               | `AWS_ORGANIZATION_ID`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, `AWS_DEFAULT_OUTPUT`                                                                                                                                                                                                                                                                                                                                   |
| `sls.env`                               | `SERVERLESS_ACCESS_KEY`, `SERVERLESS_ORG` (your Serverless Framework org; app `hermes-agents`)                                                                                                                                                                                                                                                                                                                                                         |
| `config.<stage>.env`, `aws.<stage>.env` | full per-stage copies (test, prod); copied over `config.env` / `aws.env` to switch stage (see below)                                                                                                                                                                                                                                                                                                                       |
| `config.env`                            | `DEVELOPER` (required; in `dev` your username, part of the deployment bucket name; `test`/`prod` in those stages' files; printed at container start, so it shows which stage's file is loaded); infra: `ALLOWED_SSH_CIDR` (optional; empty = SSH open), `SNAPSHOT_TIME_UTC`; agent: `HERMES_IMAGE_TAG`, `EXTRA_APT_PACKAGES`, `BEDROCK_MODEL_ID`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS` |

Stages: `dev` (default), `test` and `prod`; the `allowed-stages` safeguard rejects any other. Each stage is deployed to its own AWS
account, so stack, instance, IP, IAM user and secret names carry no stage
(`hermes-agents-infrastructure`, `hermes-agents`...); the stage only selects the bundle size, the
deployment bucket and the `stage` tag.

What differs per stage: the instance size (`custom.bundleIds` in `serverless.yml`: dev/test
`small_3_0` (2 GB, ≈ US$12/month), prod `medium_3_0` (4 GB); not an env var) and the copies of `config.env` / `aws.env`.
Nothing is overlaid: scripts read only the container's `config.env` and `aws.env`, so variables of
two stages never mix (safer, at the cost of a manual step). To switch stage: save the current
files (`cp config.env config.dev.env`), copy the stage's over them (`cp config.prod.env config.env`,
`cp aws.prod.env aws.env`), rebuild the container and deploy with that `<stage>`. At start the
container prints the AWS account alias and `DEVELOPER` (`.docker/entrypoint.sh`): that is how the
deployer confirms which stage is loaded. Scripts do not check it: `scripts/lightsail.sh` has no
`STAGE` and acts on the loaded account, and `deploy-infra:<stage>` trusts the suffix you type. Use a different
Telegram bot per stage. Only the **agent** variables travel to the server
(`app/env.template` lists them); the infra ones are read by Serverless at deploy time.

Never print values of keys or tokens; report only whether they are set.
