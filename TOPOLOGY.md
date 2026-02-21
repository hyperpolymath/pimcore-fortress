<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# Pimcore Fortress — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              JOURNALIST / PRO           │
                        │        (DAM Studio / CMS Admin)         │
                        └───────────────────┬─────────────────────┘
                                            │ HTTPS + mTLS
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           SVALINN GATEWAY               │
                        │    (Policy Enforcement, HTTP Gating)    │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────────┐  ┌────────────────────────────────┐
                        │ VÖRÐR RUNTIME         │  │ SELUR IPC                      │
                        │ (Verified Containers) │  │ (WASM Bridge)                  │
                        └──────────┬────────────┘  └──────────┬─────────────────────┘
                                   │                          │
                                   └────────────┬─────────────┘
                                                ▼
                        ┌─────────────────────────────────────────┐
                        │           PIMCORE ECOSYSTEM             │
                        │    (PHP 8.3, Symfony 7, Proven Mods)    │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────────┐  ┌────────────────────────────────┐
                        │ LITHOGLYPH            │  │ VERISIMDB                      │
                        │ (Immutable Storage)   │  │ (Federated Truth Ledger)       │
                        │ - Content-addressed   │  │ - Provenance Claims            │
                        └───────────────────────┘  └────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Cerro Torre (.ctp) .machine_readable/  │
                        │  distroless build   0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CMS CORE
  Pimcore CE Setup                  ██████████ 100%    Production base stable
  Flysystem Adapter (Litho)         ██████████ 100%    Immutable storage verified
  VerisimDB Listener                ██████░░░░  60%    Provenance claims refining
  DAM Studio Customization          ████████░░  80%    Asset workflows verified

SECURITY & RUNTIME
  Svalinn Gate Integration          ██████████ 100%    Policy enforcement active
  Vörðr Verified Container          ██████████ 100%    Orchestration stable
  Proven Safety Modules             ██████████ 100%    SafeJson/Url/Digest verified
  Cerro Torre Signing               ██████████ 100%    Manifest integrity stable

REPO INFRASTRUCTURE
  Dockerfile (Distroless)           ██████████ 100%    Minimal attack surface verified
  .machine_readable/                ██████████ 100%    STATE tracking active
  Integration Test Suite            ████████░░  80%    E2E flows refining

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            █████████░  ~90%   v0.1.0 MVP Stable
```

## Key Dependencies

```
Svalinn Policy ───► Vörðr Runtime ───► Pimcore Engine ───► Lithoglyph
     │                 │                   │                 │
     ▼                 ▼                   ▼                 ▼
Cerro Torre (.ctp) ──► Proven Proofs ──► Event Listener ──► VerisimDB
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
