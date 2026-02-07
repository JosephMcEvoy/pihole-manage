# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | Yes       |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do not** open a public issue
2. Email the maintainer or use [GitHub's private vulnerability reporting](https://github.com/JosephMcEvoy/pihole-manage/security/advisories/new)
3. Include a description of the vulnerability and steps to reproduce

You can expect an initial response within 72 hours.

## Security Considerations

### Credentials

- **Never** commit Pi-hole passwords or session IDs to version control
- Use environment variables (`PIHOLE_URL`, `PIHOLE_SID`) or application passwords
- Application passwords can be generated in the Pi-hole web UI under Settings and are recommended for script/automation use
- Session IDs are temporary and bound to your client IP

### Network

- Use HTTPS when accessing Pi-hole over untrusted networks
- For self-signed certificates, use `-k` in curl opts (`PIHOLE_CURL_OPTS="-sk"`)
- The Pi-hole API binds to local interfaces by default — exposing it to the internet is not recommended

### Script Usage

- The helper script (`pihole-api.sh`) passes credentials via command-line arguments, which may be visible in process listings. For sensitive environments, source the script and set `PIHOLE_URL` and password via environment variables
- Review the script before running it in production environments

### Skill Usage

- The Claude Code skill issues curl commands that include the session ID in headers. These commands are visible in the Claude Code session but are not persisted beyond the session
- Do not share Claude Code session logs that contain Pi-hole credentials
