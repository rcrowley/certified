set -e

BITS=2048
DAYS=3650
DB="$PWD/etc/ssl"

# Prefer to find other certified-* tools in the same directory as this one.
export PATH="$(cd "$(dirname "$0")" && pwd):$PATH"

# Take note of the entire command line to use as a Git commit message.  This
# must be done before any (destructive) option parsing takes place.
MESSAGE="$0 $*"

# Log a message and exit non-zero.
die() {
    log "$*"
    exit 1
}

# Echo the second and subsequent arguments to stdout if the first argument is
# a non-empty string.
if_echo() {
    IF="$1" shift
    if [ "$IF" ]
    then echo "$*"
    fi
}

# Return zero if the first argument looks like a DNS name, including wildcards
# and single labels.  Return non-zero otherwise.
is_dns() {
    case "$1" in
        *" "*) false;;
        \*.\*.*)
            log "double-wildcards are allowed by the RFC but not by Chrome"
            false;;
        \*.*) true;;
        *\**) false;;
        *) true;;
    esac
}

# Return zero if the first argument looks like an IPv4 address.
is_ip() {
    echo "$1" | grep -E -q "([0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]).([0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]).([0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]).([0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])"
}

# Log a message to stderr, in bold and prefixed with "certified: ".
log() {
    echo "$(tput "bold")$(basename "$0"): $*$(tput "sgr0")" >&2
}

# Extract the usage message using the Tomayko method and exit.
usage() {
    grep "^#/" "$0" | cut -c"4-" >&2
    exit "$1"
}
