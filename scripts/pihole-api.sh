#!/usr/bin/env bash
# pihole-api.sh - Pi-hole v6 API helper script
# Usage: source pihole-api.sh && pihole_login http://pi.hole mypassword
#   or:  ./pihole-api.sh <command> [args...]

set -euo pipefail

# --- Configuration ---
PIHOLE_URL="${PIHOLE_URL:-}"
PIHOLE_SID="${PIHOLE_SID:-}"
PIHOLE_CSRF="${PIHOLE_CSRF:-}"
CURL_OPTS="${PIHOLE_CURL_OPTS:--s}"

# --- JSON parser (jq with Python fallback) ---

_json_extract() {
  # Extract a JSON field value. Usage: echo '{"a":"b"}' | _json_extract '.field'
  local jq_path="$1"
  if command -v jq &>/dev/null; then
    jq -r "${jq_path} // empty"
  else
    # Convert jq-style path to Python dict access
    python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    keys = '${jq_path}'.lstrip('.').split('.')
    val = data
    for k in keys:
        val = val.get(k)
        if val is None:
            break
    if val is not None:
        print(val)
except: pass
"
  fi
}

_json_pp() {
  # Pretty-print JSON
  if command -v jq &>/dev/null; then
    jq .
  else
    python3 -m json.tool 2>/dev/null || cat
  fi
}

# --- Helpers ---

_api_get() {
  local path="$1"; shift
  curl ${CURL_OPTS} -X GET "${PIHOLE_URL}/api${path}" \
    -H "sid: ${PIHOLE_SID}" "$@"
}

_api_post() {
  local path="$1"; shift
  curl ${CURL_OPTS} -X POST "${PIHOLE_URL}/api${path}" \
    -H "sid: ${PIHOLE_SID}" \
    -H "Content-Type: application/json" "$@"
}

_api_put() {
  local path="$1"; shift
  curl ${CURL_OPTS} -X PUT "${PIHOLE_URL}/api${path}" \
    -H "sid: ${PIHOLE_SID}" \
    -H "Content-Type: application/json" "$@"
}

_api_delete() {
  local path="$1"; shift
  curl ${CURL_OPTS} -X DELETE "${PIHOLE_URL}/api${path}" \
    -H "sid: ${PIHOLE_SID}" "$@"
}

# --- Authentication ---

pihole_login() {
  local url="${1:?Usage: pihole_login <url> <password>}"
  local password="${2:?Usage: pihole_login <url> <password>}"
  PIHOLE_URL="${url}"
  local response
  response=$(curl ${CURL_OPTS} -X POST "${PIHOLE_URL}/api/auth" \
    -H "Content-Type: application/json" \
    -d "{\"password\":\"${password}\"}")
  PIHOLE_SID=$(echo "${response}" | _json_extract '.session.sid')
  PIHOLE_CSRF=$(echo "${response}" | _json_extract '.session.csrf')
  if [ -z "${PIHOLE_SID}" ]; then
    echo "ERROR: Authentication failed" >&2
    echo "${response}" | _json_pp >&2
    return 1
  fi
  local validity
  validity=$(echo "${response}" | _json_extract '.session.validity')
  echo "Authenticated. Session valid for ${validity}s"
  export PIHOLE_URL PIHOLE_SID PIHOLE_CSRF
}

pihole_logout() {
  _api_delete "/auth"
  PIHOLE_SID=""
  PIHOLE_CSRF=""
  echo "Session ended."
}

# --- DNS Blocking ---

pihole_status() {
  _api_get "/dns/blocking"
}

pihole_enable() {
  _api_post "/dns/blocking" -d '{"blocking":true}'
}

pihole_disable() {
  local seconds="${1:-}"
  if [ -n "${seconds}" ]; then
    _api_post "/dns/blocking" -d "{\"blocking\":false,\"timer\":${seconds}}"
  else
    _api_post "/dns/blocking" -d '{"blocking":false}'
  fi
}

# --- Statistics ---

pihole_summary() {
  _api_get "/stats/summary"
}

pihole_top_domains() {
  local count="${1:-10}"
  _api_get "/stats/top_domains?count=${count}"
}

pihole_top_blocked() {
  local count="${1:-10}"
  _api_get "/stats/top_domains?count=${count}&blocked=true"
}

pihole_top_clients() {
  local count="${1:-10}"
  _api_get "/stats/top_clients?count=${count}"
}

