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

_result=$(docker buildx imagetools inspect --raw $baseRegistry/$baseImage:$baseTag)

if echo $_result | grep -q manifests
then
  _digest=$(echo $_result | jq -r '.manifests[] | select (.platform.architecture == "amd64") | .digest')
else
  _digest=$(echo $_result | jq -r .config.digest)
fi

[ "$_digest" == "" ] && echo "Error: cannot get image digest for ${baseImage}:${baseTag}" && exit 1

# Get current digest from target azure registry
echo "Base registry current digest for ${baseImage}:${baseTag}: [${_digest}]"

# Get the manifest from ACR and extract the amd64 platform digest directly
_acr_manifest=$(az acr manifest show --registry $acrName --name $targetImage -o json 2>/dev/null || echo "")

# Extract the amd64 platform digest from the manifest
if [ -n "$_acr_manifest" ] && [ "$_acr_manifest" != "" ]; then
  _acr_digest=$(echo $_acr_manifest | jq -r '.manifests[] | select (.platform.architecture == "amd64") | .digest' 2>/dev/null || echo "")
else
  _acr_digest=""
fi

echo "Target registry current digest for ${baseImage}:${baseTag}: [${_acr_digest}]"

[[ "$_acr_digest" != "" && "$_acr_digest" == "$_digest" ]] && echo "Nothing to import for ${baseRegistry}/${baseImage}." && exit 0  # Nothing else to do

# Export variables for next stages (with isOutput=true to make them available to other tasks)
echo "##vso[task.setvariable variable=newTagFound;isOutput=true]true"
echo "##vso[task.setvariable variable=acrDigest;isOutput=true]$_acr_digest"
echo "##vso[task.setvariable variable=baseDigest;isOutput=true]${_digest:7:6}"
