# pihole-manage

A comprehensive [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill for managing [Pi-hole](https://pi-hole.net/) network ad blockers through the v6 REST API.

## What is this?

This is a **Claude Code skill** — a modular package that extends Claude's capabilities with specialized knowledge and tools. When installed, Claude can manage your Pi-hole instance through natural language commands.

### Examples

> "Check my Pi-hole stats"

> "Disable ad blocking for 5 minutes"

> "Add ads.example.com to my denylist"

> "Show me the top blocked domains"

> "Run a gravity update"

> "Search for google.com across all my lists"

> "Back up my Pi-hole configuration"

## Features

| Category | Capabilities |
|----------|-------------|
| **DNS Blocking** | Enable/disable blocking, timed disable |
| **Domain Management** | Allowlists, denylists (exact + regex), batch operations |
| **Adlists** | Add/remove/update blocklist subscriptions |
| **Statistics** | Summary, top domains, top clients, query types, upstreams |
| **Query Log** | Search and filter DNS queries by domain, client, status |
| **Groups & Clients** | Create groups, assign clients, manage filtering policies |
| **Custom DNS** | Local DNS records, CNAME records |
| **DHCP** | View and manage DHCP leases |
| **System Info** | CPU, memory, disk, sensors, version, logs |
| **Configuration** | Read/write any Pi-hole setting via the config API |
| **Maintenance** | Gravity updates, DNS restart, flush logs/ARP/network |
| **Teleporter** | Backup and restore Pi-hole configuration |
| **Network** | Devices, gateway, routes, interfaces |

## Requirements

- **Pi-hole v6+** with the REST API enabled (built into FTL)
- **curl** available on the system
- **jq** (recommended) or **Python 3** for JSON parsing in the helper script
- Network access to your Pi-hole instance

## Installation

### As a Claude Code Skill

Copy the skill directory into your Claude Code skills folder:

```bash
# Linux / macOS
cp -r pihole-manage ~/.claude/skills/pihole-manage

# Windows
xcopy /E /I pihole-manage %USERPROFILE%\.claude\skills\pihole-manage
```

Then restart Claude Code. The skill will appear in the available skills list automatically.

### Standalone Helper Script

The included shell script can also be used independently:

```bash
# Source it for interactive use
source scripts/pihole-api.sh
pihole_login http://pi.hole your-password
pihole_summary
pihole_top_domains 10
pihole_logout

# Or run commands directly
./scripts/pihole-api.sh login http://pi.hole your-password
./scripts/pihole-api.sh summary
./scripts/pihole-api.sh top-domains 10
```

Run `./scripts/pihole-api.sh help` for the full command list.

## Project Structure

```
pihole-manage/
├── SKILL.md              # Skill metadata and workflow instructions
├── README.md             # This file
├── LICENSE               # MIT License
├── CONTRIBUTING.md       # Contribution guidelines
├── SECURITY.md           # Security policy
├── CODE_OF_CONDUCT.md    # Code of conduct
├── CHANGELOG.md          # Version history
├── references/
│   └── api-endpoints.md  # Complete Pi-hole v6 API endpoint reference
└── scripts/
    └── pihole-api.sh     # Reusable shell helper (50+ commands)
```

## API Coverage

The skill covers the **entire Pi-hole v6 REST API** with 70+ endpoints across all categories. See [`references/api-endpoints.md`](references/api-endpoints.md) for the complete endpoint reference.

## Authentication

Pi-hole v6 uses session-based authentication. The skill handles the full flow:

1. `POST /api/auth` with your password to get a session ID (SID)
2. Include the SID in subsequent requests via header, query param, or cookie
3. `DELETE /api/auth` to end the session

Application passwords (generated from Pi-hole Settings) are supported as an alternative to your admin password.

## Related Resources

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Pi-hole API Docs](https://docs.pi-hole.net/api/)
- [Pi-hole GitHub](https://github.com/pi-hole)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)

## License

[MIT](LICENSE)
