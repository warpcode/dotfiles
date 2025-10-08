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

# Load in any custom dependency scripts that must run before
for file in ~/.zshrc.before.d/*.zsh(Nn.); do
    source "$file";
done;

# Load all the required files in order
for file in ${0:A:h}/{functions,config,apps,projects}/*.zsh(Nn.); do
    source "$file";
done;

for file in ~/.zshrc.{functions,config,apps,projects}/*.zsh(Nn.); do
    source "$file";
done;

# Load in any custom scripts that must run after
for file in ~/.zshrc.d/*.zsh(Nn.); do
    source "$file";
done;
