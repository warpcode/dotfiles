e_header "Nano Set-up"

echo ' - Compiling syntax files'

pushd ~/.dotfiles/vendor/nanorc > /dev/null


COMPILE=$(sed -f mixins.sed *.nanorc | sed -f theme.sed)

NANOVER=$(nano -V | sed -n 's/^.* version \([0-9\.]*\).*/\1/p')
NANOVERLOWR=$(printf "2.1.5\n$NANOVER" | sort -nr | head -1)

if [[ "$NANOVERLOWR" == "2.1.5" ]];
then
    COMPILE=$(echo "$COMPILE" | sed -e '/^header/d' )
fi

if [[ "$OSTYPE" =~ ^darwin ]];
then
    COMPILE=$(echo -n "$COMPILE" | sed -e 's|\\<|[[:<:]]|g;s|\\>|[[:>:]]|g' )
fi

echo "$COMPILE" > ~/.dotfiles/source/nanorc/syntax.nanorc

popd > /dev/null