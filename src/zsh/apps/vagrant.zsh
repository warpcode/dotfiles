if [[ "$OSTYPE" =~ ^linux ]]; then
    # use lib virt on linux
    export VAGRANT_DEFAULT_PROVIDER=libvirt
fi
