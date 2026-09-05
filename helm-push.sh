#!/usr/bin/env bash
#
# Package and push a Helm chart to a GitLab OCI Container Registry.
#
# Usage:
#   ./helm-push.sh                       # uses defaults
#   ./helm-push.sh -r registry.gitlab.com/mygroup/myproject -u myuser -p mytoken
#
# Prerequisites:
#   - Helm v3.8+ (OCI support GA)
#   - A GitLab personal-access or deploy token with `read_registry` + `write_registry` scopes
#
# Environment variables (alternative to flags):
#   HELM_REGISTRY   – OCI registry URL  (e.g. registry.gitlab.com/mygroup/myproject)
#   HELM_USER       – Registry username
#   HELM_PASSWORD   – Registry password / token
#
set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────────────────────
CHART_DIR="$(cd "$(dirname "$0")/helmchart" && pwd)"
REGISTRY="${HELM_REGISTRY:-}"
USER="${HELM_USER:-}"
PASSWORD="${HELM_PASSWORD:-}"

# ─── Parse CLI flags ────────────────────────────────────────────────────────
while getopts "r:u:p:c:h" opt; do
  case $opt in
    r) REGISTRY="$OPTARG" ;;
    u) USER="$OPTARG" ;;
    p) PASSWORD="$OPTARG" ;;
    c) CHART_DIR="$OPTARG" ;;
    h)
      echo "Usage: $0 [-r REGISTRY] [-u USER] [-p PASSWORD] [-c CHART_DIR]"
      echo ""
      echo "  -r  OCI registry URL (e.g. registry.gitlab.com/mygroup/myproject)"
      echo "  -u  Registry username"
      echo "  -p  Registry password / token"
      echo "  -c  Path to the Helm chart directory (default: ./helmchart)"
      exit 0
      ;;
    *) echo "Unknown option: -$opt" >&2; exit 1 ;;
  esac
done

# ─── Validate ────────────────────────────────────────────────────────────────
if [[ -z "$REGISTRY" ]]; then
  echo "❌  REGISTRY is required. Pass -r or set HELM_REGISTRY."
  exit 1
fi

# OCI registries require all lowercase characters
REGISTRY="$(echo "$REGISTRY" | tr '[:upper:]' '[:lower:]')"


if [[ ! -f "$CHART_DIR/Chart.yaml" ]]; then
  echo "❌  Chart.yaml not found in $CHART_DIR"
  exit 1
fi

CHART_NAME=$(grep '^name:' "$CHART_DIR/Chart.yaml" | awk '{print $2}')
CHART_VERSION=$(grep '^version:' "$CHART_DIR/Chart.yaml" | awk '{print $2}')

echo "📦  Chart:    $CHART_NAME"
echo "🏷️   Version:  $CHART_VERSION"
echo "🌐  Registry: oci://$REGISTRY"
echo ""

# ─── Login ───────────────────────────────────────────────────────────────────
REGISTRY_HOST=$(echo "$REGISTRY" | cut -d'/' -f1)

if [[ -n "$USER" && -n "$PASSWORD" ]]; then
  echo "🔑  Logging in to $REGISTRY_HOST …"
  echo "$PASSWORD" | helm registry login "$REGISTRY_HOST" --username "$USER" --password-stdin
elif [[ -n "$PASSWORD" ]]; then
  echo "🔑  Logging in to $REGISTRY_HOST (token-only) …"
  echo "$PASSWORD" | helm registry login "$REGISTRY_HOST" --username "__token__" --password-stdin
else
  echo "ℹ️   No credentials provided – assuming you are already logged in."
fi

echo ""

# ─── Package ─────────────────────────────────────────────────────────────────
echo "📦  Packaging chart …"
helm package "$CHART_DIR" --destination /tmp/helm-packages

PACKAGE_FILE="/tmp/helm-packages/${CHART_NAME}-${CHART_VERSION}.tgz"

if [[ ! -f "$PACKAGE_FILE" ]]; then
  echo "❌  Package file not found: $PACKAGE_FILE"
  exit 1
fi

echo "✅  Created: $PACKAGE_FILE"
echo ""

# ─── Push ────────────────────────────────────────────────────────────────────
echo "🚀  Pushing to oci://$REGISTRY …"
helm push "$PACKAGE_FILE" "oci://$REGISTRY"

echo ""
echo "✅  Successfully pushed $CHART_NAME:$CHART_VERSION to oci://$REGISTRY"
echo ""
echo "To pull it later:"
echo "  helm pull oci://$REGISTRY/$CHART_NAME --version $CHART_VERSION"
