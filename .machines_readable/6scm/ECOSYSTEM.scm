;; SPDX-License-Identifier: PMPL-1.0-or-later
;; ECOSYSTEM.scm - Ecosystem relationships for pimcore-fortress
;; Media-Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0.0")
  (name "pimcore-fortress")
  (type "application")
  (purpose "Superhardened Pimcore CMS with formally verified container orchestration for journalists and PR professionals")

  (position-in-ecosystem
    "A flagship integration project that brings together multiple "
    "hyperpolymath components into a production CMS deployment. "
    "Demonstrates the verified container ecosystem in a real use case.")

  (related-projects
    (dependency "lithoglyph" "Immutable content-addressable asset storage")
    (dependency "verisimdb" "Federated truth ledger for provenance claims")
    (dependency "svalinn" "Edge gateway with policy enforcement")
    (dependency "vordr" "Formally verified container runtime")
    (dependency "cerro-torre" "Container image builder with signing")
    (dependency "proven" "Formally verified safety modules (SafeJson, SafeUrl, etc.)")
    (sibling-standard "consent-aware-http" "GDPR-compliant HTTP handling")
    (sibling-standard "http-capability-gateway" "Capability-based security")
    (potential-consumer "claim-forge" "C2PA attestation generation"))

  (what-this-is
    "A superhardened Pimcore CMS ecosystem combining DAM/PIM/CMS with "
    "cryptographic IP protection (Lithoglyph), federated provenance (VerisimDB), "
    "and formally verified container orchestration (Svalinn/Vordr/Cerro Torre).")

  (what-this-is-not
    "This is not a standalone CMS - it requires the hyperpolymath verified "
    "container ecosystem components (Lithoglyph, VerisimDB, Svalinn, etc.) "
    "for its full security guarantees."))
