#!/bin/bash
# Variables for the NGINX Multi source IP onfig
INAME="ens160"
DEST_IP="2a01:4f8:c012:b92e::1"
DEST_PORT="80"
IP6_FP="$PWD/server_v6.txt"
# listen from
LISTEN="1030"
# add ip on network card
#while read IP6; do
#    ip addr add $IP6/64 dev $INAME
#done
# Read the NGINX Multi source template file
template_content=$(<nginx_sourc_template.conf)
# Replace placeholders with variable values
template_config=${template_content/__DEST_IP__/$DEST_IP}
template_config=${template_config/__DEST_PORT__/$DEST_PORT}

SERVER_BLOK=$( while read line; do
 cat <<EOF
server {
    listen  127.0.0.1:$LISTEN;
    proxy_pass outbound;
    proxy_bind $line;
    access_log /var/log/nginx/access.log proxy flush=5m buffer=64;
    }
EOF
LISTEN=$(expr $LISTEN + 1)
done < "$IP6_FP" 
)
template_config=${template_config/__SERVER_BLOK__/$SERVER_BLOK}
echo "$template_config" > $PWD/test_sourc_dist.conf
# Read the NGINX Multi destination template file
template_content=$(<nginx_dest_template.conf)
IP6_NU=$(wc -l < "$IP6_FP")
# generate Upstream server
SERVER_LIS=$( for ((i = $LISTEN; i <= IP6_NU; i++)); do
    echo "server 127.0.0.1:$i;"
done
)
template_config=${template_content/__SERVER_LIS__/$SERVER_LIS}
echo "$template_config" > $PWD/test_dest_dist.conf
