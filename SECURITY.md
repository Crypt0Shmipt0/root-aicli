# Security Policy

## Threat model

Root.AICLI is a tiny Android app that asks the user's root manager
(Magisk, KernelSU, or APatch) for full root, then runs shell scripts as
the global mount-namespace root inside Termux's filesystem. By design
it has very wide capabilities on the device.

Root.AICLI itself:

- **Never sends data anywhere.** No telemetry, no analytics, no auto
  network calls from the app itself. The only network traffic comes
  from the **official upstream CLI installers** (Anthropic, Google,
  OpenAI, xAI) that we orchestrate, and from Termux's own package
  manager when you tap an action.
- **Never bundles or redistributes third-party CLI binaries.** Every
  install action calls a vendor's official installer.
- **Never reads or transmits user credentials.** Authentication is
  handled by each CLI's own first-run flow (browser OAuth or env-var
  API key).

What you trust when you install Root.AICLI:

- The repo's source code (this is open source; read it).
- The signed APK on GitHub Releases (signed with the project debug
  keystore committed in the repo, so the signature is reproducible by
  anyone who clones).
- The vendors of each CLI you choose to install (Anthropic, Google,
  OpenAI, xAI, the wallentx fork maintainer).

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Use GitHub's private security advisory flow:

  https://github.com/Crypt0Shmipt0/root-aicli/security/advisories/new

Include:

1. A clear description of the vulnerability.
2. Steps to reproduce on a known-good test device (root manager + Android
   version + Termux source).
3. The expected behavior vs. the observed behavior.
4. If possible, a suggested fix.

We aim to:

- Acknowledge a report within 7 days.
- Issue a patch release within 30 days for high-severity issues.
- Credit the reporter in the changelog unless they prefer to stay
  anonymous.

## Supported versions

| Version | Supported |
|---|---|
| 0.1.x | yes (current) |

Earlier prerelease commits are not supported. Stay on a tagged release.

## Known security-relevant gotchas

- **`su -mm` is the right tool for this job, but it is broad.** A
  malicious shell module in Root.AICLI would have full root with the
  global mount namespace. Review module changes carefully.
- **MLS context relabeling can be exploited if abused.** The Permanent
  Fix boot hook touches files across `$PREFIX/lib`, `$PREFIX/bin`, and
  Termux home. If an attacker can write a binary to those paths, our
  boot hook will faithfully relabel it. The fix is to keep root access
  on the device limited to apps you trust, not to weaken the boot hook.
- **The bundled debug keystore is intentionally public.** It exists so
  the build is reproducible. **Do not** treat APK signature pinning
  with the debug keystore as a security boundary. If you want a
  signature-pinned trust path, build from source and sign with your
  own keystore.
