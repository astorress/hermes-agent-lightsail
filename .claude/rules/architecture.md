# Architecture — hermes-agent-lightsail

Diagram: `docs/architecture.drawio` (page `Hermes Agent`). What matters when editing:

- **Two containers, two purposes**: the dev container (`.docker/`, image stage
  `img-hermes`) is where everything runs; `app/` is what runs on the instance.
- **One node**: Lightsail Ubuntu 24.04 + static IP + firewall (22 only) + daily snapshot.
  State lives in `/opt/hermes/data` (mounted at `/opt/data`: config, sessions, memory,
  skills the agent creates). No HA; the snapshot is the safety net.
- **`gateway`** (`hermes gateway run`, Telegram long polling, outbound only) and
  **`dashboard`** (`127.0.0.1:9119`, reached by SSH tunnel; its API needs the session token it
  creates at start and embeds in its page, `npm run token`). Both `network_mode: host`,
  neither publishes ports. Never pass `--insecure --host 0.0.0.0` to the dashboard (in this
  version `--insecure` is a no-op and a public bind requires an auth provider anyway).
- **Releases**: `/opt/hermes/releases/<timestamp>/` (last 3 kept), `current` symlink,
  `docker compose up -d --build` from the release folder.
- **Skills**: `app/skills/` ships in each release and is mounted read-only at
  `/opt/skills`; `lightsail.sh deploy` registers that path with
  `hermes config set skills.external_dirs '["/opt/skills"]'` (fixed, not run yet; see `skills.md`). Skills the agent writes itself live in the data volume.
- **SSM** (`/hermes-agents/LightsailPublicIp`, `LightsailInstanceName`) is how
  `scripts/lightsail.sh` finds the server without storing IPs.
- Another agent = another stage (another AWS account) or another Hermes profile on the same instance.

## Dev container vs. agent container

|          | Dev container                                                      | Agent container                                          |
| -------- | ------------------------------------------------------------------ | -------------------------------------------------------- |
| Folder   | `.docker/` (+ `.devcontainer.json`)                                | `app/`                                                   |
| Purpose  | Develop and deploy (AWS CLI, Serverless, cfn-lint, SSH, envsubst)  | What runs on Lightsail: Hermes Agent                     |
| Image    | `node:24` + Python 3.13 (stage `img-hermes`)                       | `nousresearch/hermes-agent:<tag>` + `EXTRA_APT_PACKAGES` |
| Secrets  | `.envs/aws.env`, `sls.env`, `config.env` (environment variables)   | `app/.env` rendered on every deploy (0600)               |

## Pieces

- **Instance**: Ubuntu 24.04, size from `custom.bundleIds`, daily snapshot; uses the region's default key pair (`downloadSshKeyPair.sh` downloads it after each deploy).
- **Firewall** (`Networking.Ports`): TCP 22 only, from `ALLOWED_SSH_CIDR`; empty (PoC) = any IPv4, key only.
- **User data** (once): Docker CE + compose, log limits, 2 GB swap, `/opt/hermes`.
- **Static IP**: fixed address for SSH and the Desktop tunnel.

## What `deploy-app` does (`scripts/lightsail.sh deploy`)

1. `app/env.sh` renders `app/env.template` → `app/.env` from `config.env` (empty values dropped).
2. Reads the agent's IAM key (Bedrock) from Secrets Manager and validates: credentials exist and, with a Telegram token, `TELEGRAM_ALLOWED_USERS`.
3. `tar` of `app/` over SSH to `/opt/hermes/releases/<timestamp>/`.
4. `docker compose up -d --build` there; `current` points to it; 3 releases are kept.
5. Checks `hermes` is `running`, otherwise shows the logs. `npm run rollback` starts the previous release.
6. The local `app/.env` is deleted on exit.

## Why it is built this way

- **Instance + Docker, not Lightsail Container Service**: the agent needs persistent state (memory, sessions) and the container service has no volumes.
- **Nothing published**: Telegram is outbound and the dashboard is loopback. Exposing Hermes' API server (`API_SERVER_*`) later needs TLS + `API_SERVER_KEY` and an explicit port in `lightsail.yml`.
- **Secrets you write stay outside CloudFormation**: user data and the template are readable. The only secret CloudFormation handles is the Bedrock access key it creates itself (`iam.yml` → `secrets-manager.yml`).
- **Mandatory allowlist**: Hermes runs commands; never `*_ALLOW_ALL_USERS`.
- **Image built on the server**: the extra layer is small; at larger scale publish it to ECR.

## Growing

Another channel (Discord, Slack, Teams) = new variables in `app/env.template`; the infrastructure does not change. More agents = another stage (own size in `custom.bundleIds`, own `config.<stage>.env` and `aws.<stage>.env`) or several Hermes profiles on one instance. For a concrete objective, see `objective.md`.
