# Pi-hole v6 API - Complete Endpoint Reference

All endpoints are relative to the Pi-hole base URL (e.g., `http://pi.hole`). Unless noted, endpoints require authentication via session ID (SID).

## Authentication

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/auth` | Check current session validity |
| POST | `/api/auth` | Create new session (login) |
| DELETE | `/api/auth` | End current session (logout, returns 410) |
| GET | `/api/auth/sessions` | List all active sessions |
| DELETE | `/api/auth/session/{id}` | Terminate a specific session |
| GET | `/api/auth/app` | Generate an application password |
| GET | `/api/auth/totp` | Generate TOTP secret for 2FA setup |

### POST /api/auth - Request Body

```json
{
  "password": "string (required)",
  "totp": 123456
}
```

### POST /api/auth - Response (200)

```json
{
  "session": {
    "valid": true,
    "totp": false,
    "sid": "string",
    "csrf": "string",
    "validity": 300
  }
}
```

### SID Transmission Methods

1. **Header**: `sid: VALUE` or `X-FTL-SID: VALUE`
2. **Query parameter**: `?sid=VALUE`
3. **JSON body field**: `"sid": "VALUE"`
4. **Cookie**: `sid=VALUE` (must also send `X-FTL-CSRF: CSRF_TOKEN` header)

---

## DNS Blocking

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/dns/blocking` | Get current blocking status |
| POST | `/api/dns/blocking` | Set blocking status |

### POST /api/dns/blocking - Request Body

```json
{
  "blocking": true,
  "timer": null
}
```

- `blocking` (boolean): Enable or disable blocking
- `timer` (integer, optional): Seconds until blocking reverts; `null` for permanent

---

## Domains (Allowlist / Denylist)

Path pattern: `/api/domains/{type}/{kind}` where:
- `{type}` = `allow` or `deny`
- `{kind}` = `exact` or `regex`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/domains/{type}/{kind}` | List all domains of this type/kind |
| POST | `/api/domains/{type}/{kind}` | Add a new domain entry |
| GET | `/api/domains/{type}/{kind}/{domain}` | Get a specific domain entry |
| PUT | `/api/domains/{type}/{kind}/{domain}` | Update a domain entry |
| DELETE | `/api/domains/{type}/{kind}/{domain}` | Remove a domain entry |
| POST | `/api/domains:batchDelete` | Batch delete multiple domain entries |

### POST /api/domains/{type}/{kind} - Request Body

```json
{
  "domain": "ads.example.com",
  "enabled": true,
  "comment": "optional comment",
  "groups": ["Default"]
}
```

### POST /api/domains:batchDelete - Request Body

```json
[
  {"domain": "a.example.com", "type": "deny", "kind": "exact"},
  {"domain": "b.example.com", "type": "deny", "kind": "exact"}
]
```

### Domain Types Reference

| Type | Kind | Description |
|------|------|-------------|
| `allow` | `exact` | Exact allowlist (whitelist) |
| `allow` | `regex` | Regex allowlist |
| `deny` | `exact` | Exact denylist (blacklist) |
| `deny` | `regex` | Regex denylist |

---

## Adlists (Blocklist Subscriptions)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/lists` | List all adlists |
| POST | `/api/lists` | Add a new adlist |
| GET | `/api/lists/{list}` | Get a specific adlist |
| PUT | `/api/lists/{list}` | Update an adlist |
| DELETE | `/api/lists/{list}` | Remove an adlist |
| POST | `/api/lists:batchDelete` | Batch delete adlists |

`{list}` is the URL-encoded address of the adlist.

### POST /api/lists - Request Body

```json
{
  "address": "https://example.com/blocklist.txt",
  "type": "block",
  "enabled": true,
  "comment": "optional comment",
  "groups": ["Default"]
}
```

List types: `block` (standard blocklist), `allow` (allowlist override)

---

