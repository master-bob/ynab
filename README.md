# README

## WORK IN PROGRESS; USE AT YOUR OWN RISK
Build the docker container:

`docker build -t YOUR-CONTAINER-NAME https://raw.github.com/shofetim/ynab/master/Dockerfile`

Run with:
`sudo setenforce 0 && docker-compose run ynab`

## FAQ

### Wine cannot start x?

This seems to be a permissions issue on latest versions of Ubuntu, try:

`xhost +`

This turns off security for the XServer. 

Also, run the container with the following additions:
`--volume /tmp/.X11-unix/X0:/tmp/.X11-unix/X0 -e DISPLAY`
this mounts the host xserver to the container's xserver & the -e command allows
 the host Display to be used.

To turn XHost security back on use:

`xhost -`.