pihole_query_types() {
  _api_get "/stats/query_types"
}

pihole_upstreams() {
  _api_get "/stats/upstreams"
}

pihole_recent_blocked() {
  _api_get "/stats/recent_blocked"
}

# --- Query Log ---

pihole_queries() {
  local domain="${1:-}"
  if [ -n "${domain}" ]; then
    _api_get "/queries?domain=${domain}"
  else
    _api_get "/queries"
  fi
}

# --- Domain Management ---

pihole_deny() {
  local domain="${1:?Usage: pihole_deny <domain> [comment]}"
  local comment="${2:-Added via API}"
  _api_post "/domains/deny/exact" \
    -d "{\"domain\":\"${domain}\",\"comment\":\"${comment}\"}"
}

pihole_allow() {
  local domain="${1:?Usage: pihole_allow <domain> [comment]}"
  local comment="${2:-Added via API}"
  _api_post "/domains/allow/exact" \
    -d "{\"domain\":\"${domain}\",\"comment\":\"${comment}\"}"
}

pihole_undeny() {
  local domain="${1:?Usage: pihole_undeny <domain>}"
  _api_delete "/domains/deny/exact/${domain}"
}

pihole_unallow() {
  local domain="${1:?Usage: pihole_unallow <domain>}"
  _api_delete "/domains/allow/exact/${domain}"
}

pihole_list_denied() {
  _api_get "/domains/deny/exact"
}

pihole_list_allowed() {
  _api_get "/domains/allow/exact"
}

# --- Adlists ---

pihole_adlists() {
  _api_get "/lists"
}

pihole_add_adlist() {
  local url="${1:?Usage: pihole_add_adlist <url> [comment]}"
  local comment="${2:-Added via API}"
  _api_post "/lists" \
    -d "{\"address\":\"${url}\",\"type\":\"block\",\"enabled\":true,\"comment\":\"${comment}\"}"
}

pihole_remove_adlist() {
  local url="${1:?Usage: pihole_remove_adlist <url>}"
  local encoded
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${url}', safe=''))" 2>/dev/null || echo "${url}")
  _api_delete "/lists/${encoded}"
}

# --- Groups ---

pihole_groups() {
  _api_get "/groups"
}

pihole_add_group() {
  local name="${1:?Usage: pihole_add_group <name> [comment]}"
  local comment="${2:-}"
  _api_post "/groups" \
    -d "{\"name\":\"${name}\",\"comment\":\"${comment}\"}"
}

pihole_remove_group() {
  local name="${1:?Usage: pihole_remove_group <name>}"
  local encoded
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${name}', safe=''))" 2>/dev/null || echo "${name}")
  _api_delete "/groups/${encoded}"
}

# --- Clients ---

pihole_clients() {
  _api_get "/clients"
}

pihole_client_suggestions() {
  _api_get "/clients/_suggestions"
}

pihole_add_client() {
  local client="${1:?Usage: pihole_add_client <ip|mac|hostname> [comment]}"
  local comment="${2:-Added via API}"
  _api_post "/clients" \
    -d "{\"client\":\"${client}\",\"comment\":\"${comment}\"}"
}

pihole_remove_client() {
  local client="${1:?Usage: pihole_remove_client <ip|mac|hostname>}"
  _api_delete "/clients/${client}"
}

# --- Search ---

pihole_search() {
  local domain="${1:?Usage: pihole_search <domain>}"
  _api_get "/search/${domain}"
}

# --- System Info ---

pihole_system() {
  _api_get "/info/system"
}

pihole_version() {
  _api_get "/info/version"
}

pihole_host() {
  _api_get "/info/host"
}

pihole_sensors() {
  _api_get "/info/sensors"
}

pihole_db_info() {
  _api_get "/info/database"
}

pihole_messages() {
  _api_get "/info/messages"
}

# --- Logs ---

pihole_logs_dns() {
  _api_get "/logs/dnsmasq"
}

pihole_logs_ftl() {
  _api_get "/logs/ftl"
}

pihole_logs_web() {
  _api_get "/logs/webserver"
}

# --- Network ---

pihole_devices() {
  _api_get "/network/devices"
}

pihole_gateway() {
  _api_get "/network/gateway"
}

pihole_routes() {
  _api_get "/network/routes"
}

pihole_interfaces() {
  _api_get "/network/interfaces"
}

