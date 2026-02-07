#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Pimcore Fortress - Verified Container Demo
#
# Demonstrates the complete verified container workflow:
# Client → Vörðr MCP → Container Operations

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

VORDR_ENDPOINT="http://localhost:8080"

mcp_call() {
    local method=$1
    local params=${2:-"{}"}
    local id=$RANDOM

    curl -s -X POST "$VORDR_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":$id,\"method\":\"$method\",\"params\":$params}"
}

demo_step() {
    echo -e "${BLUE}$1${NC}"
}

result_ok() {
    echo -e "${GREEN}✓ $1${NC}"
}

echo ""
echo "======================================"
echo "  Verified Container Demo"
echo "  Vörðr MCP Protocol"
echo "======================================"
echo ""

# Step 1: Health check
demo_step "1. Checking Vörðr health..."
response=$(mcp_call "health")
if echo "$response" | jq -e '.result.success == true' >/dev/null 2>&1; then
    result_ok "Vörðr is healthy"
    echo "$response" | jq '.result'
else
    echo "ERROR: Vörðr not healthy"
    exit 1
fi
echo ""

# Step 2: Version check
demo_step "2. Getting Vörðr version..."
response=$(mcp_call "version")
echo "$response" | jq '.result'
echo ""

# Step 3: List containers
demo_step "3. Listing containers..."
response=$(mcp_call "containers/list")
echo "$response" | jq '.result'
echo ""

# Step 4: List images
demo_step "4. Listing available images..."
response=$(mcp_call "images/list")
echo "$response" | jq '.result'
echo ""

# Step 5: Create container
demo_step "5. Creating container (alpine:latest)..."
response=$(mcp_call "containers/create" '{"image":"docker.io/library/alpine:latest","name":"fortress-demo"}')
echo "$response" | jq '.result'
result_ok "Container creation request sent"
echo ""

# Step 6: Start container
demo_step "6. Starting container..."
response=$(mcp_call "containers/start" '{"id":"fortress-demo"}')
echo "$response" | jq '.result'
result_ok "Container start request sent"
echo ""

# Step 7: Get container info
demo_step "7. Getting container info..."
response=$(mcp_call "containers/get" '{"id":"fortress-demo"}')
echo "$response" | jq '.result'
echo ""

# Step 8: Stop container
demo_step "8. Stopping container..."
response=$(mcp_call "containers/stop" '{"id":"fortress-demo"}')
echo "$response" | jq '.result'
result_ok "Container stop request sent"
echo ""

echo "======================================"
echo -e "${GREEN}✓ Demo Complete!${NC}"
echo "======================================"
echo ""
echo "What was demonstrated:"
echo "  • JSON-RPC 2.0 MCP protocol"
echo "  • Container lifecycle operations"
echo "  • Vörðr runtime communication"
echo "  • Type-safe structured requests"
echo ""
echo "Note: Responses are mock data (MVP mode)"
echo "      Real container operations coming soon"
echo ""
