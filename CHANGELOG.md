# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-02-07

### Added

- SKILL.md with complete Pi-hole v6 API workflow instructions
- Full API endpoint reference covering 70+ endpoints (`references/api-endpoints.md`)
- Reusable shell helper script with 50+ commands (`scripts/pihole-api.sh`)
- Session-based authentication flow with SID management
- jq with Python 3 fallback for JSON parsing (cross-platform)
- DNS blocking control (enable, disable, timed disable)
- Domain management (allow/deny, exact/regex, batch delete)
- Adlist (blocklist subscription) management
- Group and client management
- Custom DNS record management (local DNS, CNAME)
- Statistics retrieval (summary, top domains/clients, query types, upstreams)
- Historical database statistics with time range filtering
- Query log search and filtering
- DHCP lease management
- System information (CPU, memory, sensors, version, host)
- Log retrieval (dnsmasq, FTL, webserver)
- Network information (devices, gateway, routes, interfaces)
- Configuration read/write via config API
- Maintenance actions (gravity update, DNS restart, flush operations)
- Teleporter backup and restore
- PADD terminal dashboard output
- Over-time history data for graphing
