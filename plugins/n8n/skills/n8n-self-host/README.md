# n8n Self-Host

> Install, configure, and operate self-hosted n8n responsibly — Day-0
> checklist, Docker Compose, queue mode, reverse proxy, backups.

This is the human-facing landing page. The AI agent contract lives in
[SKILL.md](SKILL.md).

## Key capabilities

- Day-0 production setup (`N8N_ENCRYPTION_KEY`, `WEBHOOK_URL`, Postgres,
  timezone, TLS)
- Single-instance Docker Compose deployment
- Queue mode deployment with Redis + scalable workers
- Reverse proxy patterns (nginx, Traefik, Caddy)
- Postgres setup and migration from SQLite
- Backup, restore, and upgrade procedures
- Security hardening (encryption key handling, binary storage, env-var
  blocking)

## Use cases

- "We just spun up an n8n instance and want to run it in production"
- "We need to scale n8n past 50 concurrent executions"
- "Migrate from SQLite to Postgres"
- "Upgrade from n8n 1.50 to 1.78"
- "Set up SSL / move behind Cloudflare"

## Prerequisites

- A Linux host (or Kubernetes cluster) with Docker
- Ability to terminate TLS (or use the host's existing proxy)
- (For production) Postgres and optionally Redis

## Install (this skill only)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add rwilson504/agent-skills
copilot plugin install n8n@agent-skills
```

(Bundled in the `n8n` plugin.)

### Claude Code

```bash
claude install-github-skill rwilson504/agent-skills/src/skills/n8n-self-host
```

## What's in this folder

| Path | Purpose |
|---|---|
| [`SKILL.md`](SKILL.md) | Main skill instructions |
| [`LESSONS_LEARNED.md`](LESSONS_LEARNED.md) | Continuous-learning log |
| [`references/DOCKER.md`](references/DOCKER.md) | Docker / Docker Compose recipes |
| [`references/ENV_VARS.md`](references/ENV_VARS.md) | Annotated env-var catalog |
| [`references/QUEUE_MODE.md`](references/QUEUE_MODE.md) | Queue mode setup and tuning |
| [`references/REVERSE_PROXY.md`](references/REVERSE_PROXY.md) | nginx/Traefik/Caddy configs |
| [`references/SECURITY.md`](references/SECURITY.md) | Encryption key, binary storage, env access |
| [`references/BACKUP_UPGRADE.md`](references/BACKUP_UPGRADE.md) | Backup, restore, and upgrade procedures |

## Resources

- [n8n Hosting Docs](https://docs.n8n.io/hosting/)
- [n8n Docker Compose Examples](https://github.com/n8n-io/n8n-hosting)
- [n8n Environment Variables Reference](https://docs.n8n.io/hosting/configuration/environment-variables/)
- [n8n Helm Chart](https://github.com/n8n-io/n8n-hosting/tree/main/kubernetes)

## License

[MIT-0](https://opensource.org/license/0bsd) — no attribution required.
