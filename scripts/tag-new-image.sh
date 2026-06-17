#!/usr/bin/env bash

set -euo pipefail

tag=
targetImage=
acrName=
targetRegistry=
sourceDigest=
acrDigest=

usage(){
>&2 cat << EOF
------------------------------------------------
Script to check if AKS cluster is active state
------------------------------------------------
Usage: $0
    [ -t | --tag ]
    [ -ti | --targetImage ]
    [ -an | --acrName ]
    [ -tr | --targetRegistry ]
    [ -sd | --sourceDigest ]
    [ -ad | --acrDigest ]
    [ -h | --help ]
EOF
exit 1
}

args=$(getopt -a -o t:ti:an:tr:sd:ad: --long tag:,targetImage:,acrName:,targetRegistry:,sourceDigest:,acrDigest:,help -- "$@")
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
        -h  | --help )           usage                  ; shift   ;;
        -t | --tag )        tag=$2             ; shift 2 ;;
        -ti | --targetImage )    targetImage=$2         ; shift 2 ;;
        -an | --acrName )        acrName=$2             ; shift 2 ;;
        -tr | --targetRegistry ) targetRegistry=$2      ; shift 2 ;;
        -sd | --sourceDigest )   sourceDigest=$2        ; shift 2 ;;
        -ad | --acrDigest )      acrDigest=$2           ; shift 2 ;;
        --) shift; break ;;
        *) >&2 echo Unsupported option: $1
        usage ;;
    esac
done

# Check if all arguments are provided (acrDigest can be empty for new images)
if [ -z "$tag" ] || [ -z "$targetImage" ] || [ -z "$acrName" ] || [ -z "$targetRegistry" ] || [ -z "$sourceDigest" ]; then
    echo "------------------------"
    echo 'Some values are missing, please supply all the required arguments' >&2
    echo "------------------------"
    exit 1
fi


# Check if the source tag (e.g., latest-$digest) exists in ACR before proceeding
echo "Checking if source tag ${tag}-${sourceDigest} exists in ${acrName}/${targetImage}..."
sourceTagExists=$(az acr repository show-tags -n ${acrName} --repository ${targetImage} --query "[?@=='${tag}-${sourceDigest}'] | [0]" -o tsv)

if [ -z "$sourceTagExists" ]; then
    echo "Error: Source tag ${tag}-${sourceDigest} does not exist in ${acrName}/${targetImage}. Import must have failed."
    exit 1
fi

# Remove the target tag if it exists
echo "Removing existing ${tag} tag if present..."
az acr repository untag -n ${acrName} --image ${targetImage}:${tag} 2>/dev/null || true

# Attempt to import the image with the new tag
echo "Importing ${targetRegistry}/${targetImage}:${tag}-${sourceDigest} as ${targetImage}:${tag} ..."
az acr import --name ${acrName} --source ${targetRegistry}/${targetImage}:${tag}-${sourceDigest} --image ${targetImage}:${tag} || {
    echo "Import failed, trying alternative method with repository tag..."
    manifestDigest=$(az acr repository show-manifests -n ${acrName} --repository ${targetImage} --query "[?tags[?contains(@, '${tag}-${sourceDigest}')]].digest | [0]" -o tsv)
    if [ -n "$manifestDigest" ]; then
        echo "Creating tag ${tag} for manifest ${manifestDigest}..."
        az acr repository untag -n ${acrName} --image ${targetImage}:${tag} 2>/dev/null || true
        az acr manifest metadata update -r ${acrName} -n ${targetImage}@${manifestDigest} --tag ${tag}
    else
        echo "Error: Could not find source image ${targetImage}:${tag}-${sourceDigest}"
        exit 1
    fi
}
echo "Done."
