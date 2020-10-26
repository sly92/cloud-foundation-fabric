#!/bin/bash
DEBIAN_FRONTEND=noninteractive apt install --assume-yes squid
cat <<EOF > /etc/squid/squid.conf
# bind to port 3128
http_port 0.0.0.0:3128

# only proxy, don't cache
cache deny all

acl ssl_ports port 443
acl safe_ports port 80
acl safe_ports port 443
acl CONNECT method CONNECT

# read clientd cidr from clients.txt
acl clients src "/etc/squid/clients.txt"

# read allowlist domains from allow.txt
acl allowlist dstdomain "/etc/squid/allow.txt"

# deny access to anything other than ports 80 and 443
http_access deny !safe_ports

# deny CONNECT if connection is not using ssl
http_access deny CONNECT !ssl_ports

# deny acccess to cachemgr
http_access deny manager

# deny access to localhost though the proxy
http_access deny to_localhost

# allow connection from allowed clients only to the allowed domains
http_access allow clients allowlist

# deny everything else
http_access deny all
EOF

%{ for host in allowlist ~}
echo "${host}" >> /etc/squid/allow.txt
%{ endfor ~}

%{ for client in clients ~}
echo "${client}" >> /etc/squid/clients.txt
%{ endfor ~}

systemctl restart squid
