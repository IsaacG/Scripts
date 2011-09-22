#!/bin/bash

# Play classical96.3 without Flash
alias classical='mplayer http://stream.classical963fm.com:8017'

# Monitor the xclip for URLs and auto-open
xclip-open () {
	xco=$(xclip -o)
	while sleep 0.2 ; do
		xc=$(xclip -o)
		[[ $xc = $xco ]] && continue
		[[ $xc = http* || $xc = www* ]] || continue
		xco="$xc"
		firefox "$xc"
	done
}
xo () { xclip-open ; }

# See what changed on my MP3 player
commpodcasts () { comm -3 <(ls ~/c/PODCASTS/) ~/Downloads/podcasts/loaded ; }

# Sync my MP3 player
syncpodcast () {
	if ! [[ -d ~/c/PODCASTS ]] ; then
		echo "Mount MP3 Player"
		return 1
	fi
	rsync -ahv --del ~/Downloads/podcasts/toLoad/ ~/c/PODCASTS/
	ls ~/c/PODCASTS > ~/Downloads/podcasts/loaded
	sync
	umount ~/c
}

# Add a file to my download queue
dl() { exec 3>~/downloadqueue ; printf "%s\n" "$@" >&3 ; }

# Count seconds
stopwatch () { SECONDS=0 ; while sleep 1; do clear ; echo ; echo $SECONDS | figlet  ; done ; }

# Bring up/down my encfs
alias encUp='encfs ~/enc/.data ~/enc/data'
alias encDown='fusermount -u ~/enc/data/'

alias amixer='sudo amixer'
alias io='iotop -d 30 -o -P -k'
alias s='[[ $TERM = *screen* ]] || ssh goodi.gotdns.com'
alias pw='$HOME/bin/pw/setup'
alias x="while sleep 1 ; do date >> ~/x.log ; startx >>~/x.log 2>&1 & wait || break ; sleep 10 || break ; done"
update () 
{ 
	unset TMOUT ; day=$( date +%F ); last=$( < ~/.update.last );
	[[ $day != $last ]] && echo -n $day > ~/.update.last && sudo pacman -Syu
}


