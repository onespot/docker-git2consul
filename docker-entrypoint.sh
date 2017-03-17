#!/usr/bin/dumb-init /bin/sh
set -e

USER=git2consul
GROUP=git2consul
HOME=/home/git2consul

KNOWN_HOSTS=$HOME/.ssh/known_hosts

if [ ! -d "${HOME}/.ssh" ]; then
    mkdir "${HOME}/.ssh"
fi
chmod 700 "${HOME}/.ssh"

if [ -n ${SSH_CLIENT_CONFIG} ]; then
    echo ${SSH_CLIENT_CONFIG} > "${HOME}/.ssh/config"
    chmod 600 "${HOME}/.ssh/config"
    echo "Wrote: ${HOME}/.ssh/config"
fi

if [ -n "${SSH_HOST}" ]; then
    if [ -z "${SSH_HOST_FINGERPRINT}" ]; then
        printf "SSH_HOST_FINGERPRINT must be defined to verify connection to ${SSH_HOST}\n" >&2
        exit 1
    fi

    if [ ! -f ${KNOWN_HOSTS} ]; then
        touch ${KNOWN_HOSTS}
    fi

    ssh-keyscan -H ${SSH_HOST} >> ${KNOWN_HOSTS} 2> /dev/null

    ssh-keygen -l -f ${KNOWN_HOSTS} | grep -e ${SSH_HOST_FINGERPRINT}
    if [ $? -eq 0 ]; then
        echo "Matched fingerprint for ${SSH_HOST}"
    else
        printf $?
        printf "Fingerprint for ${SSH_HOST} didn't match\n" >&2
        exit 1
    fi
fi

chown -R "${USER}:${GROUP}" "${HOME}/.ssh"

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

