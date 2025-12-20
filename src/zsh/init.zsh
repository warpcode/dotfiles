# Load in a .env file from the home directory if it exists
if [ -f ~/.env ]; then
    while IFS= read -r line; do
        # Skip comments (starting with #, with optional leading whitespace) and empty lines
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ -z $line ]] && continue
        # Parse key=value (split on first =)
        if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
            key=${match[1]}
            value=${match[2]}
            # Trim leading/trailing whitespace from key and value
            key=${key##[[:space:]]}
            key=${key%%[[:space:]]}
            value=${value##[[:space:]]}
            value=${value%%[[:space:]]}
            # Validate key: must be a valid variable name (letters, digits, underscores; start with letter/_)
            if [[ $key =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                printf -v "$key" %s "$value" && export "$key"
            fi
        fi
    done <~/.env
fi

local file

# 1. Source core functions first (Critical for detection)
for file in ${0:A:h}/functions/**/*.zsh(Nn-); do source "$file"; done

# 2. Detect OS
local current_os=$(_os_detect_os_family)

# 3. Build list of remaining modules
local files_to_source=(
    ~/.zshrc.before.d/**/*.zsh(Nn-)
    ${0:A:h}/{installers,config,apps,projects}/**/*.zsh(Nn-)
    ${0:A:h}/platform/${current_os}/**/*.zsh(Nn-)
    ~/.zshrc.{functions,installers,config,apps,projects}/**/*.zsh(Nn-)
    ~/.zshrc.d/**/*.zsh(Nn-)
)

# 4. Source the rest
for file in "${files_to_source[@]}"; do
    source "$file"
done
