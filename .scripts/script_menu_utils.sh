PATCHES=$KERNEL_PATCHES_DIRECTORY
SOURCE=$KERNEL_SOURCE_DIRECTORY
BUILD=$KERNEL_BUILD_DIRECTORY
CHANGELOG_SCRIPT=$SCRIPT_PATCH_CHANGELOG
MAINTAINERS_SCRIPT=$SCRIPT_MAINTAINER_COVER
SCRIPTS_DIR=$SCRIPT_DIRECTORY
CMD_ARCHIVE=$CMD_ARCHIVE_FILE

terminal_open() {
	POSITION=$(xdotool getmouselocation --shell | grep "X=" | awk -F"=" '{print (NF>1)? $NF : ""}')
	if [[ $POSITION -gt 1920 ]]
	then
		FONT="-o font.size=11"
	else
		FONT=""
	fi
	alacritty $FONT --hold -e $1
}

timer_start () {
	~/.scripts/timer_dmenu.sh
}

timer_stop () {
	~/.scripts/timer_dmenu.sh 0
}

timer_menu () {
		CHOICE=$(printf "󱎫 timer start\\n󱎬 timer stop\\n󰈆 exit" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 4 -i)
		case "$CHOICE" in
			*󱎫*) timer_start ;;
			*󱎬*) timer_stop ;;
			*󰈆*) exit ;;
		esac
}

ssh_kernel_build () {
	HOST=${1%@*}
	IP=${1#*@}
	dq=\"
	POSITION=$(xdotool getmouselocation --shell | grep "X=" | awk -F"=" '{print (NF>1)? $NF : ""}')
	if [[ $POSITION -gt 1920 ]]
	then
		FONT="-o font.size=11"
	else
		FONT=""
	fi
	COMMAND="$SCRIPTS_DIR/remote_install_kernel.sh v6.17..HEAD~22 ${HOST} ${IP} _custom_mainline v6.17"
	alacritty $FONT &
	sleep 0.7
	xdotool type "$COMMAND";
}

open_ssh_connection () {
	~/.scripts/alacritty.sh --hold -e "ssh $1"
}

read_ssh_list () {
	~/.scripts/parse_ssh.sh ssh
}

ssh_password_clipboard () {
	HOST=${1%@*}
	IP=${1#*@}
	PASSWORD=$($SCRIPTS_DIR/parse_ssh.sh pass $HOST@$IP)
	echo $PASSWORD | xclip -selection clipboard && notify-send "Password for $1 copied to clipboard"
}

ssh_address_menu () {
	# $1 ssh address
		CHOICE=$(printf " open ssh connection\\n build kernel over ssh\\n copy ssh address\\n copy ssh password\\n󰈆 exit" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 4 -i)
		case "$CHOICE" in
			**) open_ssh_connection $1;;
			**) ssh_kernel_build $1;;
			**) echo $1 | xclip -selection clipboard && notify-send "$1 copied to clipboard" ;;
			**) ssh_password_clipboard $1 ;;
			*󰈆*) exit ;;
		esac
}

list_ssh () {
 		CHOICE=$(echo -e "$(read_ssh_list)" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 4 -i) || exit 0
		ssh_address_menu $CHOICE

}

ssh_menu () {
		CHOICE=$(printf " list ssh connections\\n󰈆 exit" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 4 -i)
		case "$CHOICE" in
			**) list_ssh ;;
			*󰈆*) exit ;;
		esac
}

notatki () {
	~/.scripts/dmenu_notes.sh
}

vit () {
	terminal_open vit
}

ssh_password_clipboard () {
	HOST=${1%@*}
	IP=${1#*@}
	PASSWORD=$(~/.scripts/parse_ssh.sh pass $HOST@$IP)
	echo $PASSWORD | xclip -selection clipboard && notify-send "Password for $1 copied to clipboard"
}

cmd_archive () {
	CHOICE=$(printf "$(grep "^[^#-]" $CMD_ARCHIVE | sed '1d')" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 10 -i)
	CHOICE=${CHOICE%#*}
	echo $CHOICE | xclip -selection clipboard && notify-send "$CHOICE copied to clipboard"
}

menu() {
		CHOICE=$(printf "󱎫  timer\\n󰒍  ssh menu\\n  notatki\\n  archiwum komend\\n  vit lista todo\\n󰈆  exit" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 10 -i)
		case "$CHOICE" in
			*󱎫*) timer_menu ;;
			*󰒍*) ssh_menu ;;
			**) notatki ;;
			**) cmd_archive ;;
			**) vit ;;
			*󰈆*) exit ;;
		esac
}

menu
