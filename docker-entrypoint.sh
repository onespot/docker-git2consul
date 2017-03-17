#!/usr/bin/dumb-init /bin/sh
set -e

USER=git2consul
GROUP=git2consul
HOME=/home/git2consul

if [ -n "${SSH_CLIENT_CONFIG}" ]; then
    if [ ! -d "${HOME}/.ssh" ]; then
        mkdir "${HOME}/.ssh"
    fi
    chmod 700 "${HOME}/.ssh"
    echo "${SSH_CLIENT_CONFIG}" > "${HOME}/.ssh/config"
    chmod 600 "${HOME}/.ssh/config"
    chown -R "${USER}:${GROUP}" "${HOME}/.ssh"
    echo "Wrote: ${HOME}/.ssh/config"
fi

if [ -n "${SSH_KEY_PASSPHRASE_FILE}" ]; then
    export GIT_SSH_COMMAND="sshpass -v -P passphrase -f ${SSH_KEY_PASSPHRASE_FILE} ${GIT_SSH_COMMAND}"
elif [ -n "${SSH_KEY_PASSWORD_FILE}" ]; then
    export GIT_SSH_COMMAND="sshpass -v -f ${SSH_KEY_PASSWORD_FILE} ${GIT_SSH_COMMAND}"
fi

echo "Using GIT SSH COMMAND: ${GIT_SSH_COMMAND}"

if [ "$1" == 'git2consul' ]; then
    shift
    set -- gosu "${USER}:${GROUP}" /usr/bin/node /usr/lib/node_modules/git2consul "$@"
fi

exec "$@"

