local file

# 1. Source core functions first (Critical for detection)
for file in ${0:A:h}/functions/**/*.zsh(Nn-); do source "$file"; done

# Load in a .env file from the home directory if it exists
[[ -f ~/.env ]] && env.source.file ~/.env

# 2. Detect OS
local current_os=$(_os_detect_os_family)

# 3. Build list of remaining modules
local files_to_source=(
    ~/.zshrc.before.d/**/*.zsh(Nn-)
    ${0:A:h}/{config,apps,projects}/**/*.zsh(Nn-)
    ${0:A:h}/platform/${current_os}/**/*.zsh(Nn-)
    ~/.zshrc.{functions,config,apps,projects}/**/*.zsh(Nn-)
    ~/.zshrc.d/**/*.zsh(Nn-)
)

# 4. Source the rest
for file in "${files_to_source[@]}"; do
    source "$file"
done
