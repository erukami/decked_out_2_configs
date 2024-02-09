#! /bin/bash

trap "exit" SIGTERM SIGINT

echo "Stopping Tunnels"
if  tmux has-session -t server-run:0.0 2> /dev/null
then
        tmux send -t server-run:0.0 C-c
fi
if tmux has-session -t server-run:0.2 2> /dev/null
then
        tmux send -t server-run:0.2 C-c
fi

echo "Stopping Server"
if tmux has-session -t server-run:0.1 2> /dev/null
then
        tmux send -t server-run:0.1 "stop" ENTER

        while ! [ $(tmux capture-pane -t server-run:0.1 -pS - | tail -n 5 | grep -c "All dimensions are saved") -gt 0 ]
        do
                echo "--- Waiting on server to stop ---"
                sleep 30
        done

        echo "Cleaning up Localtonet"
        curl -s \
                -H "Authorization: Bearer $(cat /opt/ltn/ltn-api)" \
                https://localtonet.com/api/StopTunnel/$(curl -s -H "Authorization: Bearer $(cat /opt/ltn/ltn-api)" https://localtonet.com/api/GetTunnels | jq '.result[].id') \
                > /dev/null
fi
