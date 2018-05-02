
# Improved WHOIS lookups
alias whois="whois -h whois-servers.net"

# OSX flush dns cache
[[ "$OSTYPE" =~ ^darwin ]] && alias dnsflush="dscacheutil -flushcache && killall -HUP mDNSResponder"