## Groups

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/groups` | List all groups |
| POST | `/api/groups` | Create a new group |
| GET | `/api/groups/{name}` | Get a specific group |
| PUT | `/api/groups/{name}` | Update a group |
| DELETE | `/api/groups/{name}` | Delete a group |
| POST | `/api/groups:batchDelete` | Batch delete groups |

### POST /api/groups - Request Body

```json
{
  "name": "IoT Devices",
  "enabled": true,
  "comment": "optional comment"
}
```

---

## Clients

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/clients` | List all configured clients |
| POST | `/api/clients` | Add a new client |
| GET | `/api/clients/{client}` | Get a specific client |
| PUT | `/api/clients/{client}` | Update a client |
| DELETE | `/api/clients/{client}` | Remove a client |
| POST | `/api/clients:batchDelete` | Batch delete clients |
| GET | `/api/clients/_suggestions` | Get discovered but unconfigured clients |

`{client}` can be an IP address, CIDR range, MAC address, or hostname.

### POST /api/clients - Request Body

```json
{
  "client": "192.168.1.100",
  "comment": "Living room TV",
  "groups": ["Default", "IoT Devices"]
}
```

---

## Search

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/search/{domain}` | Search for a domain across all lists (allow, deny, adlists) |

Returns results showing where the domain appears and whether it would be blocked or allowed.

---

## Queries (DNS Query Log)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/queries` | Get DNS query log entries |
| GET | `/api/queries/suggestions` | Get autocomplete suggestions for query filtering |

### GET /api/queries - Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `domain` | string | Filter by domain name |
| `client` | string | Filter by client IP/name |
| `status` | string | Filter by status (e.g., `denylist`, `allowed`, `blocked`, `cached`) |
| `type` | string | Filter by query type (e.g., `A`, `AAAA`, `CNAME`) |
| `upstream` | string | Filter by upstream server |
| `disk` | boolean | Include long-term database queries (`true`/`false`) |
| `from` | integer | Start time (Unix epoch) |
| `until` | integer | End time (Unix epoch) |
| `length` | integer | Number of results to return |
| `cursor` | string | Pagination cursor |

---

## Statistics (Real-time)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/stats/summary` | Overall statistics summary |
| GET | `/api/stats/top_domains` | Top queried domains (allowed and blocked) |
| GET | `/api/stats/top_clients` | Top querying clients |
| GET | `/api/stats/query_types` | Query type distribution (A, AAAA, etc.) |
| GET | `/api/stats/upstreams` | Upstream DNS server usage |
| GET | `/api/stats/recent_blocked` | Most recently blocked domain |

### GET /api/stats/top_domains - Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `count` | integer | Number of results (default varies) |
| `blocked` | boolean | Filter to blocked (`true`) or permitted (`false`) domains |

### GET /api/stats/top_clients - Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `count` | integer | Number of results |
| `blocked` | boolean | Filter to blocked (`true`) or permitted (`false`) |

---

## Statistics (Database / Historical)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/stats/database/summary` | Historical summary |
| GET | `/api/stats/database/top_domains` | Historical top domains |
| GET | `/api/stats/database/top_clients` | Historical top clients |
| GET | `/api/stats/database/query_types` | Historical query types |
| GET | `/api/stats/database/upstreams` | Historical upstream usage |

### Common Query Parameters for Database Stats

| Parameter | Type | Description |
|-----------|------|-------------|
| `from` | integer | Start time (Unix epoch, required) |
| `until` | integer | End time (Unix epoch, required) |
| `count` | integer | Number of results |
| `blocked` | boolean | Filter by blocked status |

---

## History (Over-time Data)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/history` | Over-time query data (for graphs) |
| GET | `/api/history/clients` | Per-client over-time data |
| GET | `/api/history/database` | Long-term over-time data |
| GET | `/api/history/database/clients` | Long-term per-client data |

---

