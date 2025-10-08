---
A collection of dotfiles for *nix systems

Description
========
---
A collection of dotfiles for *nix systems

Description
========
---

This is my personal compilation of dotfiles that I use. It is used to set up a common environment between *nix systems.

This project makes use of other open source projects which are listed and linked to within this readme. 

This project also makes use of `git subtree` so also listed will be the commands to update these subtree's


Installation
========
---
TODO


---

This project uses `git subtree` to manage external dependencies and stores them in the `vendors/` directory.

The external dependies were added using the following template and replacing `master` where/if necessary to select the branch to link to

     `git subtree add -P vendor/project --squash git-url master`

Updating a project manually can be used with a similar command and replacing `master` where necessary

     `git subtree pull -P vendor/project --squash git-url master`


vendors/nanorc
--------------------

The nano syntax highlighting repository is provided by [craigbarnes/nanorc](https://github.com/craigbarnes/nanorc) using the `master` branch. 
========
---

This project uses `git subtree` to manage external dependencies and stores them in the `vendors/` directory.

The external dependies were added using the following template and replacing `master` where/if necessary to select the branch to link to

     `git subtree add -P vendor/project --squash git-url master`

Updating a project manually can be used with a similar command and replacing `master` where necessary

     `git subtree pull -P vendor/project --squash git-url master`


vendors/nanorc
--------------------

The nano syntax highlighting repository is provided by [craigbarnes/nanorc](https://github.com/craigbarnes/nanorc) using the `master` branch. 
