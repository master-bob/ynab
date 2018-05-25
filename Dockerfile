FROM debian:buster

LABEL maintainer="Leonardo Canessa <masterbob@gmail.com>"

# Let apt know that we will be running non-interactively.
ENV DEBIAN_FRONTEND noninteractive
# Set locale
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update

# Set the locale and timezone.
RUN apt-get install -y locales tzdata
# Following based on https://serverfault.com/a/825872 by Mike Mitterer
RUN echo "Europe/Berlin" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    sed -i -e "s/# $LANG.*/$LANG.UTF-8 UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure -f noninteractive locales && \
    update-locale LANG=$LANG LANGUAGE=$LANGUAGE LC_ALL=$LC_ALL

# Install wget, apt-utils
RUN apt-get install -y apt-utils
RUN apt-get install -y wget

# Install apt-add-repository
RUN apt-get install -y software-properties-common apt-transport-https gnupg

# Setup i386 architecture, add winehq repo
RUN dpkg --add-architecture i386; \
    wget -nc https://dl.winehq.org/wine-builds/Release.key; \
    apt-key add Release.key; \
    apt-add-repository 'deb https://dl.winehq.org/wine-builds/debian/ buster main'

# Add Contrib repo for winetricks
RUN apt-add-repository 'deb http://deb.debian.org/debian buster contrib'

# Get the latest WINE
RUN apt-get update; apt-get install -y winehq-stable winetricks mono-complete

# Create a user inside the container, what has the same UID as your
# user on the host system, to permit X11 socket sharing / GUI Your ID
# is probably 1000, but you can find out by typing `id` at a terminal.
RUN apt-get update; apt-get install -y sudo
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/docker && \
    echo "docker:x:${uid}:${gid}:Docker,,,:/home/docker:/bin/bash" >> /etc/passwd && \
    echo "docker:x:${uid}:" >> /etc/group && \
    echo "docker ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/docker && \
    chmod 0440 /etc/sudoers.d/docker && \
    chown ${uid}:${gid} -R /home/docker

ENV HOME /home/docker
WORKDIR /home/docker

# Add the ynab installer to the image.
ADD ["https://downloadpull-youneedabudgetco.netdna-ssl.com/ynab4/liveCaptive/Win/YNAB%204_4.3.857_Setup.exe", "ynab_setup.exe"]

# When it is added via the dockerfile it is owned read+write only by root
RUN chown docker:docker ynab_setup.exe

USER docker
