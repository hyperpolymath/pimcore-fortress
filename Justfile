# SPDX-License-Identifier: PMPL-1.0-or-later
# Justfile for pimcore-fortress

# Default recipe — list available commands
import? "contractile.just"
set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Self-diagnostic — checks dependencies, permissions, paths
doctor:
    @echo "Running diagnostics for pimcore-fortress..."
    @echo "Checking required tools..."
    @command -v just >/dev/null 2>&1 && echo "  [OK] just" || echo "  [FAIL] just not found"
    @command -v git >/dev/null 2>&1 && echo "  [OK] git" || echo "  [FAIL] git not found"
    @echo "Checking for hardcoded paths..."
    @grep -rn '/var/mnt/eclipse' --include='*.rs' --include='*.ex' --include='*.res' --include='*.gleam' --include='*.sh' --include='*.toml' . 2>/dev/null | grep -v 'Justfile' | head -5 || echo "  [OK] No hardcoded paths in source"
    @echo "Diagnostics complete."

# Guided tour of key features
tour:
    @echo "=== pimcore-fortress Tour ==="
    @echo ""
    @echo "1. Project structure:"
    @ls -la
    @echo ""
    @echo "2. Available commands: just --list"
    @echo ""
    @echo "3. Read README.adoc or README.md for full overview"
    @echo "4. Read EXPLAINME.adoc for architecture decisions"
    @echo "5. Run 'just doctor' to check your setup"
    @echo ""
    @echo "Tour complete! Try 'just --list' to see all available commands."

# Open feedback channel with diagnostic context
help-me:
    @echo "=== pimcore-fortress Help ==="
    @echo "Platform: $(uname -s) $(uname -m)"
    @echo "Shell: $SHELL"
    @echo ""
    @echo "To report an issue:"
    @echo "  https://github.com/hyperpolymath/pimcore-fortress/issues/new"
    @echo ""
    @echo "Include the output of 'just doctor' in your report."

# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "WARN: panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"

# LLM context dump
llm-context:
    @echo "Project: pimcore-fortress"
    @echo "License: PMPL-1.0-or-later"
    @test -f README.adoc && head -30 README.adoc || test -f README.md && head -30 README.md || echo "No README found"


# Print the current CRG grade (reads from READINESS.md '**Current Grade:** X' line)
crg-grade:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    echo "$$grade"

# Generate a shields.io badge markdown for the current CRG grade
# Looks for '**Current Grade:** X' in READINESS.md; falls back to X
crg-badge:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    case "$$grade" in \
      A) color="brightgreen" ;; B) color="green" ;; C) color="yellow" ;; \
      D) color="orange" ;; E) color="red" ;; F) color="critical" ;; \
      *) color="lightgrey" ;; esac; \
    echo "[![CRG $$grade](https://img.shields.io/badge/CRG-$$grade-$$color?style=flat-square)](https://github.com/hyperpolymath/standards/tree/main/component-readiness-grades)"

# Create secrets directory and generate passwords
setup:
    @echo "Creating secrets..."
    @mkdir -p secrets
    @if [ ! -f secrets/db_password.txt ]; then \
        echo "pimcore_secure_$$(openssl rand -hex 16)" > secrets/db_password.txt; \
        echo "Generated database password"; \
    fi
    @if [ ! -f secrets/database_url.txt ]; then \
        echo "postgresql://pimcore:$$(cat secrets/db_password.txt)@db:5432/pimcore" > secrets/database_url.txt; \
        echo "Generated database URL"; \
    fi
    @echo "Setup complete"

build-verified:
    @echo "Building verified containers with Cerro Torre..."
    @if command -v cerro-torre >/dev/null 2>&1; then \
        cerro-torre build --manifest .ctp/pimcore.ctp --sign; \
        cerro-torre build --manifest .ctp/nginx.ctp --sign; \
        cerro-torre build --manifest .ctp/postgres.ctp --sign; \
        echo "Verified build complete"; \
    else \
        echo "Cerro Torre not found"; \
        exit 1; \
    fi

build:
    @echo "Building Docker images (fallback mode)..."
    docker compose build
    @echo "Build complete"

up-verified: setup
    @echo "Starting Pimcore Fortress (verified mode)..."
    @if command -v svalinn-compose >/dev/null 2>&1; then \
        svalinn-compose up -d; \
        echo "Services started"; \
        echo "Access Pimcore Studio at: http://localhost:8080/admin"; \
    else \
        echo "Svalinn not found; run 'just up' for fallback mode"; \
        exit 1; \
    fi

up: setup
    @echo "Starting Pimcore Fortress (Docker Compose fallback)..."
    docker compose up -d
    @echo "Services started"
    @echo "Access Pimcore Studio at: http://localhost:8080/admin"

down:
    @echo "Stopping services..."
    @if command -v svalinn-compose >/dev/null 2>&1 && [ -f svalinn-compose.yaml ]; then \
        svalinn-compose down; \
    else \
        docker compose down; \
    fi
    @echo "Services stopped"

logs:
    docker compose logs -f

test:
    @echo "Running PHPStan..."
    @if [ -d vendor ]; then \
        composer test; \
    else \
        echo "Vendor directory not found. Run 'composer install' first."; \
        exit 1; \
    fi

install:
    @echo "Installing Pimcore..."
    @if ! docker ps | grep -q fortress-pimcore; then \
        echo "Pimcore container not running. Run 'just up' first."; \
        exit 1; \
    fi
    docker compose exec pimcore ./vendor/bin/pimcore-install
    @echo "Pimcore installed"

clean:
    @echo "Cleaning up..."
    docker compose down -v
    @echo "Cleanup complete"

composer-install:
    docker compose exec pimcore composer install

composer-update:
    docker compose exec pimcore composer update

shell:
    docker compose exec pimcore bash

db-shell:
    docker compose exec db psql -U pimcore