# --- DHCP ---

pihole_leases() {
  _api_get "/dhcp/leases"
}

pihole_delete_lease() {
  local ip="${1:?Usage: pihole_delete_lease <ip>}"
  _api_delete "/dhcp/leases/${ip}"
}

# --- Custom DNS ---

pihole_dns_records() {
  _api_get "/config/dns.hosts"
}

pihole_add_dns() {
  local ip="${1:?Usage: pihole_add_dns <ip> <hostname>}"
  local hostname="${2:?Usage: pihole_add_dns <ip> <hostname>}"
  _api_put "/config/dns/hosts/${ip}%20${hostname}"
}

pihole_remove_dns() {
  local ip="${1:?Usage: pihole_remove_dns <ip> <hostname>}"
  local hostname="${2:?Usage: pihole_remove_dns <ip> <hostname>}"
  _api_delete "/config/dns/hosts/${ip}%20${hostname}"
}

# --- Actions ---

pihole_gravity() {
  _api_post "/action/gravity"
}

pihole_restart_dns() {
  _api_post "/action/restartdns"
}

pihole_flush_logs() {
  _api_post "/action/flush/logs"
}

pihole_flush_arp() {
  _api_post "/action/flush/arp"
}

pihole_flush_network() {
  _api_post "/action/flush/network"
}

# --- Teleporter ---

pihole_backup() {
  local output="${1:-pihole-backup.tar.gz}"
  curl ${CURL_OPTS} "${PIHOLE_URL}/api/teleporter" \
    -H "sid: ${PIHOLE_SID}" -o "${output}"
  echo "Backup saved to ${output}"
}

pihole_restore() {
  local file="${1:?Usage: pihole_restore <backup.tar.gz>}"
  curl ${CURL_OPTS} -X POST "${PIHOLE_URL}/api/teleporter" \
    -H "sid: ${PIHOLE_SID}" \
    -F "file=@${file}"
}

# --- Configuration ---

pihole_config() {
  local path="${1:-}"
  if [ -n "${path}" ]; then
    _api_get "/config/${path}"
  else
    _api_get "/config"
  fi
}

pihole_config_set() {
  local path="${1:?Usage: pihole_config_set <path/value>}"
  _api_put "/config/${path}"
}

pihole_config_unset() {
  local path="${1:?Usage: pihole_config_unset <path/value>}"
  _api_delete "/config/${path}"
}

# --- PADD ---

pihole_padd() {
  _api_get "/padd"
}

# --- History ---

pihole_history() {
  _api_get "/history"
}

pihole_history_clients() {
  _api_get "/history/clients"
}

# --- CLI Mode ---

