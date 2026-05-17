export DOTFILES="$(pwd)"
cat << 'TPL' > /tmp/test.tmpl
{{ file.Read (printf "%s/assets/configs/ai/mcp.json" .Env.DOTFILES) }}
TPL
gomplate -f /tmp/test.tmpl
