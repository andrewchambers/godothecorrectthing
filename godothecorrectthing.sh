#! /bin/sh

set -e
set -u
set -x

# N.B. This disables globbing.
# If you need it, enable it temporarily.
# This script turns it off because it deals with
# strings that look like paths, but we don't always
# want to expand them whenever doing $somevar.
set -f

editor=subl

guesscwdwithmagic () {
	cwd=$HOME
	winprog=$(ps -o comm,args -p `xdotool getwindowfocus getwindowpid` | tail -n 1)
	wintitle=$(xdotool getactivewindow getwindowname)
	case $winprog in
		*xterm*)
			cwd=`echo $wintitle | cut -d : -f 2- | sed 's/^ //'`
		;;
		*terminator*)
			cwd=`echo $wintitle | sed 's/^.*@.*: //'`
		;;
		*gedit*)
			cwd=`echo $wintitle | awk -F'[()]' '{print $2}'`
		;;
		*geany*)
			cwd=`echo $wintitle | awk -F '-' '{print $2}' | sed 's/^ //'`
		;;
		*subl*)
			cwd=`echo $wintitle | cut -d ' ' -f 1`
			cwd=`dirname $cwd`
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
text=$(xclip -o | head -n 1)

manualexpand () {
	# hack to expand from string without eval
	case $1 in
		/*)
			readlink -f $1
		;;
		~*)
			readlink -f $HOME/$(echo $1 | cut -c 2-)
		;;
		*)
			readlink -f $cwd/$1
		;;
	esac	
}

# Match URL's

case "$text" in
	http://* | https://*)
		exec xdg-open $text
	;;
esac


# Match patterns of the form:
#
# /some/file.txt:line:col
#
# and then open the text editor.

if echo "$text" | grep -q -E '^[_a-zA-Z0-9/~ \.]+:[0-9]+(:[0-9]+)?:?'
then
	f=$(manualexpand $(echo $text | cut -d : -f 1))
	pos=$(echo $text | cut -d : -f 2-)
	fwithpos=$f:$pos

	# strip trailing :, go error messages are one place this happens
	case $fwithpos in
		*:)
			fwithpos=$(echo $fwithpos | rev | cut -c 2- | rev)
		;;
	esac

	fnopos=`echo $fwithpos | cut -d : -f 1`
	
	if test -f $fnopos
	then
		exec $editor $fwithpos
	fi
fi

# Search a given file for a pattern:
# /some/file:/REGEX
#
# Search a dir for a pattern:
# /some/dir/*:/REGEX
#
# Recursively search a dir for a pattern:
#  /some/dir/**:/REGEX
#
# Search uses grep -E patterns, binary files are not searched.
# If there are multiple matches, dmenu is used to let the
# user select the correct choice, then open the file with editor.
#
# Search does not require dmenu to function when there is only a single match,
# but a much better experience requires dmenu.

if echo "$text" | grep -q -E '^[_a-zA-Z0-9/~ \.]+\*?\*?:/.+'
then
	f=$(echo $text | cut -d : -f 1)
	maxdepth="-maxdepth 0"
	case "$f" in
		*\*\*)
			maxdepth=""
			f=$(echo $f | rev | cut -c 3- | rev)
		;;
		*\*)
			maxdepth="-maxdepth 1"
			f=$(echo $f | rev | cut -c 2- | rev)
		;;
	esac
	f=$(manualexpand $f)
	pat=$(echo $text | cut -d : -f 2- | cut -c 2-)

	if test -e $f
	then
		# use find because some grep implementations don't have --exclude-dirs.
		filestosearch=$(find $f $maxdepth -not -path '*/\.*' -type f)
		searchresultsf=`mktemp`
		match=""
		grep -I -H -n -E "$pat" $filestosearch > $searchresultsf
		wait
		nresults=$(wc -l $searchresultsf | cut -d ' ' -f 1)
		if test $nresults -gt 1
		then
			match=$(cat $searchresultsf | dmenu -l 10 | cut -d : -f 1-2)
		elif test $nresults -gt 0
		then
			match=$(cat $searchresultsf | cut -d : -f 1-2)
		fi
		rm $searchresultsf
		if test -n "$match"
		then
			exec $editor $match
		fi
	fi
fi

# Match plain unadorned files or directories.

if echo "$text" | grep -q -E '^[_a-zA-Z0-9/~ \.]+'
then
	f=$(manualexpand $text)
	if test -e $f
	then
		case $f in
			# because xdg-open cannot handle line numbers
			# anyway, we must have the $editor hack.
			# We should use it for text files for consistency.
			*.c | *.go | *.md | *.txt)
				exec $editor $f	
			;;
		esac

		exec xdg-open $f
	fi
fi
