#!/bin/bash
# Since the script is built to be launched outside of the vm, source
# the .bashrc which is not necessarily sourced!
source ~/.bashrc

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`

if [ $# -ne 2 ]; then
  echo "Usage: eval.sh <data> <system>"
  echo "where data is the folder containing the data"
  echo "and system is the system you want"
  echo "to evaluate. Choices are:"
  echo "  -ldc_sad"
  echo "  -noisemes_sad"
  echo "  -diartk"
  exit
fi

# switch eval depending on system
audio_dir=$1
system=$2

case $system in
"ldc_sad")
   sh $BASEDIR/evalSAD.sh $audio_dir $system
   ;;
"noisemes")
   sh $BASEDIR/evalSAD.sh $audio_dir noisemes_sad
   ;;
"diartk")
   sh $BASEDIR/evalDiar.sh $audio_dir
   ;;
esac
