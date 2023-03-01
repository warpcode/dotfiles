if [[ "$OSTYPE" =~ ^darwin ]]
then
    # OSX flush dns cache
    alias dnsflush="dscacheutil -flushcache && killall -HUP mDNSResponder"
fi


# Improved WHOIS lookups
alias whois="whois -h whois-servers.net"
