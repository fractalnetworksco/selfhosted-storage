SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh

if [ -n "$S4_PRIV_KEY" ]; then
    s4 loadkey
fi

REMOTE="$1"
pull $REMOTE
