#!/usr/bin/env bash

set -euo pipefail

acrName=""
subscription=""

usage() {
    echo "Usage: $0 --acrName <acrName> --subscription <subscription>"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --acrName)
            acrName="$2"
            shift 2
            ;;
        --subscription)
            subscription="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            ;;
    esac
done

if [[ -z "$acrName" || -z "$subscription" ]]; then
    echo "acrName and subscription are required."
    usage
fi

echo "Logging into ACR..."
if ! az acr login --name "$acrName" --subscription "$subscription" 2>/dev/null; then
    echo "Error: Failed to login to ACR '$acrName' with subscription '$subscription'" >&2
    exit 1
fi

RULES_CONFIG=$(yq e acr-repositories.yaml -o=json)

# Counters for summary
created_count=0
skipped_count=0
failed_count=0

for key in $(echo "$RULES_CONFIG" | jq -r '.rules | keys | .[]'); do
    RULE_NAME=$(echo "$RULES_CONFIG" | jq -r '.rules | ."'"$key"'" | .ruleName')
    REPO_NAME=$(echo "$RULES_CONFIG" | jq -r '.rules | ."'"$key"'" | .repoName')
    REGISTRY=$(echo "$RULES_CONFIG" | jq -r '.rules | ."'"$key"'" | .registry')
    DESTINATION_NAME=$(echo "$RULES_CONFIG" | jq -r '.rules | ."'"$key"'" | .destinationRepo')

    echo "Processing ACR Cache Rule for $key, source: $REGISTRY/$REPO_NAME, destination: $DESTINATION_NAME..."
    
    # Determine if credentials are needed based on registry
    case "$REGISTRY" in
        "docker.io")
            CRED_ARGS="-c dockerhub"
            ;;
        "mcr.microsoft.com")
            CRED_ARGS="-c dockerhub"
            ;;
        "registry.k8s.io"|"gcr.io")
            # Public registries don't need credentials
            CRED_ARGS=""
            ;;
        *)
            # Default: no credentials for unknown registries
            CRED_ARGS=""
            ;;
    esac


    # Check if cache rule already exists
    if az acr cache show \
        --name "$RULE_NAME" \
        --registry "$acrName" \
        --query "name" -o tsv 2>/dev/null | grep -q "$RULE_NAME"; then
        echo "   ✓ Cache rule '$RULE_NAME' already exists, skipping creation"
        ((skipped_count++)) || true
        continue
    fi
    
    # Create the cache rule
    OUTPUT=$(az acr cache create \
        -r "$acrName" \
        -n "$RULE_NAME" \
        -s "$REGISTRY/$REPO_NAME" \
        -t "$DESTINATION_NAME" \
        $CRED_ARGS 2>&1)
    EXIT_CODE=$?
    set -e
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "   ✓ Cache rule '$RULE_NAME' created successfully"
        ((created_count++)) || true
    elif echo "$OUTPUT" | grep -q "ResourcePropertiesImmutable"; then
        echo "   ✓ Cache rule '$RULE_NAME' already exists with same properties, skipping"
        ((skipped_count++)) || true
    else
        echo "   ✗ ERROR: Failed to create cache rule '$RULE_NAME'"
        echo "   Error details: $OUTPUT" >&2
        ((failed_count++)) || true
        # Continue processing other rules instead of failing immediately
    fi
done

# Print summary
echo ""
echo "=========================================="
echo "Summary:"
echo "  Created: $created_count"
echo "  Skipped: $skipped_count"
echo "  Failed:  $failed_count"
echo "=========================================="

# Exit with error if any rules failed
if [ $failed_count -gt 0 ]; then
    exit 1
fi
