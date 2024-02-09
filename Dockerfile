FROM ubuntu:latest

RUN mkdir /server /ngrok /opt/ltn

RUN apt update && apt upgrade -qqy && apt install -qqy \
 curl \
 openjdk-18-jre-headless \
 tmux \
 jq \
 unzip \
 && apt clean \
 && rm -rf /var/lib/apt/lists

WORKDIR /ngrok
RUN --mount=type=secret,id=ngrok-auth --mount=type=secret,id=ngrok-api \
 curl -OJ https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz \
 && tar xvzf ngrok-v3-stable-linux-amd64.tgz -C /usr/local/bin; \
 ngrok config add-authtoken $(cat /run/secrets/ngrok-auth); \
 ngrok config add-api-key $(cat /run/secrets/ngrok-api); \
 rm -rf /ngrok

WORKDIR /opt/ltn
COPY ltn-auth ltn-api ./
RUN curl -OJ https://localtonet.com/download/localtonet-linux-x64.zip \
 && unzip localtonet-linux-x64.zip \
 && chmod +x localtonet \
 && rm localtonet-linux-x64.zip; \
 apt purge -qqy unzip \
 && apt autoremove

WORKDIR /server
RUN curl -o fabric-installer.jar https://meta.fabricmc.net/v2/versions/loader/1.20.1/0.15.6/1.0.0/server/jar \
 && java -jar fabric-installer.jar server \
 && sed -i 's/false/true/' eula.txt \
 && sed -i 's/enable-command-block=false/enable-command-block=true/' server.properties \
 && rm -rf /server/world/* 

COPY config ./config
COPY mods ./mods
COPY --chmod=700 server-config.sh stop-server.sh /server/

CMD ["/server/server-config.sh"]
