# README

Build the docker container:

`docker build -t YOUR-CONTAINER-NAME https://raw.github.com/shofetim/ynab/master/Dockerfile`

Run with:
`sudo setenforce 0 && docker-compose run ynab`

## FAQ

### Prompts to install Gecko

You seem to be able to safely ignore this

### Wine cannot start x?

This seems to be a permissions issue on latest versions of Ubuntu, try:

`xhost +`
