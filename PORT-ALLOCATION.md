# Pimcore Fortress Port Allocation

**Date:** 2026-02-07
**Status:** Configured for full stack deployment

---

## Port Map

| Service | Port | Status | Purpose |
|---------|------|--------|---------|
| **Vörðr MCP** | 8080 | ✅ Running | Container runtime (JSON-RPC 2.0) |
| **Svalinn Gateway** | 8000 | ✅ Running | Edge gateway + policy enforcement |
| **Lithoglyph** | 8082 | ⏳ To deploy | Immutable block storage (HTTP API) |
| **VerisimDB** | 9090 | ⏳ Building | Provenance ledger (SPARQL/HTTP) |
| **PostgreSQL** | 5432 | ✅ Running | Relational database (SQL) |
| **Redis** | 6379 | ✅ Running | Cache + session store (Redis protocol) |
| **Pimcore Web** | 8081 | ⏳ To deploy | PHP application (HTTP) |

---

## Architecture Diagram

```
                    ┌──────────────────┐
                    │  Users/Browsers  │
                    └────────┬─────────┘
                             │ HTTP
                    ┌────────▼─────────┐
                    │  Pimcore Web     │
                    │    Port 8081     │
                    └────────┬─────────┘
                             │
         ┌───────────────────┼────────────────────┐
         │                   │                    │
         │                   │                    │
    ┌────▼────┐         ┌────▼────┐         ┌────▼─────┐
    │PostgreSQL│        │  Redis  │         │Lithoglyph│
    │  5432   │        │  6379   │         │  8082    │
    └────┬────┘        └────┬────┘         └────┬─────┘
         │                   │                   │
         └───────────────────┴───────────────────┘
                             │
                             │ (Provenance events)
                             │
                    ┌────────▼─────────┐
                    │   VerisimDB      │
                    │    Port 9090     │
                    └──────────────────┘

───────────────────────────────────────────────────────
              VERIFIED CONTAINER LAYER
───────────────────────────────────────────────────────

                    ┌──────────────────┐
                    │ Svalinn Gateway  │
                    │   Port 8000      │
                    └────────┬─────────┘
                             │ JSON-RPC 2.0
                    ┌────────▼─────────┐
                    │  Vörðr Runtime   │
                    │   Port 8080      │
                    └──────────────────┘
```

---

## Service Details

### Vörðr Container Runtime (Port 8080)

**Purpose:** MCP-based container runtime
**Protocol:** JSON-RPC 2.0 over HTTP
**Process:** Deno (TypeScript)
**Location:** `~/Documents/hyperpolymath-repos/vordr/src/mcp-adapter/`
**PID:** `/tmp/vordr-mcp.pid`
**Log:** `/tmp/vordr-mcp.log`

**Methods:**
- `ping` - Health check
- `health` - System health
- `containers/list` - List containers
- `containers/start` - Start container
- `containers/stop` - Stop container
- `images/list` - List images
- `version` - Runtime version

**Start:**
```bash
cd ~/Documents/hyperpolymath-repos/vordr/src/mcp-adapter/
deno run --allow-net --allow-read --allow-env http-server.ts
```

---

### Svalinn Edge Gateway (Port 8000)

**Purpose:** REST API → MCP protocol translation
**Protocol:** HTTP REST + JSON Schema validation
**Process:** Deno (ReScript compiled to JS)
**Location:** `~/Documents/hyperpolymath-repos/svalinn/`
**Config:** Environment variables

**Environment:**
```bash
export SVALINN_PORT=8000
export VORDR_ENDPOINT=http://localhost:8080
export AUTH_ENABLED=false  # Development mode
```

**Start:**
```bash
cd ~/Documents/hyperpolymath-repos/svalinn/
deno task start
```

**Endpoints:**
- `GET /health` - Health check
- `POST /containers/create` - Create container
- `POST /containers/{id}/start` - Start container
- `POST /containers/{id}/stop` - Stop container
- `GET /containers` - List containers

