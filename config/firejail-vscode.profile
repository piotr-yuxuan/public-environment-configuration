include /etc/firejail/default.profile
# Start with nothing visible in $HOME
blacklist ${HOME}
# Then punch holes for VSCode config only
noblacklist ${HOME}/.config/Code
noblacklist ${HOME}/.vscode
whitelist ${HOME}/.config/Code
whitelist ${HOME}/.vscode
# Whitelist project directories below as needed, e.g.:
# noblacklist ${HOME}/code
# whitelist ${HOME}/code
include whitelist-common.inc
include whitelist-var-common.inc
caps.drop all
nonewprivs
noroot
protocol unix,inet,inet6,netlink
