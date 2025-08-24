# Load in a .env file from the home directory if it exists
if [ -f ~/.env ]; then
    while IFS== read -r key value; do
        if [[ ! -z "$key" ]]; then
            printf -v "$key" %s "$value" && export "$key"
        fi
    done <~/.env
fi

# Load in any custom dependency scripts that must run before
for file in ~/.zshrc.before.d/*.zsh(Nn); do
    [ -e "$file" ] && source "$file";
done;
unset file;

# Load all the required files in order
for file in ${0:A:h}/{functions,config,apps}/*.zsh(Nn); do
    [ -e "$file" ] && source "$file";
done;
unset file;

for file in ~/.zshrc.{functions,config,apps}/*.zsh(Nn); do
    [ -e "$file" ] && source "$file";
done;
unset file;

# Load in any custom scripts that must run after
for file in ~/.zshrc.d/*.zsh(Nn); do
    [ -e "$file" ] && source "$file";
done;
unset file;
