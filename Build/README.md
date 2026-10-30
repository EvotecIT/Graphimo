# Building Graphimo

Use PSPublishModule 3.0.182 or later and run the native entrypoint from the
repository root:

```powershell
./Build/Build-Module.ps1 -RunMode Build
./Build/Build-Module.ps1 -RunMode Build -SignModule:$false -PackageRoot './ValidationPackage'
./Build/Build-Module.ps1 -RunMode Publish
```

Build creates local artefacts without publishing. Signing is enabled by default;
the second command explicitly creates unsigned validation output. Manifest mode
refreshes metadata without a complete build. `ConfigurationGateMode` remains an
alias for `RunMode`.

`AllowedCertificateThumbprints` contains approved signing identities in priority
order. The default retains the configured Evotec release identity. An explicit
`CertificateThumbprint` must satisfy that list. The shared tool resolves and
validates the signer; the wrapper does not enumerate certificates or select an
unrelated identity.

Publish builds, signs and publishes to PowerShell Gallery and GitHub. By default
it reads the machine-local key files under `~/.config/evotec/`; use
`PowerShellGalleryApiKeyPath` and `GitHubApiKeyPath` to select other existing key
files. Build mode does not require these keys. Keep credentials outside Git.

The native merger owns approved dependency pruning and package finalization.
Generated artefacts remain ignored. Inspect the finalized folder and read the
exact public version back after publication, including its exported batching
command and signatures.
