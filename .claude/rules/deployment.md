# Deployment — hermes-agent-lightsail

**Claude never deploys**: no `sls deploy`, `sls remove`, `npm run deploy-*`, `npm run remove-*`, `rollback`, no `aws` command that creates, changes or deletes resources, no `ssh` that
changes the server, no `git push`. Claude runs local checks and gives the owner the command.

> **Status (2026-10-15)**: `dev` is deployed and `scripts/lightsail.sh deploy` works end to end;
> the fixed `skills.external_dirs` step has not run yet (see `skills.md`). `test` and `prod` were never deployed:
> run their first deploy step by step.

## Order (inside the dev container)

```bash
npm run myip              # optional: put the result in ALLOWED_SSH_CIDR (.envs/config.env) to restrict SSH to your IP
npm run deploy-infra:dev      # Lightsail + IP + firewall; Docker installs on first boot (~3 min); the hook downloads the SSH key
npm run deploy-app:dev            # render app/.env, upload a release, build and start gateway + dashboard
npm run status && npm run logs
```

Other stages: `npm run deploy-infra:test|prod` and `npm run deploy-app:test|prod` (first copy `.envs/config.<stage>.env` and `aws.<stage>.env` over `config.env` / `aws.env` and rebuild the container;
the infra scripts run `sls deploy|remove --stage <stage>` in `serverless/infrastructure`).
The stage suffix matters only for `deploy-infra`/`remove-infra` (bundle size, deployment bucket,
`stage` tag). `deploy-app:<stage>` and every operation act on the account of the loaded `aws.env`,
whatever the suffix: check the account alias and `DEVELOPER` printed at container start. Instance size per
stage is `custom.bundleIds` in `serverless.yml`.
Operations: `status`, `logs`, `releases`, `rollback`, `chat`, `model`, `ssh`, `tunnel`, `token` (dashboard session token for Hermes Desktop; it changes on every restart), `ip` (`npm run ip-lightsail`: the instance public IP, from SSM), `key`.
Remove: `npm run remove-infra:dev` (deletes the instance, the IP, `/opt/hermes/data` and the
automatic snapshots — take a manual snapshot first if the state matters).

## Checks Claude can run (read-only)

`npm run format:check`, `npm run spell`,
`cd serverless/infrastructure && sls print --stage <stage>` or `sls package --stage <stage>` (local
template, to diff against `aws cloudformation get-template`),
`cfn-lint` on the templates, `npm run status|releases|ip-lightsail|token`,
`aws ... get-*|describe-*|list-*`, and, **from the host** (the dev container has no Docker CLI):
`docker compose -f app/docker-compose.yml config` (with a temporary `app/.env`, deleted afterwards) and
`docker build app`. Also read-only `ssh` that only reads (`cat`, `grep`, `docker compose logs|ps`,
`curl` to loopback, `cloud-init status`). Never print a token or key; report only whether it is set.

## Gotchas

- `deploy` reads `/hermes-agents/BedrockCredentials` from Secrets Manager: it fails with "deploy the
  stack first" until `deploy-infra` has created it. It also fails if `TELEGRAM_BOT_TOKEN` is set without `TELEGRAM_ALLOWED_USERS`.
- Changing `BEDROCK_MODEL_ID` needs `deploy-infra` too (the IAM policy is scoped to the model); it must be
  region-prefixed (`us.<vendor>.<model>`) because `iam.yml` splits it on dots.
- Bedrock needs the **AWS Marketplace agreement of that exact model**, accepted once per account by
  someone with `aws-marketplace:Subscribe` (send one message in the Bedrock playground). The agent's
  IAM user cannot do it; without it Hermes gets HTTP 403. The agreement of one model (e.g. Haiku
  4.5) does not cover another (Haiku 5.5). Check:
  `aws bedrock get-foundation-model-availability --model-id <foundation model id>` →
  `agreementAvailability.status` must be `AVAILABLE`.
- Verified in `dev`: `hermes config set model.provider|model.default|bedrock.region` work; if they
  fail, `deploy` warns and `npm run model` (choose AWS Bedrock) finishes the job.
- `deploy` says "still bootstrapping" whenever `test -f /opt/hermes/.bootstrapped` fails over SSH,
  which also covers a failed cloud-init or an SSH error. Check with `npm run ssh` and
  `cloud-init status --long` / `/var/log/cloud-init-output.log`.
- `user-data.sh` runs under `/bin/sh` (dash): Lightsail prepends its own lines, so the shebang is
  ignored. Keep it POSIX (`set -eux`, no `pipefail`). It only runs when the instance is created; a
  change to it makes CloudFormation replace the instance (not verified), so on a stage with state
  take a snapshot first.
- The dashboard session token changes on every restart and every `deploy-app`: `npm run token` again.
- If `ALLOWED_SSH_CIDR` is set and the owner's IP changes: update it and run `npm run deploy-infra:<stage>` again.
- `user-data.sh` must stay under 16 KB and contain no `${` (Serverless would resolve it).
