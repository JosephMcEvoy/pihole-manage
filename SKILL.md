---
name: pihole-manage
description: Comprehensive Pi-hole network ad blocker management skill. This skill should be used when users want to manage, configure, monitor, or troubleshoot their Pi-hole instance via the v6 REST API. Covers DNS blocking, allowlists/denylists, group management, client configuration, DHCP, statistics, query logs, gravity updates, teleporter backup/restore, custom DNS records, and system information.
metadata:
  author: joema
  version: "1.0.0"
  pihole_api_version: "v6"
---

# Pi-hole Management

Manage Pi-hole network ad blockers through the v6 REST API. This skill provides workflows for all Pi-hole management tasks including DNS blocking control, list management, statistics retrieval, client/group configuration, and system administration.

## When to Use This Skill

- Enabling/disabling DNS ad blocking (temporarily or permanently)
- Managing allowlists and denylists (add, remove, batch operations)
- Managing adlists (blocklist subscriptions)
- Viewing query logs and filtering DNS queries
- Retrieving statistics (top domains, top clients, query types, upstreams)
- Managing groups and assigning clients/domains/lists to groups
- Configuring custom DNS records (local DNS, CNAME)
- Managing DHCP leases
- Running gravity updates
- Backing up and restoring configuration (teleporter)
- Viewing system information, logs, and messages
- Searching domains across all lists
- Restarting DNS resolver
- Flushing logs, ARP cache, or network table

## Prerequisites

Before executing any API calls, determine the Pi-hole connection details:

1. **Base URL** - The Pi-hole address (e.g., `http://pi.hole`, `http://192.168.1.53`, or `https://pihole.local:443`)
2. **Password** - The admin password (or an application password generated from Settings in the web UI)
3. **HTTPS** - If using HTTPS with a self-signed cert, add `-k` to curl commands

If the user has not provided these details, ask for them before proceeding.

## Authentication Flow

The Pi-hole v6 API uses **session-based authentication**. A session ID (SID) must be obtained before making authenticated requests.

### Obtain a Session

```bash
curl -s -X POST "${PIHOLE_URL}/api/auth" \
  -H "Content-Type: application/json" \
  -d '{"password":"PASSWORD_HERE"}' | jq
```

Successful response:
```json
{
  "session": {
    "valid": true,
    "totp": false,
    "sid": "SESSION_ID_HERE",
    "csrf": "CSRF_TOKEN_HERE",
    "validity": 300
  }
}
```

If 2FA/TOTP is enabled, include the TOTP code:
```json
{"password":"PASSWORD_HERE", "totp": 123456}
```

### Using the Session ID

Include the SID in subsequent requests via one of these methods:

| Method | Example |
|--------|---------|
| Header | `-H "sid: SESSION_ID"` |
| Query param | `?sid=SESSION_ID` |
| Cookie | `-b "sid=SESSION_ID"` (also requires `-H "X-FTL-CSRF: CSRF_TOKEN"`) |

### End a Session

```bash
curl -s -X DELETE "${PIHOLE_URL}/api/auth" -H "sid: SESSION_ID"
```

### No-Password Mode

If no password is set on the Pi-hole, authentication is not required.

## Core Workflows

### Check/Toggle DNS Blocking

```bash
# Check current blocking status
curl -s "${PIHOLE_URL}/api/dns/blocking" -H "sid: ${SID}" | jq

# Disable blocking (indefinitely)
curl -s -X POST "${PIHOLE_URL}/api/dns/blocking" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"blocking": false}' | jq

# Disable blocking for N seconds (timer)
curl -s -X POST "${PIHOLE_URL}/api/dns/blocking" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"blocking": false, "timer": 300}' | jq

# Re-enable blocking
curl -s -X POST "${PIHOLE_URL}/api/dns/blocking" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"blocking": true}' | jq
```

### View Statistics Summary

```bash
curl -s "${PIHOLE_URL}/api/stats/summary" -H "sid: ${SID}" | jq
```

### Search a Domain Across All Lists

```bash
curl -s "${PIHOLE_URL}/api/search/example.com" -H "sid: ${SID}" | jq
```

### Run Gravity Update

```bash
curl -s -X POST "${PIHOLE_URL}/api/action/gravity" -H "sid: ${SID}" | jq
```

### Restart DNS Resolver

```bash
curl -s -X POST "${PIHOLE_URL}/api/action/restartdns" -H "sid: ${SID}" | jq
```

