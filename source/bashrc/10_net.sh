# IP info
alias localip="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print \$1'"
alias wanip="dig +short myip.opendns.com @resolver1.opendns.com"

# Improved WHOIS lookups
alias whois="whois -h whois-servers.net"

# OSX flush dns cache
[[ "$OSTYPE" =~ ^darwin ]] && alias dnsflush="dscacheutil -flushcache"

# View live HTTP traffic
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""