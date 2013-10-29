[[ "$OSTYPE" =~ ^darwin ]] || return;

#Create aliases for mamp
for f in /Applications/MAMP/bin/php/*; do
    f=`basename "$f"`

    if [[ -f /Applications/MAMP/bin/php/${f}/bin/php ]]; then
        alias "mamp_${f}"="/Applications/MAMP/bin/php/${f}/bin/php"
    fi
done;