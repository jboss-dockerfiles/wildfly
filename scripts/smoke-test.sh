WILDFLY_IMAGE=$1

check_http_status() {
  response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/")
  if [ "$response" -eq 200 ]; then
    echo "Success! Received a 200 OK response."
    return 0
  fi
  return 1
}

check_wildfly_up_and_running() {
  # wait until WildFLy is up and running
  max_time=120
  retry_interval=5

  start_time=$(date +%s)
  while true; do
    current_time=$(date +%s)
    elapsed_time=$(( current_time - start_time ))
    if [ $elapsed_time -ge $max_time ]; then
      echo "Failed to get WildFly up and running within $max_time seconds."
      return 1
    fi
    docker container logs ${CONTAINER_ID} | grep WFLYSRV0025
    if [ $? -eq 0 ]; then
      echo "Success! WildFly is up and running."
      return 0
    fi
    sleep $retry_interval
  done
}

check_wildfly_version() {
  docker container logs ${CONTAINER_ID} | grep WFLYSRV0025 | grep ${WILDFLY_VERSION}
  if [ $? -eq 0 ]; then
    echo "Success! WildFly is using version ${WILDFLY_VERSION}."
   return 0
  fi
  return 1
}

WILDFLY_VERSION=$(grep "ENV WILDFLY_VERSION" Dockerfile | rev | cut -d' ' -f1 | rev)

docker run --rm -p 8080:8080 ${WILDFLY_IMAGE} &
sleep 2
CONTAINER_ID=$(docker ps -l -q)

if ! check_wildfly_up_and_running; then
    echo "WildFly did not boot up properly."
    exit 1
fi

if ! check_http_status; then
    echo "WildFly did not reply to the HTTP request."
    exit 1
fi

if ! check_wildfly_version; then
    echo "WildFly did not use the expected ${WILDFY_VERSION} version."
    exit 1
fi

docker kill ${CONTAINER_ID}