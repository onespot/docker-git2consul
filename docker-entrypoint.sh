#!/usr/bin/dumb-init /bin/bash

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

USER=git2consul
GROUP=git2consul
HOME=/home/git2consul

KNOWN_HOSTS=$HOME/.ssh/known_hosts
SSH_IDENTITY_FILE=/run/secrets/ssh
SSH_PASSPHRASE_FILE=/run/secrets/passphrase

file_env 'TOKEN'

if [ ! -d "${HOME}/.ssh" ]; then
    mkdir "${HOME}/.ssh"
fi
chmod 700 "${HOME}/.ssh"

if [ -n "${SSH_CLIENT_CONFIG}" ]; then
    echo "${SSH_CLIENT_CONFIG}" > "${HOME}/.ssh/config"
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

    ssh-keyscan -H "${SSH_HOST}" >> ${KNOWN_HOSTS} 2> /dev/null

    ssh-keygen -l -f ${KNOWN_HOSTS} | grep -q -e ${SSH_HOST_FINGERPRINT}
    if [ $? -eq 0 ]; then
        printf "Matched fingerprint for ${SSH_HOST}: %s\n" "${SSH_HOST_FINGERPRINT}"
    else
        printf $?
        printf "Fingerprint for ${SSH_HOST} didn't match\n" >&2
        exit 1
    fi
fi

chown -R "${USER}:${GROUP}" "${HOME}/.ssh"

if [ -f ${SSH_PASSPHRASE_FILE} ]; then
    printf "SHA of passphrase file: %s \n" "$(shasum ${SSH_PASSPHRASE_FILE})"
fi

if [ -f ${SSH_IDENTITY_FILE} ]; then
    printf "Fingerprint of private key: %s \n" "$(sshpass -v -P PEM -f ${SSH_PASSPHRASE_FILE} ssh-keygen -E md5 -lf ${SSH_IDENTITY_FILE})"
fi

if [ "$1" == 'git2consul' ]; then
    shift
    set -- gosu "${USER}:${GROUP}" /usr/bin/node /usr/lib/node_modules/git2consul "$@"
fi

exec "$@"

