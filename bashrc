#!/bin/bash

# A bunch of useful stuff to source from ~/.bashrc or ~/.bash_profile

shopt -s nullglob
for i in ~/.bash/* ; do . "$i" ; done
alias c=clear
alias ls='ls --color=auto'

export HISTCONTROL=ignoreboth
