e_header "Checking dependencies"

echo "TODO"
exit
function require { hash "${1}" 2>/dev/null || { return 1;} }

#Check for required installed binaries
ALL_INSTALLED=1

require git || { echo " [x] Git is not installed and is required"; ALL_INSTALLED=0; export ALL_INSTALLED; };

if [[ "$OSTYPE" =~ ^darwin ]]; then
    require gcc || { echo " [x] The XCode command line tools are not installed"; ALL_INSTALLED=0; export ALL_INSTALLED; };
fi

#If there were any errors, back out now
if [[ ${ALL_INSTALLED} -eq 0 ]]; then
    echo " [x] Please resolve the above errors before continuing"
    exit 1;
fi

echo " - Dependencies found"


# include necessary bash source files
source ~/.dotfiles/source/bashrc/01_misc_func.sh
source ~/.dotfiles/source/bashrc/01_paths.sh
