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
