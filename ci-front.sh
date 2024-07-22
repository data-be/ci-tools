#!/bin/bash

function go() {
  docker compose --project-name pro build node --build-arg build_number_ci=$BUILD_NUMBER

  docker compose --project-name pro run -v $PWD/dist:/var/www/dist:rw node npm run build

  aws s3 cp $PWD/dist s3://$AWS_BUCKET/v$BUILD_NUMBER --recursive --acl public-read
}

FUNCTION=$1

while test $# -gt 0; do
  case "$2" in
    -h|--help)
      echo "CI-TOOLS - to standardize our builds"
      echo " "
      echo "./ci.sh FUNCTIONS OPTIONS"
      echo " "
      echo "functions:"
      echo "go                          launch the build and push"
      echo " "
      echo "options:"
      echo "-h, --help                  show brief help"
      exit 0
      ;;
    --aws-bucket*)
      export AWS_BUCKET=`echo $2 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --build-number*)
      export BUILD_NUMBER=`echo $2 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    *)
      break
      ;;
  esac
done

case "$FUNCTION" in
  go)
    echo "Build Started!"
    if [ -z "$AWS_BUCKET" ]
      then
        echo "--aws-bucket must be set"
        exit 1
    fi

    if [ -z "$BUILD_NUMBER" ]
      then
        echo "--build-number must be set"
        exit 1
    fi
    go
    ;;

  *)
    echo $"Usage: $0 {go}"
    exit 1

esac
