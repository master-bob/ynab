FROM debian:buster

LABEL maintainer="Leonardo Canessa <masterbob@gmail.com>"

# Let apt know that we will be running non-interactively.
ENV DEBIAN_FRONTEND noninteractive

# Use Local Apt-cache, Remove if no app-cache
RUN  echo 'Acquire::http { Proxy "http://172.17.0.1:3142"; };' >> /etc/apt/apt.conf.d/01proxy

# Update and install apt-utils
RUN apt-get update; apt-get install -y apt-utils

# Set the locale and timezone.
RUN apt-get install -y locales tzdata
# Following based on various answers from https://serverfault.com/q/362903
RUN echo "Europe/Berlin" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure -f noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    update-locale LANGUAGE=en_US:en && \
    update-locale LC_ALL=en_US.UTF-8

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Install preqs to add winehq repo
RUN apt-get install -y software-properties-common apt-transport-https wget

# Setup i386 architecture
RUN dpkg --add-architecture i386

# Add Contrib repo for winetricks
RUN apt-add-repository 'deb http://deb.debian.org/debian buster contrib'

# Get the latest WINE
RUN apt-get update; apt-get install -y wine wine32 libwine libwine:i386 fonts-wine winetricks winbind xvfb

# Create a user inside the container, what has the same UID as your
# user on the host system, to permit X11 socket sharing / GUI Your ID
# is probably 1000, but you can find out by typing `id` at a terminal.
RUN apt-get install -y sudo
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/docker && \
    echo "docker:x:${uid}:${gid}:Docker,,,:/home/docker:/bin/bash" >> /etc/passwd && \
    echo "docker:x:${uid}:" >> /etc/group && \
    echo "docker ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/docker && \
    chmod 0440 /etc/sudoers.d/docker && \
    chown ${uid}:${gid} -R /home/docker

# Clean Up
RUN apt-get -y autoremove software-properties-common && \
    apt-get -y autoclean && \
    apt-get -y clean && \
    apt-get -y autoremove

# Get Gecko
WORKDIR /home/docker/.cache/wine
#ADD ["http://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi", "wine_gecko-2.47-x86.msi"]
RUN wget -q http://dl.winehq.org/wine/wine-gecko/2.47/wine_gecko-2.47-x86.msi
RUN chown docker:docker wine_gecko-2.47-x86.msi

# Get Mono
#ADD ["http://dl.winehq.org/wine/wine-mono/4.7.1/wine-mono-4.7.1.msi", "wine-mono-4.7.1.msi"]
RUN wget -q "http://dl.winehq.org/wine/wine-mono/4.7.1/wine-mono-4.7.1.msi"
RUN chown docker:docker wine-mono-4.7.1.msi

ENV HOME /home/docker
WORKDIR /home/docker

# Add the ynab installer to the image.
#ADD ["https://downloadpull-youneedabudgetco.netdna-ssl.com/ynab4/liveCaptive/Win/YNAB%204_4.3.857_Setup.exe", "ynab_setup.exe"]
RUN wget -q "https://downloadpull-youneedabudgetco.netdna-ssl.com/ynab4/liveCaptive/Win/YNAB%204_4.3.857_Setup.exe" -O ynab_setup.exe

# When it is added via the dockerfile it is owned read+write only by root
RUN chown docker:docker ynab_setup.exe

USER docker

# Wine initial setup
ENV WINEPREFIX /home/docker/.wine
RUN xvfb-run -a -s "-screen 0 1024x768x24" wine "wineboot" && while pgrep -u `whoami` wineserver > /dev/null; do sleep 1; done
RUN WINEARCH=win32 WINEPREFIX=/home/docker/.wine32 xvfb-run -a -s "-screen 0 1024x768x24" wine "wineboot" && while pgrep -u `whoami` wineserver > /dev/null; do sleep 1; done
RUN echo 'alias WIN32="WINEARCH=win32 WINEPREFIX=/home/docker/.wine32"' >> ~/.bashrc
