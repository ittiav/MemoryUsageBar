# Security review

Reviewed locally on 2026-10-22, before the initial upload. This is a scoped source and artifact review, not a third-party security audit.

## Scope and findings

- Reviewed all application sources, Info.plist, icon generator, build/test scripts, and GitHub Actions workflow. No embedded API keys, access tokens, passwords, account files, or private keys were found. The workflow references GitHub's ephemeral `github.token`; no token value is stored in the repository.
- The application has no networking code, external process execution, telemetry, remote configuration, package dependencies, or sample persistence. Its memory reads are local Mach calls. It checks only same-bundle running instances to avoid duplicate overlays.
- No Accessibility, Screen Recording, camera, microphone, administrator, or special entitlement request is present. The signed bundle has no custom entitlements. The app is not App Sandbox confined; it runs with the current user's normal privileges.
- Launch at login is disabled by default. Registration/unregistration happens only after choosing the menu item, uses Apple's `SMAppService`, and reports errors. No LaunchAgent files are installed by the build scripts.
- The build runs checked-in Swift sources and Apple toolchain commands. It does not download dependencies. The icon generator writes only generated icons under the project. The scripts quote paths, stop on failures, and do not remove user files.
- CI actions are pinned to verified full commit SHAs. Checkout does not persist credentials. The build job has read-only repository permissions; only a separate release job triggered by a pushed version tag has contents-write permission. The tag is passed as an environment variable and shell-quoted. Pull-request builds cannot run the release job.
- The app archive includes only the bundle executable, Info.plist, icon, and code signature. The source archive is generated from tracked repository files. Module caches, local Git history, build logs, test executables, and other workspace files are excluded from source and app archives.

## Verification

- Built and verified an ad hoc signed universal binary containing arm64 and x86_64 slices with a macOS 13 minimum deployment target.
- Tests passed for 4 KiB and 16 KiB memory page sizes, bounds, rounding, notch geometry, non-notch fallback, and live memory sampling.
- Launched the app on the local Apple Silicon Mac. Accessibility inspection confirmed the Chinese label and percentage; a panel screenshot confirmed the green percentage. No Intel Mac hardware test has been performed.
- Launch-at-login approval, full-screen display behavior, crowded status menus, and every display configuration have not been exhaustively tested.

## Distribution limits

The app is ad hoc signed, not Developer ID signed or notarized. Checksums verify archive integrity, not publisher identity. A floating panel does not reserve system menu-bar space, so crowded status menus can overlap it. No claim is made that used-memory percentage is equivalent to memory pressure.
