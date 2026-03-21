# CLAUDE.md — Campfire Marketplace

> OS-level instructions (session protocol, model routing, blog pipeline, rules) are inherited from `~/.claude/CLAUDE.md`. This file contains only project-specific configuration.

## Project

**Campfire Marketplace**: Azure Marketplace managed application for campfire. Customers deploy cf-mcp into their own Azure subscription via one-click. The operator (3DL) manages updates remotely.

## Work Tracking — rd (not bd)

**This project uses `rd` for all work tracking.** The `bd` CLI is NOT used in this project.

```bash
rd list                    # All items
rd list --status active    # Active items
rd ready                   # Ready queue
rd show <id>               # Item details
rd create "Title" --type task  # New item
rd update <id> --status active # Change status
rd close <id> --reason "..."   # Close with reason
```

## Agent Roster

| Agent | Spec | Role |
|-------|------|------|
| PM | CLAUDE.md | Prioritize, track, route work |
| implementer | .claude/agents/implementer.md | Build one work unit |
| reviewer | .claude/agents/reviewer.md | Review for correctness + integration |
| designer | .claude/agents/designer.md | Architecture + pricing decisions |

**Routing rules:**
- Bicep templates → implementer (sonnet)
- Marketplace listing/content → implementer (sonnet)
- Pricing model → designer (opus)
- Certification process → implementer (sonnet)

## Task-Type → Model Mapping

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| Pricing model, marketplace strategy | **Opus** | Strategic decisions |
| Bicep templates, UI definitions | **Sonnet** | Structured implementation |
| Listing text, icon updates | **Haiku** | Content updates |

## Architecture

```
managed-app/
  mainTemplate.bicep       Main deployment template (App Service B1 + Storage + App Insights)
  createUiDefinition.json  Marketplace UI definition (customer-facing parameters)
  viewDefinition.json      Managed app dashboard views
marketplace/
  listing.md               Marketplace listing content
  pricing.json             Tier definitions (Community/Team/Enterprise)
  icons/                   Marketplace listing assets
docs/
  publishing-guide.md      Azure Partner Center certification process
  operator-runbook.md      Remote management procedures
.github/workflows/
  validate.yml             Bicep linting + ARM-TTK validation
  package.yml              Package managed app ZIP for Partner Center
```

## Source of Truth

1. Design doc: campfire repo `docs/design-hosted-deployment.md`
2. Managed app template: `managed-app/mainTemplate.bicep`
3. Marketplace listing: `marketplace/`

## Conventions

- Bicep for all templates (no ARM JSON, no Terraform)
- ARM-TTK validation must pass before commit
- Marketplace listing follows Azure Marketplace content guidelines
- All managed app resources tagged with `managedBy: campfire`

## Don't

- Don't include application source code — the managed app pulls from GHCR
- Don't hardcode SKUs — parameterize everything in createUiDefinition
- Don't bypass Partner Center validation — run ARM-TTK locally first
