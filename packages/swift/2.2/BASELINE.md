# Swift 2.2 baseline

**Solution:** Swift storefront (B2C/B2B commerce)
**Baseline version:** 2.2.0
**Captured & verified against:** DW 10.23.9
**Config:** [`config/swift-2.2.json`](config/swift-2.2.json)

When a customer adopts Swift as their commerce platform they get a working
storefront before adding a single product: hundreds of structural pages,
item-type definitions, shop setup, payment and shipping definitions,
country/currency/VAT reference data, the order state machine, and the
URL-rewriting infrastructure. This package captures exactly that starting point
so a clean install can be brought to a known-good state and kept in sync across
environments.

## The three buckets

Every piece of data in Swift belongs to one of three buckets. Only the first two
are in this package.

| Bucket | Owner | Behavior on deploy | In package |
| --- | --- | --- | --- |
| **Deploy** | Developer / template | Source wins — YAML overwrites the target every time | `deploy/` |
| **Seed** | Developer once, then the customer | Field-level merge — fills only empty fields, preserves customer edits | `seed/` |
| **Not-serialized** | Ops / infrastructure | Never captured; configured per environment | — |

## Deploy (`deploy/`) — 17 predicates

Structural, source-owned data that must be identical across dev/test/QA/prod.

- **Content — Swift 2 area:** the full page tree, item types, layouts,
  navigation, and framework pages (Customer Center, checkout, account, etc.).
- **Ecommerce reference tables:** `EcomCountries`, `EcomCountryText`,
  `EcomCurrencies`, `EcomLanguages`, `EcomVatGroups`, `EcomVatCountryRelations`,
  `EcomShops`, `EcomShopLanguageRelation`, `EcomShopGroupRelation`,
  `EcomPayments`, `EcomShippings`, `EcomMethodCountryRelation`, `EcomOrderFlow`,
  `EcomOrderStates`, `EcomOrderStateRules`.
- **Routing:** `UrlPath`.

## Seed (`seed/`) — 9 predicates

Bootstrap content delivered once, then owned by the customer. Deserialize fills
only fields the target left empty, so customer edits survive re-runs.

- **Content — Swift 2 area:** seed defaults for customer-tunable fields.
- **Catalog & promotions:** `EcomGroups`, `EcomProducts`,
  `EcomGroupProductRelation`, `EcomVariantGroups`, `EcomVariantsOptions`,
  `EcomVariantOptionsProductRelation`, `EcomDiscount`, `EcomDiscountTranslation`.

> **Seed tree status:** the seed catalog is captured into this package via the
> [authoring loop](../../../docs/authoring-a-baseline.md) against a clean source
> host. See [`seed/README.md`](seed/README.md) for the current state.

## Not-serialized (configured per environment)

These never appear in any YAML and must be set on each target host:

- Live domain bindings (`AreaDomain`, `AreaDomainLock`) and CDN host.
- Payment-gateway API keys and other secrets (host configuration / key vault).
- Analytics and tag-manager IDs (e.g. `GoogleTagManagerID`), favicon overrides.
- The Swift template filesystem under `/Files/Templates/Designs/Swift/` (shipped
  with the design, cloned separately, not part of the data baseline).

The config's `excludeXmlElementsByType` strips per-environment and transient
fields out of serialized XML payloads (e.g. cart mail sender/subject defaults)
so they do not leak into the baseline.

## Deploying this package

- **CI/CD:** see [docs/consuming-cicd.md](../../../docs/consuming-cicd.md).
- **In-admin upload:** see [docs/consuming-upload.md](../../../docs/consuming-upload.md).

Deploy onto a host running the tested platform version (see
[COMPATIBILITY.md](../../../COMPATIBILITY.md)) for a deployment with no schema
warnings.
