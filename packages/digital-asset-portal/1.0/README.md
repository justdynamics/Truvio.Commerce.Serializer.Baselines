# Digital Asset Portal 1.0 — in progress

This package is being authored. The first capture has not yet been run, so there
is no `config/`, `deploy/`, or `seed/` content here yet.

To produce it, follow the [authoring loop](../../../docs/authoring-a-baseline.md):

1. Stand up a clean Digital Asset Portal source host ([host-setup.md](../../../docs/host-setup.md)).
2. Write `config/digital-asset-portal-1.0.json` with the Deploy/Seed predicates
   for the portal's areas and supporting tables.
3. Capture:

   ```powershell
   pwsh tools/capture/new-baseline.ps1 -Product digital-asset-portal -Version 1.0 `
     -SourceHostUrl https://localhost:54035 -SourceFilesRoot <host>\wwwroot\Files -Mode all
   ```

4. Verify with `tools/e2e/full-clean-roundtrip.ps1` until disposition CLOSED.
5. Write `BASELINE.md` / `CHANGELOG.md`, update `CATALOG.md`, open a PR.

Known portal-specific areas to validate during the first capture: cross-area
references and item-editor field bindings.
