---
name: ticket
description: Start or resume a work session on a Jira ticket (SmartCkt / WebKit)
disable-model-invocation: true
---

Drive the work on ticket `$ARGUMENTS` (e.g. `SMARTCKTS-11640`).
No ticket key given → ask for one and stop.

The ticket folder is `~/Work/<number>/`, the key without its project prefix
(`SMARTCKTS-11640` → `~/Work/11640/`).

## Mode: pick by the current directory
- **Anywhere outside the ticket folder (e.g. the vault): bootstrap only.**
  Do Setup 2–4: fetch the Jira issue into `jira-<KEY>.json` in the ticket
  folder, set the vault line to `gate: investigate`. Then print
  `cd ~/Work/<number> && claude "/ticket <KEY>"` and stop. No investigation,
  no Conductor or DB queries in this session.
- **Inside the ticket folder: work session.** Do the full Setup, then the Flow.

## Setup
1. Read `~/Work/smartckt-context.md` in full. It is the working context for
   SmartCkt and WebKit; its rules override defaults. It holds no secrets.
2. Credentials: only via `op run --env-file ~/Work/.env.op -- sh -c '...'`.
   Never print, echo or write a resolved value. If `op` fails, stop and say so.
3. Ticket folder: create it with `git init` if missing; if it exists, read what
   is there and resume from the last gate reached.
   All notes, baselines, plans and deliverables for the ticket live here.
4. Vault: in `~/Personal/obsidian-vault/01 Projects/`, pick `SmartCkt.md` or
   `WebKit.md` by where the change lands (ask if unclear). Under `## Tickets`,
   keep exactly one line per ticket:
   `- [ ] <KEY> — <short title> · gate: <investigate|questions|plan|phase N|review|QA>`
   Update the gate as the session moves. Only that line; no ticket detail in the
   vault (it syncs to GitHub).

## Flow
Run the gated session flow from the context file (§9). Every gate waits for my
explicit approval. Read-only investigation needs no approval.