---

### Lithoglyph Immutable Storage (Port 8082)

**Purpose:** Content-addressable block storage
**Protocol:** HTTP JSON API
**Process:** Zig native binary
**Location:** `~/Documents/hyperpolymath-repos/lithoglyph/`
**Storage:** `~/Documents/hyperpolymath-repos/lithoglyph/demo.lgh`

**Endpoints:**
- `POST /insert` - Insert data, returns SHA-256
- `GET /block/{hash}` - Retrieve by content hash
- `GET /health` - Health check
- `GET /version` - Version info
- `GET /schema` - JSON schema

**Start:**
```bash
cd ~/Documents/hyperpolymath-repos/lithoglyph/
LITHOGLYPH_PORT=8082 ./demo-server
```

**Note:** Port changed from 8080 to 8082 to avoid conflict with Vörðr.

---

### VerisimDB Provenance Ledger (Port 9090)

**Purpose:** Federated truth ledger with RDF + tensor embeddings
**Protocol:** HTTP + SPARQL
**Process:** Rust binary
**Location:** `~/Documents/hyperpolymath-repos/verisimdb/`
**Storage:** RocksDB + Sophia RDF + Tantivy search

**Capabilities:**
- SPARQL INSERT/SELECT for provenance tracking
- Tensor semantic embeddings (Burn framework)
- Temporal drift detection
- Immutable audit trail

**Start:**
```bash
cd ~/Documents/hyperpolymath-repos/verisimdb/
./target/release/verisimdb --port 9090
```

**Example SPARQL:**
```sparql
INSERT DATA {
  <urn:asset:42> <prov:wasGeneratedBy> <urn:upload:12345> .
  <urn:upload:12345> <prov:wasAssociatedWith> <urn:user:alice> .
  <urn:upload:12345> <prov:atTime> "2026-02-07T14:30:00Z" .
  <urn:asset:42> <crypto:sha256> "7f83b165..." .
}
```

---

### PostgreSQL Database (Port 5432)

**Purpose:** Primary relational database
**Protocol:** PostgreSQL wire protocol
**Process:** PostgreSQL 17
**Container:** `docker.io/postgres:17-alpine`
**Storage:** Volume-mounted

**Start:**
```bash
cd /mnt/eclipse/repos/pimcore-fortress/
podman-compose -f docker-compose.dev.yml up -d db
```

**Credentials:**
- User: `pimcore`
- Password: `pimcore`
- Database: `pimcore`

---

### Redis Cache (Port 6379)

**Purpose:** Session storage + caching
**Protocol:** Redis wire protocol
**Process:** Redis 7
**Container:** `docker.io/redis:7-alpine`
**Storage:** In-memory (no persistence in dev)

**Start:**
```bash
cd /mnt/eclipse/repos/pimcore-fortress/
podman-compose -f docker-compose.dev.yml up -d redis
```

---

### Pimcore Fortress CMS (Port 8081)

**Purpose:** Digital Asset Management web interface
**Protocol:** HTTP (PHP-FPM + Nginx)
**Process:** PHP 8.3 + Symfony
**Location:** `/mnt/eclipse/repos/pimcore-fortress/`

**Environment:**
```env
DATABASE_URL="postgresql://pimcore:pimcore@localhost:5432/pimcore"
REDIS_URL="redis://localhost:6379"
LITHOGLYPH_API_URL="http://localhost:8082"
VERISIMDB_ENDPOINT="http://localhost:9090/sparql"
APP_ENV=dev
```

**Start:**
```bash
cd /mnt/eclipse/repos/pimcore-fortress/
php -S localhost:8081 -t public/
# Or with Symfony CLI:
symfony server:start --port=8081
```

---

## Port Conflict Resolution