## Domain Management

Domains are organized by **type** (`allow` or `deny`) and **kind** (`exact` or `regex`).

Path pattern: `/api/domains/{type}/{kind}`

```bash
# List all exact deny entries
curl -s "${PIHOLE_URL}/api/domains/deny/exact" -H "sid: ${SID}" | jq

# Add a domain to the exact denylist
curl -s -X POST "${PIHOLE_URL}/api/domains/deny/exact" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"domain":"ads.example.com","comment":"Blocked manually"}' | jq

# Add a regex allowlist entry
curl -s -X POST "${PIHOLE_URL}/api/domains/allow/regex" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"domain":"(^|\\.)example\\.com$","comment":"Allow example.com and subdomains"}' | jq

# Remove a domain
curl -s -X DELETE "${PIHOLE_URL}/api/domains/deny/exact/ads.example.com" \
  -H "sid: ${SID}" | jq

# Batch delete domains
curl -s -X POST "${PIHOLE_URL}/api/domains:batchDelete" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '[{"domain":"a.example.com","type":"deny","kind":"exact"},{"domain":"b.example.com","type":"deny","kind":"exact"}]' | jq
```

## Adlist (Blocklist) Management

```bash
# List all adlists
curl -s "${PIHOLE_URL}/api/lists" -H "sid: ${SID}" | jq

# Add a new blocklist
curl -s -X POST "${PIHOLE_URL}/api/lists" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"address":"https://example.com/blocklist.txt","type":"block","enabled":true,"comment":"Custom blocklist"}' | jq

# Disable a list (PUT updates the existing entry)
curl -s -X PUT "${PIHOLE_URL}/api/lists/https%3A%2F%2Fexample.com%2Fblocklist.txt" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"enabled":false}' | jq

# Delete a list
curl -s -X DELETE "${PIHOLE_URL}/api/lists/https%3A%2F%2Fexample.com%2Fblocklist.txt" \
  -H "sid: ${SID}" | jq
```

After adding or removing lists, run a gravity update to apply changes.

## Group Management

```bash
# List all groups
curl -s "${PIHOLE_URL}/api/groups" -H "sid: ${SID}" | jq

# Create a group
curl -s -X POST "${PIHOLE_URL}/api/groups" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"name":"IoT Devices","comment":"Strict filtering for IoT"}' | jq

# Update a group
curl -s -X PUT "${PIHOLE_URL}/api/groups/IoT%20Devices" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"enabled":true,"comment":"Updated comment"}' | jq

# Delete a group
curl -s -X DELETE "${PIHOLE_URL}/api/groups/IoT%20Devices" -H "sid: ${SID}" | jq
```

## Client Management

```bash
# List all configured clients
curl -s "${PIHOLE_URL}/api/clients" -H "sid: ${SID}" | jq

# Get client suggestions (discovered but not configured)
curl -s "${PIHOLE_URL}/api/clients/_suggestions" -H "sid: ${SID}" | jq

# Add a client
curl -s -X POST "${PIHOLE_URL}/api/clients" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"client":"192.168.1.100","comment":"Living room TV","groups":["IoT Devices"]}' | jq

# Update client
curl -s -X PUT "${PIHOLE_URL}/api/clients/192.168.1.100" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"comment":"Updated","groups":["Default","IoT Devices"]}' | jq

# Delete a client
curl -s -X DELETE "${PIHOLE_URL}/api/clients/192.168.1.100" -H "sid: ${SID}" | jq
```

## Custom DNS Records

Custom local DNS entries are managed through the config API.

```bash
# Get all custom DNS host records
curl -s "${PIHOLE_URL}/api/config/dns.hosts" -H "sid: ${SID}" | jq

# Add a custom DNS record (IP + hostname, space-separated, URL-encoded)
curl -s -X PUT "${PIHOLE_URL}/api/config/dns/hosts/192.168.1.50%20myserver.local" \
  -H "sid: ${SID}" | jq

# Remove a custom DNS record
curl -s -X DELETE "${PIHOLE_URL}/api/config/dns/hosts/192.168.1.50%20myserver.local" \
  -H "sid: ${SID}" | jq

# Get CNAME records
curl -s "${PIHOLE_URL}/api/config/dns.cnameRecords" -H "sid: ${SID}" | jq
```

## Query Log

