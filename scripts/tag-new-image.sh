#!/usr/bin/env bash

set -euo pipefail

baseTag=
targetImage=
acrName=
baseRegistry=
baseDigest=
acrDigest=

usage(){
>&2 cat << EOF
------------------------------------------------
Script to import image from source registry to ACR
------------------------------------------------
Usage: $0
    [ -bt | --baseTag ]
    [ -ti | --targetImage ]
    [ -an | --acrName ]
    [ -br | --baseRegistry ]
    [ -bd | --baseDigest ]
    [ -ad | --acrDigest ]
    [ -h | --help ]
EOF
exit 1
}

args=$(getopt -a -o bt:ti:an:br:bd:ad: --long baseTag:,targetImage:,acrName:,baseRegistry:,baseDigest:,acrDigest:,help -- "$@")
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
        -bt | --baseTag )        baseTag=$2             ; shift 2 ;;
        -ti | --targetImage )    targetImage=$2         ; shift 2 ;;
        -an | --acrName )        acrName=$2             ; shift 2 ;;
        -br | --baseRegistry )   baseRegistry=$2        ; shift 2 ;;
        -bd | --baseDigest )     baseDigest=$2          ; shift 2 ;;
        -ad | --acrDigest )      acrDigest=$2           ; shift 2 ;;
        --) shift; break ;;
        *) >&2 echo Unsupported option: $1
        usage ;;
    esac
done

# Check if all arguments are provided (acrDigest can be empty for new images)
if [ -z "$baseTag" ] || [ -z "$targetImage" ] || [ -z "$acrName" ] || [ -z "$baseRegistry" ] || [ -z "$baseDigest" ]; then
    echo "------------------------"
    echo 'Some values are missing, please supply all the required arguments' >&2
    echo "------------------------"
    exit 1
fi

# Move base tag to new image
[ "${acrDigest}" != "" ] && echo "Untagging previous ${baseTag} ..." && az acr repository untag -n ${acrName} --image ${targetImage}:${baseTag}

echo "Importing ${baseRegistry}/${targetImage}:${baseTag} to ACR as ${baseTag} ..."
az acr import --name ${acrName} --source ${baseRegistry}/${targetImage}:${baseTag} --image ${targetImage}:${baseTag}
echo "Done."