_usage() {
  cat <<'USAGE'
Pi-hole API Helper Script

Usage:
  Source mode:  source pihole-api.sh && pihole_login <url> <password>
  CLI mode:     ./pihole-api.sh <command> [args...]

Environment variables:
  PIHOLE_URL         Pi-hole base URL (e.g., http://pi.hole)
  PIHOLE_SID         Session ID (from login)
  PIHOLE_CURL_OPTS   Extra curl options (default: -s; use "-sk" for self-signed HTTPS)

Commands:
  login <url> <password>      Authenticate and print session info
  logout                      End current session
  status                      Show blocking status
  enable                      Enable blocking
  disable [seconds]           Disable blocking (optionally for N seconds)
  summary                     Show statistics summary
  top-domains [count]         Top queried domains
  top-blocked [count]         Top blocked domains
  top-clients [count]         Top querying clients
  query-types                 Query type distribution
  upstreams                   Upstream server stats
  recent-blocked              Most recently blocked domain
  queries [domain]            Query log (optionally filtered)
  deny <domain> [comment]     Add to denylist
  allow <domain> [comment]    Add to allowlist
  undeny <domain>             Remove from denylist
  unallow <domain>            Remove from allowlist
  list-denied                 List denylist entries
  list-allowed                List allowlist entries
  adlists                     List blocklist subscriptions
  add-adlist <url> [comment]  Add a blocklist
  remove-adlist <url>         Remove a blocklist
  groups                      List groups
  add-group <name> [comment]  Create a group
  remove-group <name>         Delete a group
  clients                     List configured clients
  client-suggestions          List discovered clients
  add-client <id> [comment]   Add a client
  remove-client <id>          Remove a client
  search <domain>             Search domain across all lists
  system                      System info
  version                     Version info
  host                        Host info
  sensors                     Hardware sensors
  db-info                     Database info
  messages                    Pi-hole messages/warnings
  dns-records                 List custom DNS records
  add-dns <ip> <hostname>     Add custom DNS record
  remove-dns <ip> <hostname>  Remove custom DNS record
  devices                     Network devices
  gateway                     Gateway info
  routes                      Routing table
  interfaces                  Network interfaces
  leases                      DHCP leases
  delete-lease <ip>           Delete a DHCP lease
  gravity                     Update gravity (re-download lists)
  restart-dns                 Restart DNS resolver
  flush-logs                  Flush query logs
  flush-arp                   Flush ARP cache
  flush-network               Flush network table
  backup [filename]           Export config backup
  restore <filename>          Import config backup
  config [path]               View configuration
  config-set <path/value>     Set a config value
  config-unset <path/value>   Remove a config value
  padd                        PADD terminal dashboard output
  history                     Over-time query history
  history-clients             Per-client query history
  logs-dns                    DNS resolver logs
  logs-ftl                    FTL engine logs
  logs-web                    Web server logs
  help                        Show this help message
USAGE
}

# If executed directly (not sourced), handle CLI commands
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  command="${1:-help}"
  shift 2>/dev/null || true

  case "${command}" in
    login)            pihole_login "$@" ;;
    logout)           pihole_logout ;;
    status)           pihole_status ;;
    enable)           pihole_enable ;;
    disable)          pihole_disable "$@" ;;
    summary)          pihole_summary ;;
    top-domains)      pihole_top_domains "$@" ;;
    top-blocked)      pihole_top_blocked "$@" ;;
    top-clients)      pihole_top_clients "$@" ;;
    query-types)      pihole_query_types ;;
    upstreams)        pihole_upstreams ;;
    recent-blocked)   pihole_recent_blocked ;;
    queries)          pihole_queries "$@" ;;
    deny)             pihole_deny "$@" ;;
    allow)            pihole_allow "$@" ;;
    undeny)           pihole_undeny "$@" ;;
    unallow)          pihole_unallow "$@" ;;
    list-denied)      pihole_list_denied ;;
    list-allowed)     pihole_list_allowed ;;
    adlists)          pihole_adlists ;;
    add-adlist)       pihole_add_adlist "$@" ;;
    remove-adlist)    pihole_remove_adlist "$@" ;;
    groups)           pihole_groups ;;
    add-group)        pihole_add_group "$@" ;;
    remove-group)     pihole_remove_group "$@" ;;
    clients)          pihole_clients ;;
    client-suggestions) pihole_client_suggestions ;;
    add-client)       pihole_add_client "$@" ;;
    remove-client)    pihole_remove_client "$@" ;;
    search)           pihole_search "$@" ;;
    system)           pihole_system ;;
    version)          pihole_version ;;
    host)             pihole_host ;;
    sensors)          pihole_sensors ;;
    db-info)          pihole_db_info ;;
    messages)         pihole_messages ;;
    dns-records)      pihole_dns_records ;;
    add-dns)          pihole_add_dns "$@" ;;
    remove-dns)       pihole_remove_dns "$@" ;;
    devices)          pihole_devices ;;
    gateway)          pihole_gateway ;;
    routes)           pihole_routes ;;
    interfaces)       pihole_interfaces ;;
    leases)           pihole_leases ;;
    delete-lease)     pihole_delete_lease "$@" ;;
    gravity)          pihole_gravity ;;
    restart-dns)      pihole_restart_dns ;;
    flush-logs)       pihole_flush_logs ;;
    flush-arp)        pihole_flush_arp ;;
    flush-network)    pihole_flush_network ;;
    backup)           pihole_backup "$@" ;;
    restore)          pihole_restore "$@" ;;
    config)           pihole_config "$@" ;;
    config-set)       pihole_config_set "$@" ;;
    config-unset)     pihole_config_unset "$@" ;;
    padd)             pihole_padd ;;
    history)          pihole_history ;;
    history-clients)  pihole_history_clients ;;
    logs-dns)         pihole_logs_dns ;;
    logs-ftl)         pihole_logs_ftl ;;
    logs-web)         pihole_logs_web ;;
    help|--help|-h)   _usage ;;
    *)                echo "Unknown command: ${command}" >&2; _usage >&2; exit 1 ;;
  esac
fi
