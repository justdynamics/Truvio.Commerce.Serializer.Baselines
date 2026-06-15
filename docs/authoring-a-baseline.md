# Authoring or updating a baseline

The maintainer loop for capturing a new solution (e.g. Digital Asset Portal) or
refreshing an existing one. Every package passes the clean-room round-trip gate
before it merges — see [CONTRIBUTING.md](../CONTRIBUTING.md).

## 1. Stand up a clean source host

Restore the solution's database and apply the cleanup scripts so the capture is
trustworthy. Full detail in [host-setup.md](host-setup.md):

```powershell
sqlpackage /Action:Import /SourceFile:tools\<solution>-database.zip `
  /TargetServerName:localhost\SQLEXPRESS /TargetDatabaseName:<SolutionDb>
Get-ChildItem tools\cleanup\0*.sql | Sort-Object Name | ForEach-Object {
  sqlcmd -S localhost\SQLEXPRESS -E -d <SolutionDb> -i $_.FullName
}
sqlcmd -S localhost\SQLEXPRESS -E -d <SolutionDb> -i tools\cleanup\99-verify.sql
```

## 2. Write the predicate config

Create `packages/<product>/<version>/config/<product>-<version>.json`. For each
piece of data decide its bucket and add a predicate (see
[package-format.md](package-format.md)):

- **Deploy** — structure the developer owns and must be identical everywhere
  (site framework, item types, payment/shipping definitions, reference tables,
  routing).
- **Seed** — bootstrap content the customer then edits (starter pages, catalog,
  templates).
- **Not-serialized** — leave it out (domains, secrets, analytics IDs, CDN host).

## 3. Capture

Run the capture wrapper. It serializes the source host and stages the YAML +
manifest under the package directory:

```powershell
pwsh tools/capture/new-baseline.ps1 -Product <product> -Version <version> `
  -SourceHostUrl https://localhost:54035 -Mode all
```

`-Mode deploy` / `-Mode seed` / `-Mode all` selects which trees to (re)capture.
The wrapper calls `serialize?mode=deploy` then `serialize?mode=seed` and copies
the host's `SerializeRoot/{deploy,seed}` into
`packages/<product>/<version>/{deploy,seed}`.

## 4. Verify — the gate

Deploy the freshly captured package into a CleanDB target and assert a clean
round-trip:

```powershell
pwsh tools/e2e/full-clean-roundtrip.ps1
pwsh tools/smoke/Test-BaselineFrontend.ps1 -HostUrl https://localhost:58217 -AreaId 3
```

The package is gated only when the pipeline reaches disposition **CLOSED**:

- serialize + deserialize all return HTTP 200,
- **zero escalations**,
- source/target row-count parity (e.g. `EcomProducts` matches),
- no orphan YAML files,
- the frontend smoke test exits 0 and is non-vacuous.

## 5. Document and open the PR

- Write `BASELINE.md` (bucket reasoning, not-serialized items, known source-data
  issues) and `CHANGELOG.md`.
- Update `CATALOG.md` (status, tested platform version) and `COMPATIBILITY.md`.
- Open a PR. `validate-pr.yml` checks structure; the round-trip gate is the
  merge bar (`e2e-gate.yml` / maintainer attestation).

## Tips

- Capture and deploy on the **same** platform version to avoid schema drift.
- Re-run capture after every config change — the YAML is generated, never
  hand-edited.
- If the round-trip surfaces source-data problems (cross-area references,
  orphans), fix them with a cleanup script under `tools/cleanup/` and note them
  in `BASELINE.md` rather than patching YAML by hand.
