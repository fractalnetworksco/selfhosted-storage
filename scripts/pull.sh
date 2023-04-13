SCRIPT_DIR=$(dirname $(readlink -f $0))
source $SCRIPT_DIR/base.sh


REMOTE="$1"
ARCHIVE="$2"
pull $REMOTE $ARCHIVE
