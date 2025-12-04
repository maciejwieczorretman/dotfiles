#!/usr/bin/env bash

LAST_PWD=$(pwd)
PATCHES=$KERNEL_PATCHES_DIRECTORY
SOURCE=$KERNEL_SOURCE_DIRECTORY
CHANGELOG_SCRIPT=$SCRIPT_PATCH_CHANGELOG
MAINTAINERS_SCRIPT=$SCRIPT_MAINTAINER_COVER
WORK_EMAIL=$WORK_EMAIL_ADDRESS

EMAILS=""
CHOICE=""
email=""

while [[ $CHOICE != "STOP" ]]
do
	EMAILS=$EMAILS$email
	CHOICE=$(echo -e "Wpisz email...\nSTOP\n$(abook --mutt-query . | awk '{print $1}')" | dmenu -fn 'Iosevka Nerd Font-14' -c -l 10 -i -p "Maile: ") || exit 0
	case $CHOICE in
		*Wpisz*) email=" --to=$(echo "" | dmenu -fn 'Iosevka Nerd Font-14' -c -p "Podaj email: " <&-)" || exit 0 ;;
		*STOP*) email="" ;;
		*) email=" --to="$CHOICE ;;
	esac
done

GIT_SEND="git send-email --confirm=always --cc=$WORK_EMAIL"$EMAILS" "${PATCHES}"/$2/changelog/*"
rm -rf $PATCHES/$2/
cd $SOURCE && \
git format-patch -v $1 --thread --cover-letter --cover-from-description=subject  -o $PATCHES/$2/ $3 && \
python $CHANGELOG_SCRIPT -i $PATCHES/$2/ && \
$SOURCE/scripts/checkpatch.pl $PATCHES/$2/changelog/* --codespell --strict
echo $GIT_SEND
cd $LAST_PWD
