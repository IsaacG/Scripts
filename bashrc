#!/bin/bash

# A bunch of useful stuff to source from ~/.bashrc or ~/.bash_profile

# Sleep spin until a file appears. $1 is filename. $2 is optional sleep length
waitforfile () {
        (( $# == 1 || $# == 2 )) || return 1
        local file="$1"
        local delay="${2:-30}"
        until [[ -f $file ]] ; do sleep "$delay" ; done
        return 0
}

alias c=clear
alias ls='ls --color=auto'

export HISTCONTROL=ignoreboth
