# SPDX-License-Identifier: PMPL-1.0-or-later
# Pimcore Fortress - Makefile

.PHONY: help setup build up down logs test clean secrets install

# Default target
help:
	@echo "Pimcore Fortress - Superhardened CMS Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  setup           - Create secrets and initial configuration"
	@echo "  build           - Build Docker images (fallback mode)"
	@echo "  build-verified  - Build verified .ctp containers via Cerro Torre"
	@echo "  up              - Start services (Docker Compose fallback)"
	@echo "  up-verified     - Start services via Svalinn"
	@echo "  down            - Stop services"
	@echo "  logs            - Tail container logs"
	@echo "  test            - Run PHPStan static analysis"
	@echo "  clean           - Remove containers and volumes"
	@echo "  install         - Install Pimcore (after 'up')"
	@echo ""

# Create secrets directory and generate passwords
setup:
	@echo "🔐 Creating secrets..."
	@mkdir -p secrets
	@if [ ! -f secrets/db_password.txt ]; then \
		echo "pimcore_secure_$$(openssl rand -hex 16)" > secrets/db_password.txt; \
		echo "✅ Generated database password"; \
	fi
	@if [ ! -f secrets/database_url.txt ]; then \
		echo "postgresql://pimcore:$$(cat secrets/db_password.txt)@db:5432/pimcore" > secrets/database_url.txt; \
		echo "✅ Generated database URL"; \
	fi
	@echo "✅ Setup complete"

# Build verified containers using Cerro Torre
build-verified:
	@echo "🏗️  Building verified containers with Cerro Torre..."
	@if command -v cerro-torre >/dev/null 2>&1; then \
		cerro-torre build --manifest .ctp/pimcore.ctp --sign && \
		cerro-torre build --manifest .ctp/nginx.ctp --sign && \
		cerro-torre build --manifest .ctp/postgres.ctp --sign && \
		echo "✅ Verified build complete"; \
	else \
		echo "❌ Cerro Torre not found. Install from: https://github.com/hyperpolymath/cerro-torre"; \
		exit 1; \
	fi

# Build standard Docker images (fallback)
build:
	@echo "🏗️  Building Docker images (fallback mode)..."
	docker compose build
	@echo "✅ Build complete"

# Start services via Svalinn (verified mode)
up-verified: setup
	@echo "🚀 Starting Pimcore Fortress (verified mode)..."
	@if command -v svalinn-compose >/dev/null 2>&1; then \
		svalinn-compose up -d && \
		echo "✅ Services started"; \
		echo "📊 Access Pimcore Studio at: http://localhost:8080/admin"; \
	else \
		echo "❌ Svalinn not found. Install from: https://github.com/hyperpolymath/svalinn"; \
		echo "💡 Use 'make up' for fallback Docker Compose mode"; \
		exit 1; \
	fi

# Start services via Docker Compose (fallback)
up: setup
	@echo "🚀 Starting Pimcore Fortress (Docker Compose fallback)..."
	docker compose up -d
	@echo "✅ Services started"
	@echo "📊 Access Pimcore Studio at: http://localhost:8080/admin"

# Stop services
down:
	@echo "🛑 Stopping services..."
	@if command -v svalinn-compose >/dev/null 2>&1 && [ -f svalinn-compose.yaml ]; then \
		svalinn-compose down; \
	else \
		docker compose down; \
	fi
	@echo "✅ Services stopped"

# View logs
logs:
	docker compose logs -f

# Run PHPStan static analysis
test:
	@echo "🔍 Running PHPStan..."
	@if [ -d vendor ]; then \
		composer test; \
	else \
		echo "❌ Vendor directory not found. Run 'composer install' first."; \
		exit 1; \
	fi

# Install Pimcore (run after 'up')
install:
	@echo "📦 Installing Pimcore..."
	@if ! docker ps | grep -q fortress-pimcore; then \
		echo "❌ Pimcore container not running. Run 'make up' first."; \
		exit 1; \
	fi
	docker compose exec pimcore ./vendor/bin/pimcore-install
	@echo "✅ Pimcore installed"
	@echo "🔑 Create admin user and configure system via web UI"

# Clean up containers and volumes
clean:
	@echo "🧹 Cleaning up..."
	docker compose down -v
	@echo "✅ Cleanup complete"

# Development helpers
composer-install:
	docker compose exec pimcore composer install

composer-update:
	docker compose exec pimcore composer update

shell:
	docker compose exec pimcore bash

db-shell:
	docker compose exec db psql -U pimcore
