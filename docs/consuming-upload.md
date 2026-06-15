# Consuming a baseline via Upload Package (quick-start)

The fastest way to try a baseline on a single host, with no pipeline. You
download a release `.zip` and upload it through DW admin. A pre-flight gate
checks the target before anything is written.

## Steps

1. **Get the package zip.** Open this repo's
   [Releases](https://github.com/justdynamics/Truvio.Commerce.Serializer.Baselines/releases),
   pick the package tag you want (e.g. `swift/2.2.0`), and download its
   `.zip` asset.

2. **Open the upload screen.** In DW admin go to
   **Settings → Developer → Serialize → Upload Package**.

3. **Upload the zip.** The pre-flight gate reads the package's template manifest
   and verifies every required layout, grid row, and item type exists on this
   host. If anything is missing, the upload is **blocked** with a report — fix
   the missing templates (e.g. install the matching Swift design) and retry.

4. **Apply.** On a clean pre-flight, the content and any bundled assets are
   written. Deploy data overwrites; seed data fills only empty fields.

## When to use this vs CI/CD

- **Upload Package:** evaluating a baseline, a one-off demo, or a single
  environment you manage by hand.
- **CI/CD:** real environment promotion across dev/test/QA/prod with reviewable
  diffs — see [consuming-cicd.md](consuming-cicd.md).

## Notes

- The host needs the **Truvio.Commerce.Serializer** app installed first.
- The zip is the same package content as the git tree (`config/` + `deploy/` +
  `seed/` + `templates.manifest.yml`), bundled for the upload flow plus an
  `INSTALL.txt`.
- Deploy onto the platform version the package was tested against — see
  [COMPATIBILITY.md](../COMPATIBILITY.md).
