docker build -t ramp-sim-curobo:latest --build-arg USER=${USER} --build-arg PASSWD=root --build-arg USER_ID=$(id -u) .
