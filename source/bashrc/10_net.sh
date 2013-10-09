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

#Checks whether a domain could be registered or not
domainreg () {
  dig soa $1 | grep -q ^$1 && echo "Registered" || echo "Not Registered"
}


#Port scanner
portscan () {
  HOST="$1";
  for((port=1;port<=65535;++port));do 
      echo -en "$port ";
      if echo -en "open $HOST $port\nlogout\quit" | telnet 2>/dev/null | grep 'Connected to' > /dev/null;then 
          echo -en "\n\nport $port/tcp is open\n\n";
      fi;
  done
}

#Url encoding and decoding
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'
alias urldecode='python -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])"'