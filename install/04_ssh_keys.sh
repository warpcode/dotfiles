e_header "Checking SSH keys"

SSH_DIR=~/.ssh
SSH_KEY_NAME='id_rsa'

if [ ! -d "$SSH_DIR" ]; then
    echo " - Creating $SSH_DIR"
    mkdir "$SSH_DIR"
else
    echo " - $SSH_DIR exists"
fi

echo " - Setting $SSH_DIR permissions to 0700"
chmod 0700 "$SSH_DIR"


if [ ! -f "$SSH_DIR/$SSH_KEY_NAME" ]; then
    echo " - Creating $SSH_KEY_NAME ssh key"
    ssh-keygen -t rsa -N '' -f "$SSH_DIR/$SSH_KEY_NAME"
else
    echo " - $SSH_KEY_NAME ssh key already exists"
fi

echo " - Setting $SSH_KEY_NAME permissions to 0600"
chmod 600 "$SSH_DIR/$SSH_KEY_NAME"
echo " - Setting $SSH_KEY_NAME.pub permissions to 0600"
chmod 600 "$SSH_DIR/$SSH_KEY_NAME.pub"



if [ ! -f "$SSH_DIR/known_hosts" ]; then
    echo " - Creating known_hosts file"
    touch "$SSH_DIR/known_hosts"
else
    echo " - known_hosts file already exists"
fi

echo " - Setting known_hosts permissions to 0644"
chmod 644 "$SSH_DIR/known_hosts"



if [ ! -f "$SSH_DIR/config" ]; then
    echo " - Creating config file"
    cat << 'EOF' > "$SSH_DIR/config"
Host *
    # Set compression by default
    Compression yes
    CompressionLevel 5
    
    # Forward ssh agent to the remote machine.
    ForwardAgent yes

    # Automatically add all common hosts to the host file as they are connected to.
    StrictHostKeyChecking no
EOF
else
    echo " - config file already exists"
fi

echo " - Setting config permissions to 0644"
chmod 644 "$SSH_DIR/config"