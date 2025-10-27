# Homelab-ansible project directory (override in your environment or ~/.zshrc.d/homelab-ansible.zsh if needed)
: "${HOMELAB_ANSIBLE_DIR:=$HOME/src/homelab-ansible}"
: "${HOMELAB_ANSIBLE_REPO:=git@github.com:warpcode/homelab-ansible.git}"

if [[ ! -d "$HOMELAB_ANSIBLE_DIR" ]]; then
  return
fi

# Navigation
alias ha.cd="_git_clone_and_cd \"$HOMELAB_ANSIBLE_REPO\" \"$HOMELAB_ANSIBLE_DIR\""

# Ansible management aliases
alias ha.play="(ha.cd && ansible-playbook site.yml)"
alias ha.ping="(ha.cd && ansible all -m ping)"

