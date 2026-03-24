# Partner Center Configuration

Azure Marketplace Managed Application offer configuration for Campfire — Decentralized Agent Coordination.

## Offer Type

**Azure Managed Application** — customer deploys into their own Azure subscription via the Azure Marketplace. Publisher manages the template; customer pays for Azure resources plus metered usage.

## Plans

### Free Plan

| Field | Value |
|-------|-------|
| Plan ID | `free` |
| Display name | Free |
| Description | 1,000 messages/month per campfire. No credit card required. |
| Pricing model | Free + metered (no base fee) |
| Monthly base fee | $0 |
| Metered usage | $0 per message (reported but not charged) |
| Message cap | 1,000 messages/month per campfire |
| Availability | Public |

The 1,000 message/month cap matches `DefaultMonthlyMessageCap = 1000` in `pkg/ratelimit/ratelimit.go`. When a campfire hits the cap, the server returns HTTP 402. The free plan still emits metered usage events so operators can see actual usage.

### Pro Plan

| Field | Value |
|-------|-------|
| Plan ID | `pro` |
| Display name | Pro |
| Description | 50,000 messages/month per campfire. Best for production agent workloads. |
| Pricing model | Flat monthly fee + metered overage |
| Monthly base fee | $29/month |
| Included messages | 50,000 messages/month (aggregate across all campfires) |
| Overage rate | $0.001 per message above 50,000 |
| Rate limit | 100 messages/minute per campfire (default) |
| Availability | Public |

Pro disables the 1,000 message monthly cap. The rate limiter monthly cap is set to 50,000 via `Config.MonthlyMessageCap` at deployment time (configurable in the managed app template parameters).

### Enterprise Plan

| Field | Value |
|-------|-------|
| Plan ID | `enterprise` |
| Display name | Enterprise |
| Description | Unlimited messages, SLA, dedicated support, custom rate limits. Contact us for pricing. |
| Pricing model | Private offer / custom |
| Monthly base fee | Custom (negotiated) |
| Message cap | None (rate limiter disabled or set to customer-agreed limit) |
| Availability | Private (by customer invitation) |

Enterprise plans are configured as private offers in Partner Center. Metering still runs so usage data is available for billing reconciliation.

## Custom Meter Dimensions

Defined under **Technical configuration > Custom meters** in Partner Center.

| Dimension ID | Display name | Unit of measure | Included quantity (Free) | Included quantity (Pro) |
|-------------|--------------|-----------------|--------------------------|--------------------------|
| `messages` | Messages | message | 0 (billed at $0) | 50,000 |

### Dimension: `messages`

- **ID**: `messages` — must match the `Dimension` field in `pkg/meter/UsageEvent` (defaults to `"messages"` in `EmitterConfig.dimension()`)
- **Description**: One campfire message accepted and stored. Counted after rate limit and size checks pass (i.e., after `pkg/ratelimit/Wrapper.AddMessage` succeeds). Emitted hourly by `pkg/meter/Emitter`.
- **Unit**: message (singular)
- **Charged plans**: Pro (overage above 50,000), Enterprise (custom)
- **Free plan**: Dimension is reported but charged at $0.00

### Why one dimension

The meter code tracks messages per campfire ID (`UsageCollector.RecordMessage(campfireID)`). The Marketplace receives one `UsageEvent` per campfire per hour, all using the `messages` dimension. A `campfires` dimension is not needed — campfire count is implicit in the resource ID and not a separately priced unit.

## Per-Plan Meter Rates

| Plan | Dimension | Rate | Notes |
|------|-----------|------|-------|
| free | messages | $0.00/message | Reported, not charged |
| pro | messages | $0.000 for first 50,000; $0.001/message overage | Overage metered |
| enterprise | messages | Custom | Private offer |

## Plan Visibility

- Free and Pro: publicly listed on Azure Marketplace
- Enterprise: private, surfaced only to invited customers via Partner Center

## Technical Configuration

### Resource ID

Each deployed managed application instance has an Azure resource ID. The `pkg/meter/Emitter` uses this as `UsageEvent.ResourceID`. For managed apps this is the managed application's resource ID, not the subscription ID.

### Plan ID propagation

The `PlanID` field in `UsageEvent` must match the Plan ID configured in Partner Center (`free`, `pro`, or `enterprise`). The managed app template passes the plan ID to the cf-mcp container at deploy time via environment variable `MARKETPLACE_PLAN_ID`.

### Metering API endpoint

`https://marketplaceapi.microsoft.com/api/usageEvent?api-version=2018-08-31` (matches `DefaultMeteringAPIURL` in `pkg/meter/meter.go`)

## Notes

- Partner Center offer type: **Azure Application > Managed Application**
- Offer must pass Microsoft Marketplace certification before it appears in the Marketplace
- Test plans should be created in the staging environment (Preview audience) before going live
- Pricing can only be changed for new subscriptions; existing subscribers keep their plan pricing
