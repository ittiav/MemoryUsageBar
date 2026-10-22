# Changelog

## 1.0.0 — 2026-10-22

- Initial native macOS application with a universal Apple Silicon and Intel binary.
- Show `内存 65%` to the right of the camera notch, with the percentage in green.
- Refresh every 60 seconds, after wake, or on request.
- Read physical memory usage using Mach VM statistics and the system page size.
- Adapt to screen geometry, display changes, and non-notch displays.
- Add optional launch at login, a custom memory-chip logo, and English documentation.
