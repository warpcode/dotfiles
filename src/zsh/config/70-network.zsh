# Get IPs
alias localip="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
alias wanip="dig +short myip.opendns.com @resolver1.opendns.com"


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