## System Information

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/info/client` | Current client connection info |
| GET | `/api/info/login` | Login page info (no auth required) |
| GET | `/api/info/system` | System info (CPU, memory, disk, uptime) |
| GET | `/api/info/database` | FTL database info |
| GET | `/api/info/sensors` | Hardware sensors (temperature) |
| GET | `/api/info/host` | Hostname and OS info |
| GET | `/api/info/ftl` | FTL engine details |
| GET | `/api/info/version` | Version information |
| GET | `/api/info/metrics` | Prometheus-compatible metrics (text format) |

---

## Messages

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/info/messages/count` | Count of pending messages/warnings |
| GET | `/api/info/messages` | List all messages |
| GET | `/api/info/messages/{message_id}` | Get a specific message |
| DELETE | `/api/info/messages/{message_id}` | Dismiss a message |

---

## Logs

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/logs/dnsmasq` | DNS resolver logs |
| GET | `/api/logs/ftl` | FTL engine logs |
| GET | `/api/logs/webserver` | Web server logs |

---

## Configuration

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/config` | Get full configuration |
| PATCH | `/api/config` | Partial configuration update |
| GET | `/api/config/{element}` | Get a specific config element (dot notation) |
| PUT | `/api/config/{element}/{value}` | Set a specific config value |
| DELETE | `/api/config/{element}/{value}` | Remove a specific config value |

### Common Config Paths

| Path | Description |
|------|-------------|
| `dns.upstreams` | Upstream DNS servers |
| `dns.hosts` | Custom local DNS records |
| `dns.cnameRecords` | CNAME records |
| `dns.port` | DNS listening port |
| `dns.listeningMode` | Listening mode (local, all, etc.) |
| `dhcp.active` | DHCP server enabled |
| `dhcp.start` | DHCP range start |
| `dhcp.end` | DHCP range end |
| `dhcp.router` | DHCP gateway |
| `dhcp.leaseTime` | DHCP lease duration |
| `webserver.api.localAPIauth` | Require auth for local API |
| `webserver.port` | Web interface port |
| `misc.privacylevel` | Privacy level (0-4) |

### Custom DNS Entry Format

Entries under `dns.hosts` use the format `IP HOSTNAME` (space-separated, URL-encoded as `IP%20HOSTNAME`).

```
PUT /api/config/dns/hosts/192.168.1.50%20myserver.local
DELETE /api/config/dns/hosts/192.168.1.50%20myserver.local
```

---

## Network

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/network/devices` | List network devices (ARP table) |
| DELETE | `/api/network/devices/{device_id}` | Remove a device entry |
| GET | `/api/network/gateway` | Gateway information |
| GET | `/api/network/routes` | Routing table |
| GET | `/api/network/interfaces` | Network interfaces |

---

## DHCP

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/dhcp/leases` | List all DHCP leases |
| DELETE | `/api/dhcp/leases/{ip}` | Delete a specific lease |

---

## Actions

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/action/gravity` | Update gravity (re-download blocklists) |
| POST | `/api/action/restartdns` | Restart the DNS resolver |
| POST | `/api/action/flush/logs` | Flush query logs |
| POST | `/api/action/flush/arp` | Flush ARP cache |
| POST | `/api/action/flush/network` | Flush network table |

---

## Teleporter (Backup / Restore)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/teleporter` | Export configuration backup (.tar.gz) |
| POST | `/api/teleporter` | Import configuration backup (multipart form) |

### Import Example

```bash
curl -X POST "${PIHOLE_URL}/api/teleporter" \
  -H "sid: ${SID}" \
  -F "file=@pihole-backup.tar.gz"
```

---

## Utility

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/endpoints` | List all available API endpoints |
| GET | `/api/docs` | Interactive API documentation (OpenAPI/Swagger UI) |
| GET | `/api/padd` | PADD-formatted text summary for terminal dashboards |

---

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Resource created |
| 204 | Success, no content (e.g., delete) |
| 400 | Bad request (invalid parameters) |
| 401 | Unauthorized (missing/invalid session) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not found |
| 410 | Gone (session terminated) |
| 429 | Rate limited |
| 5xx | Server error |

## Error Response Format

```json
{
  "error": {
    "key": "string",
    "message": "string",
    "hint": "string or null"
  }
}
```
