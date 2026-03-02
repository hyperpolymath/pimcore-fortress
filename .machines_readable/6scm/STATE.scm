;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Project state tracking for pimcore-fortress
;; Media-Type: application/vnd.state+scm

(define-state pimcore-fortress
  (metadata
    (version "0.1.0-alpha")
    (schema-version "1.0.0")
    (created "2026-02-07")
    (updated "2026-03-02")
    (project "pimcore-fortress")
    (repo "hyperpolymath/pimcore-fortress"))

  (project-context
    (name "pimcore-fortress")
    (tagline "Superhardened Pimcore CMS with formally verified container orchestration")
    (tech-stack ("PHP 8.3" "Symfony 7" "Pimcore CE" "Lithoglyph" "VerisimDB" "Svalinn" "Cerro Torre")))

  (current-position
    (phase "initial-setup")
    (overall-completion 15)
    (components
      ("svalinn-compose.yaml" "LithoglyphAdapter" "Dockerfile.pimcore"
       "composer.json" "docker-compose.yml" "nginx.conf"))
    (working-features
      ("Svalinn compose orchestration"
       "LithoglyphAdapter Flysystem bridge"
       "Distroless PHP 8.3 container build"
       "Architecture documentation")))

  (route-to-mvp
    (milestones
      ((name "Core Container Infrastructure")
       (status "in-progress")
       (completion 50)
       (items
         ("Create .ctp manifests for all services" . todo)
         ("Write nginx.conf for Pimcore" . done)
         ("Configure Flysystem in config/packages/flysystem.yaml" . done)
         ("Test svalinn-compose up locally" . todo)))))

  (blockers-and-issues
    (critical ())
    (high
      ("Lithoglyph and VerisimDB need HTTP API servers for integration testing"))
    (medium
      ("Cerro Torre .ctp manifest format not fully documented"))
    (low ()))

  (critical-next-actions
    (immediate
      "Create .ctp manifests for postgres, redis, nginx"
      "Test basic docker-compose.yml deployment")
    (this-week
      "Implement VerisimDB event listener"
      "Document Lithoglyph/VerisimDB API requirements")
    (this-month
      "Integrate php-aegis and sanctify-php"
      "Add claim-forge attestation"))

  (session-history
    ((date "2026-02-07")
     (agent "Claude Sonnet 4.5")
     (summary "Initial bootstrap: repo structure, svalinn-compose.yaml, LithoglyphAdapter, README"))
    ((date "2026-03-02")
     (agent "Claude Opus 4.6")
     (summary "RSR 3-axis audit: fixed SPDX headers, emails, template placeholders, SCM files, created .well-known/"))))

;; Helper functions
(define (get-completion-percentage state)
  (current-position 'overall-completion state))

(define (get-blockers state severity)
  (blockers-and-issues severity state))

(define (get-milestone state name)
  (find (lambda (m) (equal? (car m) name))
        (route-to-mvp 'milestones state)))
