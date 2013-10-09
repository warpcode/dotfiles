
# Make vim the default editor
export EDITOR="vim"

#######################
# Open Editor
#######################
function e(){
    if [[ $EDITOR == '' ]]
    then
        echo "\$EDITOR variable is empty"
        exit 1
    fi

    if [ "$1" = "" ] ; then
      exec $EDITOR .
    else
      exec $EDITOR "$1"
    fi
}