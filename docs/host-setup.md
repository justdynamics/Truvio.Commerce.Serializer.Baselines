# Local host & clean database for a Serialized context

To author or verify a baseline you need two local DW hosts with two database
roles:

- A **source host** you capture *from* — a known-good install of the solution,
  cleaned of upstream contamination so the captured YAML is trustworthy.
- A **target host** you deploy *into* — a **CleanDB** purged to an empty
  Serialized context, so a deploy deterministically reconstructs the solution.

Everything below is automated by `tools/e2e/full-clean-roundtrip.ps1`; this doc
explains what that script does so you can run the steps by hand or debug them.

## Prerequisites

- PowerShell 7+ (`pwsh`), .NET SDK, SQL Server 2019+ (default
  `localhost\SQLEXPRESS`), `sqlcmd` on PATH.
- `sqlpackage` (auto-installed by the pipeline via
  `dotnet tool install --global microsoft.sqlpackage` if missing).
- Two `Dynamicweb.Host.Suite` projects (source + CleanDB), buildable locally.
- The source database artifact (a bacpac/zip). It is **not** committed to this
  repo — it is provided out-of-band. The pipeline expects it at
  `tools/<solution>-database.zip` (gitignored).

## Starting a host

DW hosts here are started with an **explicit** `ASPNETCORE_URLS` —
`launchSettings.json` is not honored in this flow:

```powershell
$env:ASPNETCORE_URLS = 'https://localhost:54035'
dotnet run --project <HostPath>\Dynamicweb.Host.Suite -c Debug
```

The pipeline then polls `/Admin/` until it answers (200/301/302/401, up to
180 s). If the host is unlicensed it auto-registers a trial license by posting
to the admin trial-install endpoint.

Install the serializer either from NuGet (AppStore) or, for local dev, by
dropping `Truvio.Commerce.Serializer.dll` into the host's `bin/`. The config and
YAML live under `Files/System/Serializer/` (see
[package-format.md](package-format.md)).

## Source database — clean for *capture*

A raw product install carries upstream contamination (orphan areas/pages, stale
template references, broken relations) that would pollute a captured baseline.
Restore a known database and apply the cleanup scripts:

```powershell
# Restore from the bacpac
sqlpackage /Action:Import /SourceFile:tools\swift2.2.0-20260129-database.zip `
  /TargetServerName:localhost\SQLEXPRESS /TargetDatabaseName:Swift-2.2

# Apply re-runnable cleanup, then verify
$db='Swift-2.2'; $s='localhost\SQLEXPRESS'
Get-ChildItem tools\cleanup\0*.sql | Sort-Object Name | ForEach-Object {
  sqlcmd -S $s -E -d $db -i $_.FullName
}
sqlcmd -S $s -E -d $db -i tools\cleanup\99-verify.sql
```

`tools/cleanup/00-backup.sql` snapshots mutated tables first; `99-verify.sql`
re-scans for orphan references and reports row counts. See
`tools/cleanup/README.md` for what each script removes.

## Target database — clean for *deploy* (CleanDB)

A "clean Serialized context" is a database emptied of content and ecommerce
reference data, with identities reseeded, so deploying the baseline rebuilds the
solution from nothing:

```powershell
$db='Swift-CleanDB'; $s='localhost\SQLEXPRESS'
sqlcmd -S $s -E -d $db -i tools\purge-cleandb.sql            # purge + reseed identities
sqlcmd -S $s -E -d $db -i tools\cleanup\cleandb-align-schema.sql  # match source schema shape
```

`purge-cleandb.sql` disables FK constraints, deletes content (Area, Page,
Paragraph, GridRow, ItemType_*) and ecommerce tables, reseeds identities to 0,
and re-enables constraints. `cleandb-align-schema.sql` nulls/aligns drift-prone
columns so the CleanDB schema matches the source (see
[COMPATIBILITY.md](../COMPATIBILITY.md)).

## Keep platform versions aligned

Capture and deploy with the **same** DW NuGet version on both hosts. Mismatched
versions introduce schema drift that surfaces as deserialize warnings. Record
the version you used in the package's `BASELINE.md` and
[COMPATIBILITY.md](../COMPATIBILITY.md).

## One command

For the full unattended sequence — restore, clean, build, start both hosts,
serialize, deserialize, smoke-test, assert preservation — run:

```powershell
pwsh tools/e2e/full-clean-roundtrip.ps1
```

See `tools/e2e/README.md` for all parameters (server, DB names, host paths,
URLs, admin credentials, `-SkipBacpacRestore`).
