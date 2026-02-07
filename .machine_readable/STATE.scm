;; SPDX-License-Identifier: PMPL-1.0-or-later
;; pimcore-fortress STATE.scm
;; Last updated: 2026-02-07

(state
  (metadata
    (name "pimcore-fortress")
    (version "0.1.0-alpha")
    (status "bootstrapping")
    (last-updated "2026-02-07T12:50:00Z"))

  (project-context
    (purpose "Superhardened Pimcore CMS with formally verified container orchestration")
    (target-users
      "journalists"
      "lens-based professionals"
      "PR/communications teams")
    (core-technologies
      "Pimcore Community Edition"
      "Lithoglyph (immutable storage)"
      "VerisimDB (federated truth)"
      "Svalinn (gateway)"
      "Vörðr (container runtime)"
      "Cerro Torre (image builder)"))

  (current-position
    (completion-percentage 15)
    (phase "initial-setup")
    (what-works
      "svalinn-compose.yaml configuration"
      "LithoglyphAdapter Flysystem bridge"
      "Dockerfile.pimcore distroless build"
      "composer.json with free Pimcore modules"
      "README.adoc with architecture docs")
    (what-doesnt-work-yet
      "VerisimDB event listener not implemented"
      "Cerro Torre .ctp manifests not created"
      "No actual Pimcore installation yet"
      "Secrets management not configured"
      "nginx config not created"
      "No integration tests"))

  (route-to-mvp
    (milestone-1
      (name "Core Container Infrastructure")
      (tasks
        "Create .ctp manifests for all services"
        "Write nginx.conf for Pimcore"
        "Configure Flysystem in config/packages/flysystem.yaml"
        "Test svalinn-compose up locally"))
    (milestone-2
      (name "Pimcore Installation")
      (tasks
        "Run composer install"
        "Execute pimcore:install wizard"
        "Create admin user"
        "Test Pimcore Studio UI"))
    (milestone-3
      (name "Lithoglyph Integration")
      (tasks
        "Test LithoglyphAdapter with mock API"
        "Upload test asset via Pimcore DAM"
        "Verify content-addressable storage"
        "Test asset retrieval"))
    (milestone-4
      (name "VerisimDB Integration")
      (tasks
        "Implement VerisimProvenanceListener"
        "Test provenance claim broadcast"
        "Verify federated storage"
        "Test claim retrieval"))
    (milestone-5
      (name "Security Hardening")
      (tasks
        "Integrate php-aegis"
        "Integrate sanctify-php"
        "Add claim-forge attestation"
        "Implement K9 policy enforcement")))

  (blockers-and-issues
    (blocker-1
      (severity "high")
      (description "Lithoglyph and VerisimDB need HTTP API servers")
      (impact "Cannot test integration without running APIs")
      (possible-solutions
        "Add HTTP server layer to Lithoglyph"
        "Add HTTP server layer to VerisimDB"
        "Create mock API servers for testing"))
    (blocker-2
      (severity "medium")
      (description "Cerro Torre .ctp manifest format not fully documented")
      (impact "Cannot build verified containers yet")
      (possible-solutions
        "Study existing .ctp manifests in cerro-torre repo"
        "Create minimal .ctp for testing"
        "Fallback to standard Docker during development")))

  (critical-next-actions
    (priority-1 "Create nginx.conf for Pimcore")
    (priority-2 "Write .ctp manifests for postgres, redis, nginx")
    (priority-3 "Create flysystem.yaml config")
    (priority-4 "Test basic docker-compose.yml deployment")
    (priority-5 "Document Lithoglyph/VerisimDB API requirements"))

  (session-history
    (session
      (date "2026-02-07")
      (agent "Claude Sonnet 4.5")
      (summary "Initial bootstrap: created repo structure, svalinn-compose.yaml, LithoglyphAdapter, README, AI manifest")
      (outcomes
        "Foundation established"
        "Architecture documented"
        "Integration points identified"))))