### Original Issue
- Lithoglyph demo-server defaulted to port 8080
- Vörðr MCP server requires port 8080
- **Conflict:** Both services cannot run simultaneously on same port

### Solution
- Vörðr: Keep on 8080 (MCP protocol standard)
- Lithoglyph: Move to 8082 (configure via `LITHOGLYPH_PORT` env var)
- All services can now coexist

---

## Network Flow

### Asset Upload Flow

```
User Browser (Web)
    │
    ▼ HTTP POST /asset/upload
Pimcore (8081)
    │
    ├──► PostgreSQL (5432) - Store metadata
    │    └─► Returns: asset_id
    │
    ├──► Lithoglyph (8082) - Store file
    │    └─► POST /insert → SHA-256 hash
    │
    ├──► PostgreSQL (5432) - Update with hash
    │
    └──► VerisimDB (9090) - Record provenance
         └─► SPARQL INSERT → Immutable record
```

### Asset Retrieval Flow

```
User Browser (Web)
    │
    ▼ HTTP GET /asset/42/view
Pimcore (8081)
    │
    ├──► Redis (6379) - Check cache
    │    └─► Cache MISS
    │
    ├──► PostgreSQL (5432) - Get SHA-256
    │    └─► Returns: "sha256:7f83..."
    │
    ├──► Lithoglyph (8082) - Get content
    │    └─► GET /block/sha256:7f83...
    │
    └──► Redis (6379) - Cache result
         └─► SET with TTL 3600s
```

---

## Firewall Rules (If Needed)

```bash
# Allow services (if firewalld is active)
sudo firewall-cmd --add-port=8000/tcp --permanent  # Svalinn
sudo firewall-cmd --add-port=8080/tcp --permanent  # Vörðr
sudo firewall-cmd --add-port=8081/tcp --permanent  # Pimcore
sudo firewall-cmd --add-port=8082/tcp --permanent  # Lithoglyph
sudo firewall-cmd --add-port=9090/tcp --permanent  # VerisimDB
sudo firewall-cmd --reload
```

---

## Service Start Order

**Correct startup sequence:**

1. **Infrastructure Layer**
   ```bash
   # Start databases
   podman-compose -f docker-compose.dev.yml up -d db redis
   ```

2. **Container Runtime Layer**
   ```bash
   # Start Vörðr (background)
   cd ~/Documents/hyperpolymath-repos/vordr/src/mcp-adapter/
   nohup deno run --allow-net --allow-read --allow-env http-server.ts > /tmp/vordr-mcp.log 2>&1 &
   echo $! > /tmp/vordr-mcp.pid

   # Start Svalinn (background)
   cd ~/Documents/hyperpolymath-repos/svalinn/
   AUTH_ENABLED=false deno task start &
   ```

3. **Storage Layer**
   ```bash
   # Start Lithoglyph
   cd ~/Documents/hyperpolymath-repos/lithoglyph/
   LITHOGLYPH_PORT=8082 ./demo-server &

   # Start VerisimDB
   cd ~/Documents/hyperpolymath-repos/verisimdb/
   ./target/release/verisimdb --port 9090 &
   ```

4. **Application Layer**
   ```bash
   # Start Pimcore
   cd /mnt/eclipse/repos/pimcore-fortress/
   symfony server:start --port=8081 --daemon
   # Or: php -S localhost:8081 -t public/
   ```

---

## Health Check Commands

```bash
# Vörðr
curl -X POST http://localhost:8080 -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"ping"}'

# Svalinn
curl http://localhost:8000/health

# Lithoglyph
curl http://localhost:8082/health

# VerisimDB
curl http://localhost:9090/health  # (when implemented)

# PostgreSQL
psql -h localhost -U pimcore -d pimcore -c "SELECT version();"

# Redis
redis-cli -h localhost -p 6379 ping

# Pimcore
curl http://localhost:8081/
```

---

## Status: ✅ CONFIGURED

All port allocations resolved. Services ready for deployment.
