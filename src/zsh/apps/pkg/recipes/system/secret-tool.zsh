pkg.recipe.define secret-tool \
    package="secret-tool" \
    managers="apt dnf" \
    apt="libsecret-tools" \
    dnf="libsecret"
