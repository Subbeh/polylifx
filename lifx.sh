#!/bin/sh

CMD='lifx -g Office'

pipe=/tmp/lifx.pipe
test -e $pipe && rm $pipe
mkfifo -m 0600 $pipe

declare -i brightness
underline=%{-u} 

trap "trap - SIGTERM && rm -f $pipe && kill -- -$$" SIGINT SIGTERM EXIT

main() {
  status
  while true; do
    ((i++ % 60)) || { status && update; i=1; }
    sleep 1 &
    wait $!
  done &

  while read cmd ; do
    #echo test
    case $cmd in
      toggle) toggle ;;
      up)     brightness up ;;
      down)   brightness down ;;
    esac
  done < $pipe 3> $pipe
}

toggle() {
  $CMD -T &> /dev/null
  sleep 1
  status && update
}

brightness() {
  case $1 in
    up) x=1 ;;
    down) x=-1 ;;
  esac

  brightness+=$((10 * $x))
  if (($brightness > 100)) ; then
    brightness=100
  elif (($brightness < 0)) ; then
    brightness=0
  fi
  update
  $CMD -B $brightness &>/dev/null &
}

status() {
  while read status ; do
    case $status in
      *power*on*) underline=%{u#de935f} ;;
      *power*off*) underline=%{u#cc241d} ;;
      *brightness*) brightness=$(echo $status | awk '-F[:,]' '{ print substr($2,0,5) *100 }') ;;
    esac
  done <<< $($CMD -a 2> /dev/null) 
}

update() {
  echo %{T3}${underline}%{+u} $brightness\%%{-u}%{T-}
}

main $*
