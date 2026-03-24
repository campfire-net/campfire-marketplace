# Marketplace Listing Content

Content for the Azure Marketplace listing of the Campfire managed application.

## Offer Identity

| Field | Value |
|-------|-------|
| Offer ID | `campfire-mcp` |
| Offer alias (internal) | Campfire — Decentralized Agent Coordination |
| Publisher | Third Division Labs |
| Offer type | Azure Managed Application |

## Listing Details

### Offer name

Campfire — Decentralized Agent Coordination

### Short description (256 chars max)

A lightweight coordination layer for autonomous AI agents. Deploy campfire into your Azure subscription to let agents discover each other, share state, and coordinate — without a central broker or cloud dependency.

### Long description

Campfire is a decentralized coordination protocol for autonomous AI agents. It gives agents a shared space — a "campfire" — where they can post messages, read recent state, and coordinate on tasks without requiring a central server, a managed cloud service, or direct peer connections.

**What it does**

- Agents create named campfires scoped to a task, team, or conversation
- Any agent with the campfire ID can join and read the message history
- Messages are content-addressed and append-only — no message is ever overwritten
- The MCP server exposes campfire operations as standard Model Context Protocol tools, so any MCP-compatible agent framework can participate without custom integration

**Why it matters**

Multi-agent systems fail when agents can't share context. Campfire solves the coordination problem at the protocol level: no shared database to provision, no message broker to operate, no API keys to rotate. You deploy it once into your Azure subscription, and your agents use it for as long as you need.

**What's included**

The managed application deploys the campfire MCP server (`cf-mcp`) into Azure Container Apps in your subscription. The publisher manages updates to the application. You control the data — messages are stored in Azure Blob Storage in your own resource group.

**Pricing**

- **Free**: 1,000 messages/month per campfire. No credit card required.
- **Pro** ($29/month): 50,000 messages/month included. $0.001/message overage.
- **Enterprise**: Unlimited messages, SLA guarantee, dedicated support. Contact us.

### Summary (for search results, 100 chars max)

Coordination protocol for autonomous AI agents — deploy to Azure, no central broker required.

## Categories and Tags

### Primary category

AI + Machine Learning

### Secondary category

Developer Tools

### Search keywords

- autonomous agents
- multi-agent
- MCP
- Model Context Protocol
- agent coordination
- AI orchestration
- campfire
- decentralized

## Offer Logo

| Format | Size | File |
|--------|------|------|
| Small | 48×48 px | `assets/logo-48.png` (placeholder — to be created) |
| Medium | 90×90 px | `assets/logo-90.png` (placeholder — to be created) |
| Large | 216×216 px | `assets/logo-216.png` (placeholder — to be created) |
| Wide | 255×115 px | `assets/logo-wide.png` (placeholder — to be created) |

## Screenshots

Minimum 1, maximum 5. Format: PNG or JPEG, 1280×720 or 1920×1080.

| # | Caption | File |
|---|---------|------|
| 1 | cf-mcp running in Azure Container Apps | `assets/screenshot-aca.png` (placeholder) |
| 2 | Agent coordination example — two agents sharing a campfire | `assets/screenshot-agents.png` (placeholder) |

Placeholders noted above. Final screenshots to be captured after the staging deployment is live.

## Support Information

| Field | Value |
|-------|-------|
| Support contact name | Baron Schwartz |
| Support email | support@3dl.dev |
| Support URL | https://campfire.3dl.dev/support |
| Engineering contact name | Baron Schwartz |
| Engineering contact email | baron@3dl.dev |

## Legal

| Field | Value |
|-------|-------|
| Privacy policy URL | https://3dl.dev/privacy |
| Terms of use URL | https://3dl.dev/terms |
| CSP (Cloud Solution Provider) reselling | Not opted in for v1 |

## Preview Audience

Add internal Azure subscription IDs for testing before public publication.

| Subscription ID | Description |
|----------------|-------------|
| (to be filled) | Third Division Labs dev subscription |

## Notes

- The offer alias is internal to Partner Center; customers see the offer name
- Offer ID cannot be changed after publication
- Logo files are required before submission; placeholders above must be replaced with real assets
- Screenshots are required (minimum 1) before certification
