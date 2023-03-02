if [[ "$OSTYPE" =~ ^darwin ]]
then
    # OSX flush dns cache
    alias dnsflush="dscacheutil -flushcache && killall -HUP mDNSResponder"
fi

# Improved WHOIS lookups
alias whois="whois -h whois-servers.net"

# Get IPs
alias localip="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
alias wanip="dig +short myip.opendns.com @resolver1.opendns.com"

# Get DNS info about a domain
digga() {
    if [ -z "$1" ]; then
        # display usage if no parameters given
        echo "Usage: digga <domain>"
    else
        dig +nocmd "$1" any +multiline +noall +answer
    fi
}

# Generate a data url
dataurl() {
    hash openssl 2>/dev/null || { echo 'Please install openssl'; exit;}

    if [ -z "$1" ]; then
        # display usage if no parameters given
        echo "Usage: dataurl <path/to/file>"
    else
        MIMETYPE=$(file -b --mime-type "$1");
        if [[ $MIMETYPE == text/* ]]; then
            MIMETYPE="${MIMETYPE};charset=utf-8";
        fi
        echo "data:${MIMETYPE};base64,$(openssl base64 -in "$1" | tr -d '\n')";
    fi
}

# Check whether a domain is registered or not
domain_is_registered() {
    if [ -z "$1" ]; then
        # display usage if no parameters given
        echo "Usage: domain_registered <domain>"
    else
        dig soa $1 | grep -q ^$1 && echo "Registered" || echo "Not Registered"
    fi
}

# View live HTTP traffic
httpdump() {
    if [ -z "$1" ]; then
        # display usage if no parameters given
        echo "Usage: httpdump <network_interface>"
    else
        sudo tcpdump -i "$1" -n -s 0 -w - | grep -a -o -E "Host\: .*|GET \/.*"
    fi
}

# Post scans a single host
# port_scan() {
#     if [ -z "$1" ]; then
#         # display usage if no parameters given
#         echo "Usage: port_scan <host>"
#     else
#         HOST="$1";
#         for((port=1;port<=65535;++port));do
#             if echo -en "open $HOST $port\nlogout\quit" | telnet 2>/dev/null | grep 'Connected to' > /dev/null;then
#                 echo -en "port $port/tcp is open\n";
#             fi;
#         done
#     fi
# }

# Another traffic sniffer
traffic_sniff() {
    hash ngrep 2>/dev/null || { echo 'Please install ngrep'; exit;}

    if [ -z "$1" ]; then
        # display usage if no parameters given
        echo "Usage: sniff <network_interface>"
    else
        sudo ngrep -d "$1" -t '^(GET|POST) ' 'tcp and port 80'
    fi
}
