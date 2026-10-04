# Monetization

## Position

Monetization is minor, optional, transparent, and subordinate to the creative fantasy. Spending must not decide competitive outcomes, accelerate exclusive power, protect paid users from risks imposed on others, or pressure children through artificial urgency.

## Allowed catalog

- Observer Vessel cosmetic hulls, trails, engine colors, and interior themes.
- Observatory room/display themes and exhibit frames.
- UI color themes, cursor/reticle styles, and non-competitive visualization skins.
- Photo-mode filters, poses, frames, and additional local album organization where platform policy permits.
- Cosmetic star-map annotations and nameplate styles.
- Supporter pack containing disclosed cosmetics and badge/title.
- Optional private/social presentation features only if core visits remain fully functional.

All cosmetics must preserve competitive readability and offer reduced-effects fallbacks.

## Prohibited catalog

No purchasable Primordial Matter, Knowledge, Exotic Matter, Epoch Insight, production multipliers, better random odds, exclusive functional galaxy types, challenge advantages, Void insurance, paid automation power, loot boxes, paid revives for preventable loss, or purchase-only Archivarium completion.

Do not sell relief from deliberately bad pacing. Do not place purchase prompts during ignition, disasters, a loss result, onboarding confusion, or repeated close attempts.

## Pricing and UX rules

- Show exact Robux price and exact contents before purchase.
- Provide preview in the player’s own scene.
- Confirm high-value bundles and prevent accidental duplicate purchase.
- Respect regional/policy restrictions and Roblox commerce requirements.
- Keep the store out of the primary gameplay HUD; access from Observatory/settings/cosmetics.
- Avoid countdowns unless an event genuinely ends; never reset fake scarcity.
- A child-friendly experience means no manipulative streak-loss or social-shame copy.

## Technical implementation

Marketplace receipts are processed server-side. Grants are idempotent by receipt/purchase ID and persisted before acknowledgment. Clients request display information but cannot grant entitlements. Failed fulfillment remains retryable. Catalog configuration is versioned and feature-flagged. Analytics distinguish preview, purchase prompt, success, failure, and refund/revocation where supported without recording sensitive details.

## Roblox Studio MCP and project skills

Use the `Roblox_Studio` MCP server as the Studio execution and evidence bridge for commerce work: select the intended Studio session, inspect the actual `MarketplaceService` integration, run server/client test purchases through Roblox-supported test flows, and debug receipt retry/idempotency behavior. At the start of each task, enumerate or otherwise confirm the MCP tools and built-in skills exposed for that Studio session; names described in [roblox_skills_guide.md](./roblox_skills_guide.md), such as `rbx-docs-search` and `rbx-debug`, are candidates, not proof that they are currently available. Do not let an agent publish products, change live prices, or perform real purchases merely because the MCP connection exists.

Create a workspace-scoped custom skill only after a commerce procedure becomes repeatable and project-specific—for example, `universe-commerce-audit` for receipt replay tests, entitlement reconciliation, fairness checks, and release evidence. Follow the guide's `.agents/skills/<name>/SKILL.md` structure, use a precise trigger description, never use the reserved `rbx-` prefix, keep secrets and live product credentials out of the skill, and review its scripts like production code.

## Success criteria

Track payer conversion and revenue alongside retention, complaint rate, accidental-purchase signals, competitive fairness, and non-payer completion. Monetization ships only after the core loop retains on its own. If a product harms trust or fairness, remove it even if it earns well.
