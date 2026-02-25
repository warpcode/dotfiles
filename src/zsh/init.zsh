local file

export DOTFILES=${0:A:h:h:h}

# Source core functions first (Critical for detection)
for file in ${0:A:h}/functions/**/*.zsh(Nn-); do source "$file"; done

# Load in a .env file from the home directory if it exists
[[ -f ~/.env ]] && env.source.file ~/.env

# Build list of remaining modules
local files_to_source=(
    ~/.zshrc.before.d/**/*.zsh(Nn-)
    ${0:A:h}/{config,apps,projects}/**/*.zsh(Nn-)
    ~/.zshrc.{functions,config,apps,projects}/**/*.zsh(Nn-)
    ~/.zshrc.d/**/*.zsh(Nn-)
    ~/.zsh_{path,prompt,exports,aliases,functions,extra}(Nn-)
)

# Source the rest
for file in "${files_to_source[@]}"; do
    source "$file"
done

unset file;