```bash
# Get recent queries
curl -s "${PIHOLE_URL}/api/queries" -H "sid: ${SID}" | jq

# Filter queries by domain
curl -s "${PIHOLE_URL}/api/queries?domain=example.com" -H "sid: ${SID}" | jq

# Filter by status (allowed, blocked, denylist, etc.)
curl -s "${PIHOLE_URL}/api/queries?status=denylist" -H "sid: ${SID}" | jq

# Include queries from long-term database
curl -s "${PIHOLE_URL}/api/queries?disk=true&domain=example.com" -H "sid: ${SID}" | jq

# Get query suggestions (autocomplete for query log search)
curl -s "${PIHOLE_URL}/api/queries/suggestions" -H "sid: ${SID}" | jq
```

## Statistics

For detailed endpoint parameters and response formats, see `references/api-endpoints.md`.

```bash
# Summary statistics
curl -s "${PIHOLE_URL}/api/stats/summary" -H "sid: ${SID}" | jq

# Top blocked/permitted domains
curl -s "${PIHOLE_URL}/api/stats/top_domains" -H "sid: ${SID}" | jq

# Top clients
curl -s "${PIHOLE_URL}/api/stats/top_clients" -H "sid: ${SID}" | jq

# Query types distribution
curl -s "${PIHOLE_URL}/api/stats/query_types" -H "sid: ${SID}" | jq

# Upstream DNS servers
curl -s "${PIHOLE_URL}/api/stats/upstreams" -H "sid: ${SID}" | jq

# Most recently blocked domain
curl -s "${PIHOLE_URL}/api/stats/recent_blocked" -H "sid: ${SID}" | jq

# Historical database stats (with time range)
curl -s "${PIHOLE_URL}/api/stats/database/summary?from=EPOCH&until=EPOCH" -H "sid: ${SID}" | jq
curl -s "${PIHOLE_URL}/api/stats/database/top_domains?from=EPOCH&until=EPOCH&count=10" -H "sid: ${SID}" | jq
curl -s "${PIHOLE_URL}/api/stats/database/top_clients?from=EPOCH&until=EPOCH&blocked=false&count=10" -H "sid: ${SID}" | jq
```

## System Information & Logs

```bash
# System info (CPU, memory, disk, uptime)
curl -s "${PIHOLE_URL}/api/info/system" -H "sid: ${SID}" | jq

# Pi-hole FTL version info
curl -s "${PIHOLE_URL}/api/info/version" -H "sid: ${SID}" | jq

# Host information
curl -s "${PIHOLE_URL}/api/info/host" -H "sid: ${SID}" | jq

# FTL engine info
curl -s "${PIHOLE_URL}/api/info/ftl" -H "sid: ${SID}" | jq

# Database info
curl -s "${PIHOLE_URL}/api/info/database" -H "sid: ${SID}" | jq

# Hardware sensors (temperature)
curl -s "${PIHOLE_URL}/api/info/sensors" -H "sid: ${SID}" | jq

# Client info (your connection)
curl -s "${PIHOLE_URL}/api/info/client" -H "sid: ${SID}" | jq

# Login page info (no auth required)
curl -s "${PIHOLE_URL}/api/info/login" | jq

# Prometheus-compatible metrics
curl -s "${PIHOLE_URL}/api/info/metrics" -H "sid: ${SID}"

# Messages/warnings from Pi-hole
curl -s "${PIHOLE_URL}/api/info/messages/count" -H "sid: ${SID}" | jq
curl -s "${PIHOLE_URL}/api/info/messages" -H "sid: ${SID}" | jq

# View logs
curl -s "${PIHOLE_URL}/api/logs/dnsmasq" -H "sid: ${SID}" | jq
curl -s "${PIHOLE_URL}/api/logs/ftl" -H "sid: ${SID}" | jq
curl -s "${PIHOLE_URL}/api/logs/webserver" -H "sid: ${SID}" | jq
```

## Network

```bash
# Network devices (ARP table)
curl -s "${PIHOLE_URL}/api/network/devices" -H "sid: ${SID}" | jq

# Gateway information
curl -s "${PIHOLE_URL}/api/network/gateway" -H "sid: ${SID}" | jq

# Routing table
curl -s "${PIHOLE_URL}/api/network/routes" -H "sid: ${SID}" | jq

# Network interfaces
curl -s "${PIHOLE_URL}/api/network/interfaces" -H "sid: ${SID}" | jq

# Delete a network device entry
curl -s -X DELETE "${PIHOLE_URL}/api/network/devices/DEVICE_ID" -H "sid: ${SID}" | jq
```

