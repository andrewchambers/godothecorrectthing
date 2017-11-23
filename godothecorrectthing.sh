#! /bin/sh

set -e
set -u
set -x

# use the standard $EDITOR variable
: "${EDITOR:=subl}" # initialize it with default, if empty

guesscwdwithmagic () {
	cwd=$HOME

	wintitle=$(xdotool getactivewindow getwindowname)
	case $wintitle in
		nixos:*:*)
			cwd=`echo $wintitle | cut -d : -f 3-`
		;;
		*Sublime\ Text)
			cwd=`echo $wintitle | cut -d ' ' -f 1`
			cwd=`dirname $cwd`
		;;
		*)
			# get the CWD of the running app
			winpid=$(xdotool getactivewindow getwindowpid)
			cwd=$(readlink -f /proc/$winpid/cwd)
		;;
	esac

	case $cwd in
		~*)
			cwd=$HOME/$(echo $cwd | cut -c 2-)
		;;
	esac

	echo $cwd
}

cwd=$(guesscwdwithmagic)

manualexpand () {
	# hack to expand from string without eval
	case $1 in
		/*)
			echo $1
		;;
		~*)
			echo $HOME/$(echo $1 | cut -c 2-)
		;;
		*)
			echo $cwd/$1
		;;
	esac
}

cwd=$(manualexpand $cwd)

type xclip 1>/dev/null 2>&1 && clip="xclip -o"
type xsel 1>/dev/null 2>&1 && clip="xsel -o"
[ -z "$clip" ] && echo "You need 'xclip' or 'xsel' for this script to work" && exit 1

text=$($clip | head -n 1)
[ -z "$text" ] && echo "nothing found in clopboard..." && exit 0

if [[ "$text" == *"://"* ]]; then
	exec xdg-open "$text"
fi

if [[ $text =~ ^[a-zA-Z/~\ \.]+(:[0-9]*)*:? ]]; then
	fwithpos=$(manualexpand $text)

	# strip trailing :, go error messages are one place this happens
	# match last character, if it's ":" -> remove it
	if [ "${fwithpos: -1}" == ":" ]; then
		fwithpos=${fwithpos: : -1} # strip last character
		# https://unix.stackexchange.com/a/144330/19795 for more info
	fi

	fnopos=$fwithpos
	if [[ "${fwithpos}" == *":"* ]]; then
		fnopos=${fwithpos%:*}
		fline=${fwithpos#*:}
	fi

	if [[ -f $fnopos ]]; then
		case $EDITOR in
			*vi*)
				exec $EDITOR $fnopos +$fline
			;;
			subl*)
				exec $EDITOR $fwithpos
			;;
			*)
				# most editors would not understand "/path/to/file:123", so we give only the file part
				exec $EDITOR $fnopos
			;;
		esac
	fi

	if [[ -d $fnopos ]]; then
		exec xdg-open $fnopos
	fi
fi

