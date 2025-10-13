# Load in a .env file from the home directory if it exists
if [ -f ~/.env ]; then
    local key value
    while IFS== read -r key value; do
        if [[ ! -z "$key" ]]; then
            printf -v "$key" %s "$value" && export "$key"
        fi
    done <~/.env
fi

local file
local files_to_source=(
    ~/.zshrc.before.d/*.zsh(Nn-)
    ${0:A:h}/{functions,config,apps,projects}/*.zsh(Nn-)
    ~/.zshrc.{functions,config,apps,projects}/*.zsh(Nn-)
    ~/.zshrc.d/*.zsh(Nn-)
)

# Source all collected files
for file in "${files_to_source[@]}"; do
    source "$file"
done
