;; SPDX-License-Identifier: PMPL-1.0-or-later
;; META.scm - Architectural decisions and project meta-information
;; Media-Type: application/meta+scheme

(define-meta pimcore-fortress
  (version "1.0.0")

  (architecture-decisions
    ;; ADR format: (adr-NNN status date context decision consequences)
    ((adr-001 accepted "2026-02-07"
      "Need a superhardened CMS for journalists and PR professionals"
      "Build on Pimcore CE with Lithoglyph storage and VerisimDB provenance"
      "Provides IP protection, tamper-proof chain of custody, and formal verification."
      "Requires integration of multiple hyperpolymath components.")
    (adr-002 accepted "2026-02-07"
      "Need formally verified container orchestration"
      "Use Svalinn gateway + Vordr runtime + Cerro Torre signed containers"
      "Zero-trust architecture with K9 policy enforcement."
      "Requires custom container tooling not yet widely adopted.")))

  (development-practices
    (code-style
      "PHP follows PSR-12 with Symfony conventions. "
      "Idris2 ABI with dependent type proofs. "
      "Zig FFI for C-compatible bindings.")
    (security
      "Zero-trust container architecture. "
      "Svalinn policy enforcement on every request. "
      "Proven safety modules (SafeJson, SafeUrl, SafeDigest). "
      "Hypatia neurosymbolic scanning enabled.")
    (testing
      "PHPStan static analysis. "
      "Integration tests for Lithoglyph and VerisimDB. "
      "Container verification via Cerro Torre.")
    (versioning
      "Semantic versioning (semver). "
      "Changelog maintained in CHANGELOG.md.")
    (documentation
      "README.adoc for overview. "
      "TOPOLOGY.md for architecture diagram and completion dashboard. "
      "STATE.scm for current state.")
    (branching
      "Main branch protected. "
      "Feature branches for new work. "
      "PRs required for merges."))

  (design-rationale
    (why-pimcore
      "Pimcore CE provides enterprise DAM/PIM/CMS/DXP in one platform, "
      "ideal for journalists and PR professionals managing media assets.")
    (why-lithoglyph
      "Content-addressable immutable storage provides cryptographic IP protection "
      "and prevents silent bit-rot or unauthorized modification.")
    (why-verisimdb
      "Federated truth ledger creates tamper-proof chain of custody "
      "that survives even if the organization's server is compromised.")))
