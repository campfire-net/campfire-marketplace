# Microsoft Marketplace Certification Checklist

Checklist for Azure Managed Application certification submission. Microsoft validates each item before the offer goes live.

Reference: [Azure Marketplace certification policies](https://learn.microsoft.com/en-us/legal/marketplace/certification-policies)

## Offer Setup

- [ ] Offer type set to **Azure Application > Managed Application**
- [ ] Publisher profile complete (company name, contact, MPN ID)
- [ ] Offer ID set and confirmed (`campfire-mcp`) — cannot change after publication
- [ ] Offer alias set (internal only)
- [ ] Customer leads destination configured (Dynamics, Salesforce, HTTPS endpoint, or email)

## Listing

- [ ] Offer name filled in
- [ ] Short description ≤ 256 characters
- [ ] Long description ≥ 300 characters, no broken links
- [ ] Summary ≤ 100 characters
- [ ] Primary category selected (AI + Machine Learning)
- [ ] Secondary category selected (Developer Tools)
- [ ] Privacy policy URL live and accessible
- [ ] Terms of use URL live and accessible (or Standard Contract selected)
- [ ] Support URL live and accessible
- [ ] Engineering contact email valid

## Logos

- [ ] Small logo (48×48 PNG) uploaded
- [ ] Medium logo (90×90 PNG) uploaded
- [ ] Large logo (216×216 PNG) uploaded
- [ ] Wide logo (255×115 PNG) uploaded
- [ ] Logos are not blurry, not stretched, background appropriate
- [ ] No Microsoft trademarks in logo (no Azure logo, Windows logo, etc.)

## Screenshots

- [ ] At least 1 screenshot uploaded
- [ ] Screenshots are 1280×720 or 1920×1080
- [ ] Screenshots show real product UI (no mockups with placeholder text)
- [ ] Captions added to each screenshot

## Technical Configuration

### ARM/Bicep template

- [ ] `mainTemplate.json` deploys successfully in a clean Azure subscription
- [ ] `createUiDefinition.json` validates cleanly in the [CreateUIDefinition Sandbox](https://portal.azure.com/?feature.customPortal=false&#blade/Microsoft_Azure_CreateUIDef/SandboxBlade)
- [ ] `viewDefinition.json` present and valid
- [ ] No hardcoded credentials or secrets in any template file
- [ ] Template passes `az deployment group validate` with no errors
- [ ] All resources deploy into the **managed resource group** (not the customer's own resource group unless explicitly required)
- [ ] Managed resource group lock level set appropriately (`None` or `ReadOnly`)
- [ ] Template uses `apiVersion` values that are not deprecated

### Metering

- [ ] Custom meter dimension `messages` configured in Partner Center
- [ ] Dimension ID `messages` matches what the code emits (`pkg/meter/EmitterConfig.Dimension`)
- [ ] Metering API calls use managed identity (not service principal secret)
- [ ] Plan IDs in metering events (`UsageEvent.PlanID`) match Plan IDs in Partner Center
- [ ] Duplicate usage event handling tested (HTTP 409 is treated as success — already handled in `pkg/meter/meter.go`)

### Plans

- [ ] Free plan configured with $0 base fee and $0 metered rate
- [ ] Pro plan configured with $29/month base fee and overage rate
- [ ] Enterprise plan configured as private offer
- [ ] Plan IDs (`free`, `pro`, `enterprise`) match what the application code uses
- [ ] Monthly message cap for Free plan matches `DefaultMonthlyMessageCap = 1000` in code

## Security

- [ ] No public storage account access (all blobs private)
- [ ] No inbound internet access to storage account (private endpoint or service endpoint)
- [ ] Container image pulled from a private registry or a trusted public registry with a pinned digest
- [ ] No SSH or RDP ports exposed unless required and documented
- [ ] Managed identity used for all Azure resource access (no stored credentials)
- [ ] Secrets (if any) stored in Key Vault, not in template parameters or environment variables
- [ ] `allowedValues` constraints on all user-facing parameters where applicable

## Microsoft Policies

- [ ] Offer does not contain malware or malicious content
- [ ] Offer does not collect or exfiltrate customer data without disclosure
- [ ] Offer does not impersonate Microsoft products or services
- [ ] No Microsoft trademarks used without permission
- [ ] If offer is free, it must remain functional without paid upsell prompts blocking core features
- [ ] Support commitment documented: response time SLA defined for Pro/Enterprise

## Preview Testing

Before submitting for certification:

- [ ] Deploy the managed app from the Preview listing into a test subscription
- [ ] Verify all resources are created in the managed resource group
- [ ] Verify `cf-mcp` is reachable and returns correct MCP tool list
- [ ] Verify metering events are emitted (check Marketplace metering API logs)
- [ ] Verify Free plan enforces 1,000 message/month cap
- [ ] Verify Pro plan allows >1,000 messages/month
- [ ] Verify delete of the managed app removes all resources cleanly
- [ ] Run `az managedapp list` and confirm the app shows up with correct plan

## Submission

- [ ] All checklist items above complete
- [ ] Preview audience subscriptions added and tested
- [ ] "Go live" button clicked in Partner Center
- [ ] Certification notes written (optional but helpful for borderline items)
- [ ] Monitor certification status in Partner Center (typically 2–5 business days)

## Post-Certification

- [ ] Offer appears in Azure Marketplace search
- [ ] Test end-to-end purchase and deployment as a customer
- [ ] Confirm metering events appear in Partner Center usage dashboard after 24 hours
- [ ] Set up alerting for metering API failures (Partner Center has a failed-events report)