## DHCP

```bash
# List DHCP leases
curl -s "${PIHOLE_URL}/api/dhcp/leases" -H "sid: ${SID}" | jq

# Delete a DHCP lease
curl -s -X DELETE "${PIHOLE_URL}/api/dhcp/leases/192.168.1.100" -H "sid: ${SID}" | jq
```

## Configuration

```bash
# Get full configuration
curl -s "${PIHOLE_URL}/api/config" -H "sid: ${SID}" | jq

# Get specific config element
curl -s "${PIHOLE_URL}/api/config/dns.upstreams" -H "sid: ${SID}" | jq

# Update configuration (PATCH for partial updates)
curl -s -X PATCH "${PIHOLE_URL}/api/config" \
  -H "sid: ${SID}" -H "Content-Type: application/json" \
  -d '{"dns":{"upstreams":["8.8.8.8","8.8.4.4"]}}' | jq

# Set a specific config value
curl -s -X PUT "${PIHOLE_URL}/api/config/dns/upstreams/8.8.8.8" -H "sid: ${SID}" | jq

# Remove a specific config value
curl -s -X DELETE "${PIHOLE_URL}/api/config/dns/upstreams/8.8.8.8" -H "sid: ${SID}" | jq
```

## Teleporter (Backup/Restore)

```bash
# Export configuration backup (returns a .tar.gz file)
curl -s "${PIHOLE_URL}/api/teleporter" -H "sid: ${SID}" -o pihole-backup.tar.gz

# Import configuration backup
curl -s -X POST "${PIHOLE_URL}/api/teleporter" \
  -H "sid: ${SID}" \
  -F "file=@pihole-backup.tar.gz" | jq
```

## Maintenance Actions

```bash
# Update gravity (re-download all blocklists)
curl -s -X POST "${PIHOLE_URL}/api/action/gravity" -H "sid: ${SID}" | jq

# Restart DNS resolver
curl -s -X POST "${PIHOLE_URL}/api/action/restartdns" -H "sid: ${SID}" | jq

# Flush query logs
curl -s -X POST "${PIHOLE_URL}/api/action/flush/logs" -H "sid: ${SID}" | jq

# Flush ARP cache
curl -s -X POST "${PIHOLE_URL}/api/action/flush/arp" -H "sid: ${SID}" | jq

# Flush network table
curl -s -X POST "${PIHOLE_URL}/api/action/flush/network" -H "sid: ${SID}" | jq
```

## History

```bash
# Query history (over-time data for graphs)
curl -s "${PIHOLE_URL}/api/history" -H "sid: ${SID}" | jq

# Per-client history
curl -s "${PIHOLE_URL}/api/history/clients" -H "sid: ${SID}" | jq

# Database history (long-term)
curl -s "${PIHOLE_URL}/api/history/database" -H "sid: ${SID}" | jq
curl -s "${PIHOLE_URL}/api/history/database/clients" -H "sid: ${SID}" | jq
```

## PADD (Console Dashboard)

```bash
# Get PADD-formatted summary (text output for terminal dashboards)
curl -s "${PIHOLE_URL}/api/padd" -H "sid: ${SID}"
```

## Helper Script

A reusable shell script is available at `scripts/pihole-api.sh` that handles authentication and provides shorthand functions for common operations. Run it with `--help` for usage.

## Error Handling

All error responses follow this format:
```json
{
  "error": {
    "key": "unauthorized",
    "message": "Unauthorized",
    "hint": null
  }
}
```

Common error keys:
- `unauthorized` (401) - Missing or invalid session
- `bad_request` (400) - Invalid parameters
- `not_found` (404) - Resource does not exist
- `rate_limited` (429) - Too many requests

## Important Notes

- The Pi-hole self-hosts its own API docs at `/api/docs` matching its exact version
- Sessions expire after a configurable timeout; activity extends validity
- Sessions are bound to the client IP address
- URL-encode special characters in path parameters (e.g., list URLs, spaces in DNS entries)
- After adding/removing adlists, run gravity update to apply changes
- The `config` endpoint provides access to all Pi-hole settings including upstream DNS, DHCP config, rate limiting, privacy settings, and more
