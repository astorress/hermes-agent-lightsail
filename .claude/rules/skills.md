# Skills — hermes-agent-lightsail

Two different things are called "skills" here:

- **Hermes skills** (what the agent loads): `app/skills/<name>/SKILL.md`. This is the
  deliverable when there is an objective. See `objective.md`.
- **Claude Code skills** (what helps work in this repo): `.claude/skills/`.

## Hermes skill format

Folder `app/skills/<name>/` with `SKILL.md` (agentskills.io format, as Hermes uses):

```markdown
---
name: <same as the folder>
description: <one sentence: what it does and when to use it>
---

# Title / When to use / Steps / Notes / References
```

Optional `references/`, `templates/`, `scripts/`, `assets/`. The agent reads only the
`description` first and the whole file when it decides to use the skill, so the
description must carry the words a user would use. Keep `SKILL.md` short; long material
goes in `references/`. Start from the template in `app/skills/README.md`.

Every folder must have a `SKILL.md` whose `name` equals the folder (no automated check yet). Skills ship with `npm run deploy-app:dev` (mounted read-only at `/opt/skills`).

Hermes finds them through `skills.external_dirs` in `/opt/data/config.yaml` (there is no env var).
`lightsail.sh deploy` sets it with `hermes config set skills.external_dirs '["/opt/skills"]'`
(`config set` parses list literals and refuses a non-list there). It replaces the whole list. Do
not edit `config.yaml` with `python3 -c "import yaml"`: neither the container's Python nor Hermes'
venv has `yaml`; that was the first version and it only warned. The fixed step has not run yet:
after the next `deploy-app`, check with `npm run chat` → `/skills`. Because they are mounted
read-only, the agent cannot edit them with `skill_manage`: git is the source of truth.
