#!/usr/bin/env bash

set -euo pipefail
set -x

acrName=
sourceImage=
sourceRegistry=
targetImage=
tag=

usage(){
>&2 cat << EOF
------------------------------------------------
Script to check if AKS cluster is active state
------------------------------------------------
Usage: $0
    [ -an |--acrName ]
    [ -si |--sourceImage ]
    [ -sr |--sourceRegistry ]
    [ -ti |--targetImage ]
    [ -t |--tag ]
    [ -h |--help ]
EOF
exit 1
}

args=$(getopt -a -o si:sr:t:ti:an: --long sourceImage:,sourceRegistry:,tag:,targetImage:,acrName:,help -- "$@")
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
        -h  | --help )              usage                  ; shift   ;;
        -an | --acrName )           acrName=$2             ; shift 2 ;;
        -si | --sourceImage )       sourceImage=$2         ; shift 2 ;;
        -sr | --sourceRegistry )    sourceRegistry=$2      ; shift 2 ;;
        -ti | --targetImage )       targetImage=$2         ; shift 2 ;;
    -t | --tag )                    tag=$2                 ; shift 2 ;;
        --) shift; break ;;
        *) >&2 echo Unsupported option: $1
        usage ;;
    esac
done

# Check if all arguments are provided
if [ -z "$sourceImage" ] || [ -z "$sourceRegistry" ] || [ -z "$tag" ] || [ -z "$targetImage" ] || [ -z "$acrName" ]; then
    echo "------------------------"
    echo 'Some values are missing, please supply all the required arguments' >&2
    echo "------------------------"
    exit 1
fi


##############################################
### Lookup current digest in source registry
##############################################
sourceDigestRaw=$(docker buildx imagetools inspect --raw $sourceRegistry/$sourceImage:$tag) || {
    echo "⚠ Warning: cannot inspect image ${sourceRegistry}/${sourceImage}:${tag}" >&2
    echo "##vso[task.logissue type=warning]Cannot inspect image ${sourceRegistry}/${sourceImage}:${tag} - skipping import for this image"
    echo "##vso[task.setvariable variable=newTagFound;isOutput=true]false"
    echo "##vso[task.setvariable variable=inspectError;isOutput=true]true"
    exit 0  # Continue to next image in loop
}

sourceDigest=$(docker buildx imagetools inspect --raw $sourceRegistry/$sourceImage:$tag | sha256sum | cut -d' ' -f1)

[ "$sourceDigest" == "" ] && echo "Error: cannot get image digest for ${sourceImage}:${tag}" && exit 1

# Get current digest from target azure registry
echo "Source registry wrapper digest for ${sourceImage}:${tag}: [${sourceDigest}]"

##############################################
### Lookup existing digest in ACR
##############################################

acrDigestRaw=$(az acr manifest list-metadata --registry $acrName --name $targetImage --query "[?not_null(tags[])]|[?contains(tags, '${tag}')].digest|[0]" -o tsv || echo "")

acrDigest=${acrDigestRaw#sha256:}

echo "Target registry wrapper digest for ${targetImage}:${tag}: [${acrDigest}]"

################################################
### Compare digests and set output variables
################################################
if [[ "$acrDigest" == "" || "$acrDigest" != "$sourceDigest" ]]; then
    # Import needed (image missing or digest mismatch)
    echo "##vso[task.setvariable variable=newTagFound;isOutput=true]true"
    echo "##vso[task.setvariable variable=acrDigest;isOutput=true]$acrDigest"
    shortenedSourceDigest="${sourceDigest:7:6}"
    echo "[DEBUG] shortDigest to set: $shortenedSourceDigest"
    echo "##vso[task.setvariable variable=sourceDigest;isOutput=true]$shortenedSourceDigest"
else
    echo "Nothing to import for ${sourceRegistry}/${sourceImage}."
    exit 0
fi

##############################################
### Summary: Echo all key variables for review
##############################################
echo "--- Pipeline and Script Variable Summary ---"
echo "acrName: $acrName"
echo "sourceImage: $sourceImage"
echo "sourceRegistry: $sourceRegistry"
echo "targetImage: $targetImage"
echo "tag: $tag"
echo "sourceDigestRaw: $sourceDigestRaw"
echo "sourceDigest: $sourceDigest"
echo "sourceDigest (short): $shortenedSourceDigest"
echo "acrDigestRaw: $acrDigestRaw"
echo "acrDigest: $acrDigest"
echo "--- End Variable Summary ---"


