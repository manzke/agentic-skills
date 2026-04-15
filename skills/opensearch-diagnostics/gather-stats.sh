#!/usr/bin/env bash
#
# OpenSearch / Elasticsearch Stats Gatherer
#
# Gathers comprehensive cluster diagnostics into a single markdown file
# suitable for analysis by Claude or other LLMs.
#
# Usage:
#   ./gather-stats.sh <index-name> [host] [port]
#
# Environment variables:
#   HOST       - Cluster host (default: localhost)
#   PORT       - Cluster port (default: 9200)
#   PROTOCOL   - http or https (default: http)
#   ES_USER    - Basic auth username (optional)
#   ES_PASS    - Basic auth password (optional)
#   CA_CERT    - Path to CA certificate for HTTPS (optional)
#
# Examples:
#   ./gather-stats.sh my_index
#   ./gather-stats.sh my_index opensearch.example.com 9201
#   PROTOCOL=https ES_USER=admin ES_PASS=secret ./gather-stats.sh my_index es.prod.com 9200
#
# Output: <index-name>_dump_<YYYYMMDD_HHMMSS>.md

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "ERROR: Missing required argument."
  echo "Usage: $0 <index-name> [host] [port]"
  echo "Example: bash $0 documents"
  exit 1
fi

# --- Configuration ---
INDEX="$1"
HOST="${2:-${HOST:-localhost}}"
PORT="${3:-${PORT:-9200}}"
PROTOCOL="${PROTOCOL:-http}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_FILE="${INDEX}_dump_${TIMESTAMP}.md"
BASE_URL="${PROTOCOL}://${HOST}:${PORT}"

# Build curl auth flags
CURL_OPTS=(-s)
if [ -n "${ES_USER:-}" ] && [ -n "${ES_PASS:-}" ]; then
  CURL_OPTS+=(-u "${ES_USER}:${ES_PASS}")
fi
if [ -n "${CA_CERT:-}" ]; then
  CURL_OPTS+=(--cacert "${CA_CERT}")
fi
if [ "${PROTOCOL}" = "https" ] && [ -z "${CA_CERT:-}" ]; then
  CURL_OPTS+=(-k)  # Allow self-signed certs if no CA provided
fi

# --- Helper Function ---
gather_stat() {
  local title="$1"
  local url="$2"
  local is_json="${3:-true}"

  echo "  Gathering: $title"
  echo "## $title" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

  if [ "$is_json" = true ]; then
    echo '```json' >> "$OUTPUT_FILE"
  else
    echo '```text' >> "$OUTPUT_FILE"
  fi

  (curl "${CURL_OPTS[@]}" "$url" 2>/dev/null || echo "ERROR: Failed to fetch $url") >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo '```' >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "---" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
}

# --- Main ---
echo "Gathering stats for index '$INDEX' from ${BASE_URL}..."
echo "Output: $OUTPUT_FILE"
echo ""

# Header
cat > "$OUTPUT_FILE" <<EOF
# OpenSearch Stats Dump for Index: ${INDEX}

- **Generated:** $(date)
- **Cluster:** ${BASE_URL}
- **Index:** ${INDEX}

---

EOF

# Cluster-level
gather_stat "Cluster Health" "${BASE_URL}/_cluster/health?pretty"
gather_stat "Cluster Stats" "${BASE_URL}/_cluster/stats?pretty"
gather_stat "Cluster Settings (with defaults)" "${BASE_URL}/_cluster/settings?include_defaults=true&pretty"
gather_stat "Pending Cluster Tasks" "${BASE_URL}/_cluster/pending_tasks?pretty"

# Node-level
gather_stat "Nodes Stats" "${BASE_URL}/_nodes/stats?pretty"
gather_stat "Nodes Hot Threads" "${BASE_URL}/_nodes/hot_threads?threads=10" false

# Index-level
gather_stat "Index Stats (${INDEX})" "${BASE_URL}/${INDEX}/_stats?pretty"
gather_stat "Index Settings (${INDEX})" "${BASE_URL}/${INDEX}/_settings?pretty&include_defaults=true"
gather_stat "Index Segments (${INDEX})" "${BASE_URL}/${INDEX}/_segments?pretty"
gather_stat "Index Mapping (${INDEX})" "${BASE_URL}/${INDEX}/_mapping?pretty"

# Plugins
gather_stat "k-NN Plugin Stats" "${BASE_URL}/_plugins/_knn/stats?pretty"

# Aliases
gather_stat "Aliases" "${BASE_URL}/_aliases?pretty"

# CAT APIs
gather_stat "CAT: Nodes" "${BASE_URL}/_cat/nodes?v&s=cpu:desc" false
gather_stat "CAT: Indices" "${BASE_URL}/_cat/indices?v&s=index" false
gather_stat "CAT: Shards" "${BASE_URL}/_cat/shards?v&s=index" false
gather_stat "CAT: Segments (${INDEX})" "${BASE_URL}/_cat/segments/${INDEX}?v" false
gather_stat "CAT: Allocation" "${BASE_URL}/_cat/allocation?v&bytes=gb" false
gather_stat "CAT: Thread Pool (Search)" "${BASE_URL}/_cat/thread_pool/search?v&h=node_name,name,active,queue,rejected" false
gather_stat "CAT: Thread Pool (Write)" "${BASE_URL}/_cat/thread_pool/write?v&h=node_name,name,active,queue,rejected" false
gather_stat "CAT: Tasks" "${BASE_URL}/_cat/tasks?v&detailed" false
gather_stat "CAT: Fielddata" "${BASE_URL}/_cat/fielddata?v" false
gather_stat "CAT: Recovery (active)" "${BASE_URL}/_cat/recovery?v&active_only=true" false
gather_stat "CAT: Plugins" "${BASE_URL}/_cat/plugins?v" false

echo ""
echo "Done. All stats written to: $OUTPUT_FILE"
