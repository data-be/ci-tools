#!/bin/bash

function run() {
  echo 'Start run';
  IMAGE_NAME=$DOCKER_REGISTRY/$GITHUB_REPOSITORY/$APP_NAME:v$VERSION_NUMBER
  CONTAINER_NAME=$APP_NAME"_"$DCP_SERVICE_NAME

  docker-compose --project-name $APP_NAME build --build-arg build_number_ci=v$VERSION_NUMBER $DCP_SERVICE_NAME

  if [ -n "$WAIT_DATABASES" ]
    then
      echo 'Pre-run databases';
      docker-compose --project-name $APP_NAME up -d $WAIT_DATABASES

      echo 'Wait for databases';
      docker-compose --project-name $APP_NAME up waithosts
  fi

  if [ -n "$RUN_JS_TESTS" ]
    then
      if docker-compose --project-name $APP_NAME run $DCP_SERVICE_NAME npm test; then
        echo 'Test Success';
      else
        exit 1;
      fi
  fi

  docker tag $CONTAINER_NAME $IMAGE_NAME
  docker login https://$DOCKER_REGISTRY --username $DOCKER_USERNAME --password $DOCKER_PASSWORD
  docker push $IMAGE_NAME
}

FUNCTION=$1

while test $# -gt 0; do
  case "$2" in
    -h|--help)
      echo "CI-TOOLS - to standarize our builds"
      echo " "
      echo "./ci.sh FUNCTIONS OPTIONS --app-name=myApp --docker-username=xx --docker-password=xx --docker-version-number=54"
      echo " "
      echo "functions:"
      echo "go                          launch the build and push"
      echo " "
      echo "options:"
      echo "-h, --help                  show brief help"
      echo "--wait-databases=dbs        specify docker db links to wait using waithosts"
      exit 0
      ;;
    --wait-databases*)
      echo "Script will wait for db to start"
      export WAIT_DATABASES=`echo $2 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --app-name*)
      export APP_NAME=`echo $2 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --dcp-service-name*)
      export DCP_SERVICE_NAME=`echo $2 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --docker-username*)
      export DOCKER_USERNAME=`echo $2 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --docker-password*)
      export DOCKER_PASSWORD=`echo $2 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --docker-registry*)
      export DOCKER_REGISTRY=`echo $2 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --version-number*)
      export VERSION_NUMBER=`echo $2 | sed -e 's/^[^=]*=//g'`
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
    if [ -z "$APP_NAME" ]
      then
        echo "--app-name must be set"
        exit 1
    fi

    if [ -z "$DOCKER_USERNAME" ]
      then
        echo "--docker-username must be set"
        exit 1
    fi

    if [ -z "$DOCKER_PASSWORD" ]
      then
        echo "--docker-password must be set"
        exit 1
    fi

    if [ -z "$VERSION_NUMBER" ]
      then
        echo "--version-number must be set"
        exit 1
    fi

    if [ -z "$DCP_SERVICE_NAME" ]
      then
        echo "Docker-compose service name will be set to default: node"
        export DCP_SERVICE_NAME="node"
    fi

    if [ -z "$DOCKER_REGISTRY" ]
      then
        echo "Docker registry endpoint will be set to default: index.docker.io/v1/"
        export DCP_SERVICE_NAME="index.docker.io/v1/"
    fi
    run
    ;;

  *)
    echo $"Usage: $0 {go}"
    exit 1

esac


