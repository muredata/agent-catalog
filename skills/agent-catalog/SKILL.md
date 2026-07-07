---
name: agent-catalog
description: >-
  Discover tools, skills, MCP servers, and agents for a task by searching ARD
  discovery services (Agent Catalog). Use whenever the user wants to find a
  tool, skill, agent, MCP server, API, or capability for something they are
  trying to do. Offers a menu of named Agent Catalogs, remembers the choice,
  presents the ranked results, and never installs anything automatically.
argument-hint: <what you want to find>
---

# Find agentic resources (ARD)

Invoke this skill as `/agent-catalog <query>`, where `<query>` is the task the user
wants to find resources for. Also use it whenever the user otherwise asks you to
**find** tools, skills, agents, MCP servers, or other capabilities for a task. It
searches ARD discovery services (Agent Catalogs) and presents matches for the user
to choose from.

**Requirements.** Querying a catalog needs an HTTP capability — in Claude Code,
`Bash` with `curl`; or an Agent Catalog MCP connector; or a fetch/web tool. If
none is available, tell the user and point them at the MCP connector setup.

Follow this contract exactly:

## 1. Choose an Agent Catalog (a menu the user sees only once)

Agent Catalogs are listed in a shared config at `~/.agentcatalog/catalogs.json`,
each with a `name`. The user's choice is remembered there, so this is a one-time
menu — not a question on every search.

1. **Seed it if missing.** If `~/.agentcatalog/catalogs.json` does not exist, create
   the directory and write this default:

   ```json
   {
     "selected": null,
     "catalogs": [
       {
         "id": "muredata",
         "name": "Mure Data Agent Catalog",
         "description": "Mure Data´s discovery service for agentic data resources.",
         "search": "https://ard.muredata.com/v1/search"
       },
       {
         "id": "github",
         "name": "GitHub Agent Finder",
         "description": "GitHub's public catalog of installable MCP servers, skills, and tools.",
         "search": "https://agentfinder.github.com/api/v1/search",
         "mcp": "https://agentfinder.github.com/api/v1/mcp"
       },
       {
         "id": "huggingface",
         "name": "Hugging Face Discover",
         "description": "Hugging Face's discovery service for agentic resources.",
         "search": "https://huggingface-hf-discover.hf.space/search",
         "mcp": "https://huggingface-hf-discover.hf.space/mcp"
       }
     ]
   }
   ```

2. **Use the saved choice.** Read the file. If `selected` names a catalog, use it
   without prompting — say once: *"Searching **the saved catalog's name** — say
   *switch agent catalog* to change."* Then go to step 2.

3. **Otherwise, show the menu.** Present the catalogs as a numbered list (name +
   description) and let the user pick by number or name:

   ```
   Which Agent Catalog should I search?
     1. Mure Data Agent Catalog — Discovery service of agentic data resources
     2. GitHub Agent Finder — GitHub's public catalog of MCP servers, skills, and tools
     3. Hugging Face Discover — Hugging Face's discovery service for agentic resources
   (Add your own in ~/.agentcatalog/catalogs.json.)
   ```

   Save the pick by writing its `id` to `selected` in the file, then continue.

When the user says *switch agent catalog* (or similar), re-show the menu and update
`selected`. If you have **no file access** (e.g. claude.ai or Desktop over the MCP
connector), there's nothing to choose — just search the endpoint that connector is
configured with.

## 2. Query the chosen Agent Catalog

```http
POST <the selected catalog's "search" URL>  # e.g. https://ard.muredata.com/v1/search
Content-Type: application/json

{ "query": { "text": "<the user's task, in plain language>" } }
```

Narrow results with a filter when useful — e.g. MCP servers only:

```json
{ "query": { "text": "<task>", "filter": { "type": ["application/mcp-server-card+json"] } } }
```

## 3. Present the results

Show only the **top 5** results, in the order returned (already ranked
most-to-least relevant), as a Markdown table:

| Name | Type | Description | Link |
|---|---|---|---|
| displayName | label (see below) | one-line description, capped at 80 chars (`…` if cut) | a Markdown link `[publisher/identifier](url)` — link text capped at 40 chars (`…` if cut), href is the result's full URL, so it's clickable |

**Type column.** Each result's `type` is a raw IANA media type (e.g.
`application/mcp-server-card+json`) — never print that raw string. Map it to a
short human label:

| Raw `type` | Label |
|---|---|
| `application/mcp-server-card+json` | MCP |
| `application/ai-skill+md` | Skill |
| `application/agent-card+json` | Agent |
| `application/tool+json` or `application/openapi+json` | Tool |

For any other `application/…` media type, derive a label the same way: drop
the `application/` prefix and the `+json`/`+md` suffix, drop a generic `ai-`
prefix, take the first remaining word, and title-case it (e.g.
`application/ai-prompt+md` → Prompt).

Don't print a numeric score or rating — rely on row order to convey relevance.
If more than 5 results came back, say how many were omitted and offer to show
more on request. Offer to follow any referrals to other discovery services.

## 4. Never auto-install

Do **not** add, enable, connect, install, or invoke any returned resource
yourself. Installation is always the user's explicit choice.

## 5. Install only on request

Once the user picks a result, give them the steps to install or connect **that**
resource themselves (add it as an MCP connector, install the skill, or call its
API) using the resource's own endpoint and protocol. Then stop and let them act.

## Installation

**Manual** — copy this `agent-catalog/` folder into your Claude Code skills
directory: `~/.claude/skills/` (personal) or `.claude/skills/` (project).

> Custom skills are currently Claude Code–only. The claude.ai web app and Claude
> Desktop do not yet support uploading your own skills.
