# IP info
alias localip="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print \$1'"
alias wanip="dig +short myip.opendns.com @resolver1.opendns.com"

# Improved WHOIS lookups
alias whois="whois -h whois-servers.net"

# OSX flush dns cache
[[ "$OSTYPE" =~ ^darwin ]] && alias dnsflush="dscacheutil -flushcache && killall -HUP mDNSResponder"

# View live HTTP traffic
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Another traffic sniffer
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"

# All the dig info
function digga() {
	dig +nocmd "$1" any +multiline +noall +answer
}


#Url encoding and decoding
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'
alias urldecode='python -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])"'