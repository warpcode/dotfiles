e_header "Checking dependencies"

function require { hash "${1}" 2>/dev/null || { return 1;} }

#Check for required installed binaries
ALL_INSTALLED=1

require git || { e_error "Git is not installed and is required"; ALL_INSTALLED=0; export ALL_INSTALLED; };

if [[ "$OSTYPE" =~ ^darwin ]]; then
    require gcc || { e_error "The XCode command line tools are not installed"; ALL_INSTALLED=0; export ALL_INSTALLED; };
fi

#If there were any errors, back out now
if [[ ${ALL_INSTALLED} -eq 0 ]]; then
    e_error "Please resolve the above errors before continuing"
    exit 1;
fi

e_success "Dependencies found"