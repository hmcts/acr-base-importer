#!/usr/bin/env bash

set -e

echo "Logging into ACR..."
az acr login --name hmctspublic --subscription DCD-CNP-Prod

RULES_CONFIG=$(yq e acr-repositories.yaml -o=json)

for key in $(echo $RULES_CONFIG | jq -r '.rules | keys | .[]'); do
    RULE_NAME=$(echo $RULES_CONFIG | jq -r '.rules | ."'$key'" | .ruleName')
    REPO_NAME=$(echo $RULES_CONFIG | jq -r '.rules | ."'$key'" | .repoName')
    DESTINATION_NAME=$(echo $RULES_CONFIG | jq -r '.rules | ."'$key'" | .destinationRepo')
    IMAGES=$(echo $RULES_CONFIG | jq -r '.rules | ."'$key'" | .images')

    echo "Creating ACR Cache for $key"
    az acr cache create -r hmctspublic -n $RULE_NAME -s docker.io/$REPO_NAME -t $DESTINATION_NAME


    # Repository in ACR (if new) will not be created until docker pull command has been run for first time
    echo "Docker Image Pull to populate repositories with external images"
    # Fetch images from returned array and remove speech marks
    echo $IMAGES | jq -c '.[]' |  tr -d '"' | while read image; do
        echo "Pulling $image into $DESTINATION_NAME repository for use with cache rule..."
        docker pull hmctspublic.azurecr.io/$DESTINATION_NAME:$image
    done
done
