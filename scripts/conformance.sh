#!/bin/bash
set -e

# Mirror the real ard-spec repo layout under /tmp so the tool's own
# relative schema lookup (dirname(__file__)/../../spec/schemas/...) resolves.
ARD_SPEC_DIR="/tmp/ard-spec-conformance"
CONFORMANCE_TOOL="$ARD_SPEC_DIR/conformance/bin/conformance-test"
SCHEMA_PATH="$ARD_SPEC_DIR/spec/schemas/ai-catalog.schema.json"
RAW_BASE="https://raw.githubusercontent.com/ards-project/ard-spec/main"
REGISTRY_URL="${1:-https://ard.muredata.com}"
MANIFEST_PATH="https://muredata.com/.well-known/ai-catalog.json"


if [ ! -f "$CONFORMANCE_TOOL" ]; then
  echo "Downloading conformance tool..."
  mkdir -p "$(dirname "$CONFORMANCE_TOOL")"
  curl -sSf "$RAW_BASE/conformance/bin/conformance-test" -o "$CONFORMANCE_TOOL"
  chmod +x "$CONFORMANCE_TOOL"
fi

if [ ! -f "$SCHEMA_PATH" ]; then
  echo "Downloading JSON Schema..."
  mkdir -p "$(dirname "$SCHEMA_PATH")"
  curl -sSf "$RAW_BASE/spec/schemas/ai-catalog.schema.json" -o "$SCHEMA_PATH"
fi

python3 -c "import jsonschema" 2>/dev/null || \
  echo "Note: Python 'jsonschema' package not installed — JSON Schema validation will be skipped. Run 'pip install jsonschema' to enable it."

echo "=== Manifest (muredata.com/.well-known/ai-catalog.json) ==="
python3 "$CONFORMANCE_TOOL" manifest "$MANIFEST_PATH"

echo ""
echo "=== Catalog (ard-api/data/catalog.json) ==="
python3 "$CONFORMANCE_TOOL" manifest "$REGISTRY_URL/.well-known/ai-catalog.json"

echo ""
echo "=== Registry: $REGISTRY_URL ==="
python3 "$CONFORMANCE_TOOL" registry "$REGISTRY_URL/v1"