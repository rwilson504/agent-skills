# n8n Debug Workflow

> Diagnose and fix failing n8n executions — error catalog, item-linking
> forensics, rate-limit recovery, trigger debugging.

This is the human-facing landing page. The AI agent contract lives in
[SKILL.md](SKILL.md).

## Key capabilities

- Reading and interpreting n8n execution logs
- Decoding common error messages (API errors, expression errors, item-linking
  errors, rate limits)
- Diagnosing trigger-never-fires problems (Webhook, Schedule, App)
- Adding the right resilience flags (`retryOnFail`, `continueOnFail`,
  `onError`, `alwaysOutputData`)
- Building error workflows that route failures to Slack/PagerDuty/email
- Recovery patterns for stalled and timed-out executions

## Use cases

- "My workflow worked yesterday and is failing today"
- Triaging a paged-out execution at 3 AM
- Adding resilience to a workflow before activating it
- Forensic analysis of "data went missing somewhere in the middle"

## Prerequisites

- Access to the n8n instance (or its execution exports) where the failure
  happened
- The failing workflow JSON or the ability to open the Editor

## Install (this skill only)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add rwilson504/agent-skills
copilot plugin install n8n@agent-skills
```

(Bundled in the `n8n` plugin.)

### Claude Code

```bash
claude install-github-skill rwilson504/agent-skills/src/skills/n8n-debug-workflow
```

## What's in this folder

| Path | Purpose |
|---|---|
| [`SKILL.md`](SKILL.md) | Main skill instructions |
| [`LESSONS_LEARNED.md`](LESSONS_LEARNED.md) | Continuous-learning log |
| [`references/ERROR_CATALOG.md`](references/ERROR_CATALOG.md) | Indexed error messages and their fixes |
| [`references/EXECUTION_DEBUGGING.md`](references/EXECUTION_DEBUGGING.md) | Reading logs, run modes, stalls, memory |
| [`references/ITEM_LINKING_ERRORS.md`](references/ITEM_LINKING_ERRORS.md) | "Could not find paired item" forensics |
| [`references/RATE_LIMITS.md`](references/RATE_LIMITS.md) | 429s, backoff, batching strategies |
| [`references/TRIGGER_PROBLEMS.md`](references/TRIGGER_PROBLEMS.md) | Triggers that never fire, fire twice, or fire late |

## Resources

- [n8n Error Handling](https://docs.n8n.io/flow-logic/error-handling/)
- [n8n Debugging Course](https://docs.n8n.io/courses/level-two/chapter-4/)
- [n8n Executions](https://docs.n8n.io/workflows/executions/)

## License

[MIT-0](https://opensource.org/license/0bsd) — no attribution required.
