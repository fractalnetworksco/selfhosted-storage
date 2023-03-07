#!/bin/bash
# write a shell script that emualtes the following git commands: init, clone, push, status

# provide a flexible way to add new commands to the s4 cli, implement each command as a bash function

function init() {
    # assert $1 is a directory
    if [ ! -d $1 ]; then
        echo "Error: $1 is not a directory"
        exit 1
    fi
    cd $1
    # create a borg repo
    echo "Initializing s4 volume"
    # return error if .s4 directory already exists
    if [ -d .s4 ]; then
        echo "Error: .s4 directory already exists"
        exit 1
    fi
    mkdir -p .s4
    # return to the original directory
    cd -            
}

function remote() {
    # handle add subcommand with switch statement
    case $1 in
        add)
            # make sure #2 is not empty
            if [ -z $3 ]; then
                echo "Error: must specify remote name and url"
                exit 1
            fi
            echo "Adding remote $2"
            echo "remote.$2"=$3 >> .s4/config
            ;;
        remove)
            # remove remote
            echo "Removing remote $2"
            # remove $2 from .s4/config
            cat .s4/config | grep -v $2 > .s4/config.tmp
            mv .s4/config.tmp .s4/config
            ;;
        -v)
            # prtint remotes in .s4/config in the same style as git remote -v wit all output on the same line
            cat .s4/config |grep remote| awk -F= '{printf $1 " " $2"\n"}'
            ;;
        *)
            echo "Unknown subcommand"
            ;;
    esac
}

function push() {
    # check of remote borg repo is initialized
    # if not, initialize it
    # get remote from s4/config
    
}

# handle subcommand in a case statement
case $1 in
    init)
        init $2
        ;;
    remote)
        remote $2 $3 $4
        ;;
    push)
        push
        ;;
    *)
        echo "Unknown command"
        ;;
esac
