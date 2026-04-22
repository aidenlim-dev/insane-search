# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] — 2026-04-22

### Added
- **`engine/` Python package** — single public entrypoint (`python3 -m engine URL` or `from engine import fetch`) that runs an exhaustive curl_cffi grid over WAF product profiles.
  - `fetch_chain.py` — grid scheduler with internal phases (probe → validate → detect → plan → execute → report), per-attempt jitter, and `FetchResult.trace[]` for diagnostics.
  - `validators.py` — 4-layer challenge classifier (`STRONG_OK / WEAK_OK / CHALLENGE / BLOCKED / UNKNOWN`) replacing naive HTTP 200 heuristics.
  - `waf_detector.py` — ranked `[(profile_id, confidence)]` detection with sticky `last_load_error()` for loader diagnostics.
  - `waf_profiles.yaml` — seven product profiles (`akamai_bot_manager`, `cloudflare_turnstile`, `f5_big_ip`, `aws_waf`, `datadome_probable`, `perimeterx_human`, `unknown_challenge`) with 25+ curl_cffi impersonate candidates and an empirically-derived `tls_impersonate_avoid` list.
  - `url_transforms.py` — generic URL mutations (`original`, `mobile_subdomain`, `am_prefix`, `drop_www`), no site-specific branches.
  - `executor.py` — capability-matched Playwright router, honours each profile's `fallback_when_challenge` ordering.
  - `templates/playwright_real_chrome.js` — Local Node + `channel:'chrome'` + stealth + persistent context, with home warmup and reload-retry against Akamai-grade WAFs.
  - `templates/playwright_mobile_chrome.js` — `devices[...]` emulation while keeping real-Chrome TLS.
  - `bias_check.py` — CI linter enforcing the No-Site-Name Rule via brand denylist + URL/domain regex, with `node_modules`/build-artefact exclusion.
  - `tests/test_smoke.py` — unit + online smoke coverage for validators, profile loader, URL transforms, and network round-trips.
- **SKILL.md harness rules R1–R7** — explicit constraints that keep Claude from improvising around the engine:
  - R1 CLI-first on any blocked URL
  - R2 no early break on HTTP 200
  - R3 No-Site-Name enforcement
  - R4 runtime-only hints
  - R5 Phase 0 official APIs take precedence
  - R6 exhaustive grid before declaring failure
  - **R7 — API-first parallel branch** when a WAF is detected early and the user intent is list/collect: engine keeps running in background while Claude reconnoiters via Playwright MCP `browser_network_requests` to discover internal JSON endpoints, then re-fetches via engine.
- **Full `references/` index (12/12 files)** grouped by role (engine extension, lightweight alternatives, platform APIs, in-tree code) with "when to read" + "what it covers" per entry.
- **`references/playwright.md`** rewritten as Approach 1 (MCP Chromium — Cloudflare-grade) vs Approach 2 (Local Node `channel:'chrome'` + stealth — Akamai-grade), selection driven automatically by profile `capabilities_needed` tags.

### Changed
- `plugin.json` version bumped to `0.4.0` (new public surface + new behavior justify minor bump).
- Graceful degradation paths for missing `PyYAML`, `curl_cffi`, `bs4`, or Node — failures surface as `UNKNOWN` verdicts + trace entries, never silently swallow.
- Per-attempt jitter between curl grid calls, env-tunable via `INSANE_JITTER_MS_MIN` / `INSANE_JITTER_MS_MAX`.

### Notes
- No site-specific logic is introduced anywhere in `engine/**` or `waf_profiles.yaml`; all site knowledge enters at call time (`success_selectors`, `user_hint`) or stays in comments / docs.
- Earlier history kept in git log.

## Earlier releases

Pre-0.4.0 history is documented in git commits only; no structured changelog was maintained before this release.
