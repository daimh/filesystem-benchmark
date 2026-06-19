#!/usr/bin/env bash
set -Eeufo pipefail
trap "exit 1" TERM
function die {
	if [ $# -gt 0 ]
	then
		echo -e "$1" | tr "	" " " | tr -s " " 1>&2
	else
		grep '#' /proc/$$/fd/255 \
			| sed -n '/^#@ HELP_START/,/^#@ HELP_END/p' \
			| grep -v "^#@ HELP_" \
			| sed "s/#@//; s/ \+/ /; s/\t\+/\t/; s/^ //" 
	fi
	kill 0
}
Node=localhost
OptShort="hv"
OptLong="help,version"
Opts=$(getopt -o $OptShort --long $OptLong -n "$(basename $0)" -- "$@")
eval set -- "$Opts"
while [ $# -gt 0 ]
do
	case "$1" in
#@ HELP_START
#@ NAME
#@	check-os-packages - check OS packages
#@ SYNOPSIS
#@	check-os-packages [OPTION]... Node
#@ EXAMPLE
#@	check-os-packages
#@	check-os-packages -n node001
#@ DESCRIPTION
		-h | --help) #@ display help and exit
			die ;;
		--version) #@ display version and exit
			die 20161212 ;;
		-v )	#@ verbose output
			set -x
			shift ;;
		--)
			shift ;;
		*)
			break ;;
#@ AUTHOR
#@	Manhong Dai <daimh@umich.edu>
#@ HELP_END
	esac
done
[ $# -eq 1 ] || die "ERR-001: use -h for help"
Node=$1
[ -n "$Node" ] || die "ERR-002: use -h for help"
Distro=$(grep ^ID= /etc/os-release | cut -d = -f 2 | tr -d '"' )
archController="pacman -S bc gnuplot m4 make openssh pandoc rsync texlive"
archWorker="pacman -S fio m4 psmisc"
debianController="apt install bc gnuplot m4 make pandoc psmisc rsync ssh screen texlive-base texlive-bibtex-extra texlive-binaries texlive-extra-utils"
debianWorker="apt install fio m4 psmisc"
ubuntuController=$debianController
ubuntuWorker=$debianWorker
rockyController="dnf config-manager --set-enabled powertools && sudo dnf -y install bc gnuplot m4 make openssh pandoc rsync texlive"
rockyWorker="dnf -y install fio m4 psmisc"
if [ "$Node" = "localhost" ]
then
	Sudo=sudo
	Cmd=${Distro}Controller
	! which gnuplot m4 pandoc > /dev/null || exit 0
else
	Sudo="ssh $Node sudo"
	Cmd=${Distro}Worker
	! which dd fio killall m4 > /dev/null || exit 0
fi
[ "$Distro" = arch -o "$Distro" = debian -o $Distro = rocky -o $Distro = ubuntu ] \
	|| die "ERR-003: only Arch, Debian and Rocky are supported as of now"
printf %60s | tr ' ' '#'
echo -e "\n# Please intall the missing packages with a command like below\n# $Sudo ${!Cmd}"
exit 1
