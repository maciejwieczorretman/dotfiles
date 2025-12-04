PATCHES=$KERNEL_PATCHES_DIRECTORY
SOURCE=$KERNEL_SOURCE_DIRECTORY
BUILD=$KERNEL_BUILD_DIRECTORY
CHANGELOG_SCRIPT=$SCRIPT_PATCH_CHANGELOG
MAINTAINERS_SCRIPT=$SCRIPT_MAINTAINER_COVER
SCRIPTS_DIR=$SCRIPT_DIRECTORY

terminal_open() {
	POSITION=$(xdotool getmouselocation --shell | grep "X=" | awk -F"=" '{print (NF>1)? $NF : ""}')
	if [[ $POSITION -gt 1920 ]]
	then
		FONT="-o font.size=11"
	else
		FONT=""
	fi
	alacritty $FONT --hold -e $@
}

open_kernel_config () {
		CHOICE=$(printf "Yes\\nNo\\n󰈆 exit" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 4 -i -p "Enable LLVM?")
		case "$CHOICE" in
			*Yes*) LLVM="LLVM=1";;
			*No*) LLVM="" ;;
		esac
		terminal_open "make -j10 $LLVM O=$BUILD nconfig"

}

compile_kernel() {
	exit 0
}

build_menu () {
	CHOICE=$(printf " open kernel config\\n󰣪 compile the kernel\\n󰈆 exit" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 4 -i)
	case "$CHOICE" in
		**) open_kernel_config ;;
		*󰣪*) compile_kernel ;;
		*󰈆*) exit ;;
	esac
}

# run the patchset_format script
# first collect all the needed data, some input, some pick from the list
patchset () {
	cd $SOURCE
	
	# input the version numer
	VERSION="$(echo "" | dmenu -fn 'Iosevka Nerd Font-14' -c -p "Wpisz numer wersji: " <&-)" || exit 0

	# use some existing directory or create a new one
	cd $PATCHES
	CHOICE=$(printf "Wpisz ręcznie nazwę serii\\n$(ls -d ./*)" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 10 -i -p "Wybierz katalog dla patchy: ")
	case "$CHOICE" in
		*Wpisz*) DIR_NAME="$(echo "" | dmenu -fn 'Iosevka Nerd Font-14' -c -p "Wpisz nazwę dla serii: " <&-)" || exit 0 ; FINAL_DIR="${DIR_NAME}_v${VERSION}" ;;
		*) DIR_NAME=$CHOICE; mv $DIR_NAME ${DIR_NAME}_del ; FINAL_DIR=$DIR_NAME ;;
	esac
	cd $SOURCE

	# browse tags or input patch range manually
	CHOICE=$(printf "Wpisz ręcznie\\n$(git tag)" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 10 -i -p "Wybierz zakresy patchy: ")
	case "$CHOICE" in
		*Wpisz*) PATCH_RANGE="$(echo "" | dmenu -fn 'Iosevka Nerd Font-14' -c -p "Wpisz zakres patchy: " <&-)" || exit 0 ;;
		*) PATCH_RANGE=$CHOICE ;;
	esac
	COMMAND="$SCRIPTS_DIR/$1 $VERSION $FINAL_DIR $PATCH_RANGE"

	terminal_open $COMMAND
	exit 0
}

prepare_patchset () {
	patchset "patchset_format.sh"
}

email_prepare_patchset () {
	patchset "dmenu_git_sendemail.sh"
}

patches_menu () {
	CHOICE=$(printf "󰙷 przygotuj łatki\\n󰇮 przygotuj i wyślij łatki\\n󰈆 exit" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 4 -i)
	case "$CHOICE" in
		*󰙷*) prepare_patchset ;;
		*󰇮*) email_prepare_patchset ;;
		*󰈆*) exit ;;
	esac

}

nvim_menu () {
	SESSION_PATH=$HOME/.local/share/nvim/session/
	CHOICE=$(printf "$(ls $SESSION_PATH)" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 10 -i -p "Wybierz sesję neovim: " || exit 0)
	# case "$CHOICE" in
	# 	*Wpisz*) PATCH_RANGE="$(echo "" | dmenu -fn 'Iosevka Nerd Font-14' -c -p "Wpisz zakres patchy: " <&-)" || exit 0 ;;
	# 	*) PATCH_RANGE=$CHOICE ;;
	# esac
	terminal_open nvim -S $SESSION_PATH$CHOICE
}

menu() {
		CHOICE=$(printf "󰣪 menu kompilacji\\n menu łatek\\n menu neovim\\n󰈆 exit" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 4 -i)
		case "$CHOICE" in
			*󰣪*) build_menu ;;
			**) patches_menu ;;
			**) nvim_menu ;;
			*󰈆*) exit ;;
		esac
}

menu
