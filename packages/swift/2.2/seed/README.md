# seed/ — Swift 2.2 seed tree

This directory holds the **Seed-mode** YAML for the Swift 2.2 baseline: the
bootstrap catalog and customer-tunable content that deserialize fills only where
the target is empty.

Seed predicates for this package (from `config/swift-2.2.json`):

- **Content — Swift 2 area** (seed defaults for customer-tunable fields)
- `EcomGroups`, `EcomProducts`, `EcomGroupProductRelation`
- `EcomVariantGroups`, `EcomVariantsOptions`, `EcomVariantOptionsProductRelation`
- `EcomDiscount`, `EcomDiscountTranslation`

## Populating this tree

The seed catalog is captured from a clean source host with the
[authoring loop](../../../../docs/authoring-a-baseline.md):

```powershell
pwsh tools/capture/new-baseline.ps1 -Product swift -Version 2.2 -Mode seed
```

This runs `serialize?mode=seed` against the cleaned source host and stages the
resulting YAML here. The capture is then verified end-to-end with
`tools/e2e/full-clean-roundtrip.ps1` before the package is released as Stable.
