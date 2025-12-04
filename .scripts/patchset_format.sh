# $1 - version number
# $2 - directory name for patches
# $3 - patch range (for example HEAD~20)
# $4 - additional emails

LAST_PWD=$(pwd)
PATCHES=$KERNEL_PATCHES_DIRECTORY
SOURCE=$KERNEL_SOURCE_DIRECTORY
CHANGELOG_SCRIPT=$SCRIPT_PATCH_CHANGELOG
MAINTAINERS_SCRIPT=$SCRIPT_MAINTAINER_COVER

rm -rf $PATCHES/$2/
cd $SOURCE && \
git -c "user.email=m.wieczorretman@pm.me" format-patch -v $1 --thread --cover-letter --cover-from-description=subject --from="Maciej Wieczor-Retman <m.wieczorretman@pm.me>" -o $PATCHES/$2/ $3 && \
python $CHANGELOG_SCRIPT -i $PATCHES/$2/ && \
/home/maciej/Code/wieczorr.linux/scripts/checkpatch.pl $PATCHES/$2/changelog/* --codespell --strict
python $MAINTAINERS_SCRIPT -k $SOURCE -i $PATCHES/$2/changelog/ -g="$4 --confirm=always --cc=m.wieczorretman@pm.me" -d && \
cd $LAST_PWD
