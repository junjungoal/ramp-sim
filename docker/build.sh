docker build -t ramp-sim:latest --build-arg USER=${USER} --build-arg PASSWD=root --build-arg USER_ID=$(id -u) .
