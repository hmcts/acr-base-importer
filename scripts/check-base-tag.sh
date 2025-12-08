#!/usr/bin/env bash

set -euo pipefail

baseImage=
baseRegistry=
baseTag=
targetImage=
acrName=

usage(){
>&2 cat << EOF
------------------------------------------------
Script to check if AKS cluster is active state
------------------------------------------------
Usage: $0
    [ -bi |--baseImage ]
    [ -br |--baseRegistry ]
    [ -bt |--baseTag ]
    [ -ti |--targetImage ]
    [ -an |--acrName ]
    [ -h |--help ]
EOF
exit 1
}

args=$(getopt -a -o bi:br:bt:ti:an: --long baseImage:,baseRegistry:,baseTag:,targetImage:,acrName:,help -- "$@")
if [[ $? -gt 0 ]]; then
    usage
fi

# Debug commands, uncomment if you are having issues
# >&2 echo [$@] passed to script
# >&2 echo getopt creates [${args}]

eval set -- ${args}
while :
do
    case $1 in
        -h  | --help )         usage                  ; shift   ;;
        -bi | --baseImage )    baseImage=$2           ; shift 2 ;;
        -br | --baseRegistry ) baseRegistry=$2        ; shift 2 ;;
        -bt | --baseTag )      baseTag=$2             ; shift 2 ;;
        -ti | --targetImage )  targetImage=$2         ; shift 2 ;;
        -an | --acrName )      acrName=$2             ; shift 2 ;;
        --) shift; break ;;
        *) >&2 echo Unsupported option: $1
        usage ;;
    esac
done

# Check if all arguments are provided
if [ -z "$baseImage" ] || [ -z "$baseRegistry" ] || [ -z "$baseTag" ] || [ -z "$targetImage" ] || [ -z "$acrName" ]; then
    echo "------------------------"
    echo 'Some values are missing, please supply all the required arguments' >&2
    echo "------------------------"
    exit 1
fi

_result=$(docker buildx imagetools inspect --raw $baseRegistry/$baseImage:$baseTag 2>&1) || {
    echo "⚠ Warning: cannot inspect image ${baseRegistry}/${baseImage}:${baseTag}" >&2
    echo "##vso[task.logissue type=warning]Cannot inspect image ${baseRegistry}/${baseImage}:${baseTag} - skipping import for this image"
    echo "##vso[task.setvariable variable=newTagFound;isOutput=true]false"
    echo "##vso[task.setvariable variable=inspectError;isOutput=true]true"
    exit 0  # Continue to next image in loop
}

# Extract wrapper digest from source registry (covers all architectures)
# Pipe directly to avoid command substitution normalizing whitespace
_digest=$(docker buildx imagetools inspect --raw $baseRegistry/$baseImage:$baseTag 2>/dev/null | sha256sum 2>/dev/null | cut -d' ' -f1)

[ "$_digest" == "" ] && echo "Error: cannot get image digest for ${baseImage}:${baseTag}" && exit 1

# Get current digest from target azure registry
echo "Base registry wrapper digest for ${baseImage}:${baseTag}: [${_digest}]"

# Get the wrapper digest from ACR using manifest list-metadata
# Only check for the specific baseTag; if it doesn't exist, treat as new image (empty digest)
_acr_digest_raw=$(az acr manifest list-metadata --registry $acrName --name $targetImage --query "[?not_null(tags[])]|[?contains(tags, '${baseTag}')].digest|[0]" -o tsv 2>/dev/null || echo "")
# Strip sha256: prefix for consistent comparison with docker buildx output (handles empty string gracefully)
_acr_digest=${_acr_digest_raw#sha256:}

echo "Target registry wrapper digest for ${baseImage}:${baseTag}: [${_acr_digest}]"

[[ "$_acr_digest" != "" && "$_acr_digest" == "$_digest" ]] && echo "Nothing to import for ${baseRegistry}/${baseImage}." && exit 0  # Nothing else to do

# Export variables for next stages (with isOutput=true to make them available to other tasks)
echo "##vso[task.setvariable variable=newTagFound;isOutput=true]true"
echo "##vso[task.setvariable variable=acrDigest;isOutput=true]$_acr_digest"
echo "##vso[task.setvariable variable=baseDigest;isOutput=true]${_digest:7:6}"
