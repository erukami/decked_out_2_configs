#! /bin/bash

trap "stop_server; exit" SIGTERM SIGINT

function stop_server() {
        /server/stop-server.sh
}

tmux new -ds server-run

echo "Configuring Voice Channel"
tmux send -t server-run:0 '/opt/ltn/localtonet authtoken $(cat /opt/ltn/ltn-auth)' ENTER

while ! [ $(tmux capture-pane -t server-run:0 -pS - | grep -c "Connected") -gt 0 ]
do
        sleep 5
done
sleep 5

tunInfo=$(curl -s -H "Authorization: Bearer$(cat /opt/ltn/ltn-api)" https://localtonet.com/api/GetTunnels)

while ! [ $(tmux capture-pane -t server-run:0 -pS - | grep -c 127.0.0.1) -gt 0 ]
do
	if ! [ $(echo $tunInfo | jq .result[].status) -eq "1" ]
	then
		curl -s \
        		-H "Authorization: Bearer $(cat /opt/ltn/ltn-api)" \
		        https://localtonet.com/api/StartTunnel/$(echo $tunInfo | jq .result[].id) \
        		> /dev/null
	fi

	sleep 5

	tunInfo=$(curl -s -H "Authorization: Bearer$(cat /opt/ltn/ltn-api)" https://localtonet.com/api/GetTunnels)
done

sed -i -E "s/voice_host=(.*)/voice_host=$(echo $tunInfo | jq -r .result[].url)/" /server/config/voicechat/voicechat-server.properties

echo "Starting Server"
tmux split-window -t server-run:0
tmux send -t server-run:0.1 'java -jar fabric-installer.jar server' ENTER

while ! [ $(tmux capture-pane -t server-run:0.1 -pS - | grep -c VoiceChatServerThread) -gt 0 ]
do
        sleep 60
done

echo "Server Started"
tmux send -t server-run:0.1 '/player TangoCam spawn at -485 62 1739 facing 0 0 in minecraft:overworld in spectator' ENTER
echo "Preparing Forwarder"

tmux split-window -t server-run:0.1
tmux select-layout -t server-run tiled
tmux send -t server-run:0.2 'ngrok tcp 25565' ENTER

while ! [ $(tmux capture-pane -t server-run:0.2 -pS - | grep -c '127.0.0.1') -gt 0 ]
do
        sleep 10
done

echo "Forwarder Started. Connect using:"
ngrok api endpoints list 2>/dev/null | jq -r '.endpoints[0].hostport'
while true; do sleep 1; done
