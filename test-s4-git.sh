#!/bin/bash

function setup() {
    rm -rf .s4
}


function test_init_create_s4_dir() {
    ./s4-git.sh init
    if [ -d .s4 ]; then
        echo "Test passed"
    else
        echo "Test failed"
    fi
}

function test_init_again_fails() {
    ./s4-git.sh init
    if [ $? -eq 1 ]; then
        echo "Test passed"
    else
        echo "Test failed"
    fi
}

function test_remote_add() {
    # echo name of test
    echo -e "==================\nTesting remote add\n=================="
    result=$(./s4-git.sh remote add origin root@localhost)
    echo $result
    # assert root@localhost is in .s4/config
    echo "Checking .s4/config for root@localhost"
    origin=$(cat .s4/config | grep root@localhost)
    if [ $? -eq 0 ]; then
        echo "Test passed"
    else
        echo "Test failed"
    fi
    # assert result is "Adding remote"
    if [ "$result" = "Adding remote origin" ]; then
        echo "Test passed"
    else
        echo "Test failed"
    fi
}

setup
test_init_create_s4_dir
test_init_again_fails
test_remote_add
