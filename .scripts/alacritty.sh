POSITION=$(xdotool getmouselocation --shell | grep "X=" | awk -F"=" '{print (NF>1)? $NF : ""}')


if [[ $POSITION -gt 1920 ]]
then
	alacritty -o font.size=11 $@
else
	alacritty $@
fi
