#!/usr/bin/env bash

set -e

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
az acr login --name "$acrName" --subscription "$subscription"

RULES_CONFIG=$(yq e acr-repositories.yaml -o=json)

for key in $(echo $RULES_CONFIG | jq -r '.rules | keys | .[]'); do
        RULE_NAME=$(echo $RULES_CONFIG | jq -r '.rules | ."'$key'" | .ruleName')
        REPO_NAME=$(echo $RULES_CONFIG | jq -r '.rules | ."'$key'" | .repoName')
        REGISTRY=$(echo $RULES_CONFIG | jq -r '.rules | ."'$key'" | .registry')
        DESTINATION_NAME=$(echo $RULES_CONFIG | jq -r '.rules | ."'$key'" | .destinationRepo')

        echo "Creating ACR Cache Rule for $key, source: $REGISTRY/$REPO_NAME, destination: $DESTINATION_NAME..."
        az acr cache create -r "$acrName" -n "$RULE_NAME" -s "$REGISTRY/$REPO_NAME" -t "$DESTINATION_NAME" -c dockerhub
done
