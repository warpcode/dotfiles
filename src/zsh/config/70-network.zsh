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


# Downloads all the contents of an open directory
opendirdl(){
    if [ -z "$1" ]; then
        # display usage if no parameters given
        echo "Usage: opendirdl <link>"
    else
        wget -m -e robots=off --no-parent --reject-regex "(.*)\?(.*)" --reject="index.html*" $@
    fi
}

# Exposes a directory as a HTTP open directory
opendir_server() {
    port="${1:-8000}";
    # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
    # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
    python3 -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port";
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
	if [ -z "${1}" ]; then
		echo "ERROR: No domain specified.";
		return 1;
	fi;

	local domain="${1}";
	echo "Testing ${domain}…";
	echo ""; # newline

	local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
		| openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1);

	if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
		local certText=$(echo "${tmp}" \
			| openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
			no_serial, no_sigdump, no_signame, no_validity, no_version");
		echo "Common Name:";
		echo ""; # newline
		echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//";
		echo ""; # newline
		echo "Subject Alternative Name(s):";
		echo ""; # newline
		echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
			| sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2;
		return 0;
	else
		echo "ERROR: Certificate not found.";
		return 1;
	fi;
}
