#!/bin/bash
# Since the script is built to be launched outside of the vm, source
# the .bashrc which is not necessarily sourced!
source ~/.bashrc

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`

if [ $# -lt 2 ] ; then
  echo "Usage: eval.sh <data> <system> <<optionalSAD>>"
  echo "where data is the folder containing the data"
  echo "and system is the system you want"
  echo "to evaluate. Choices are:"
  echo "  -ldc_sad"
  echo "  -noisemes_sad"
  echo "  -diartk"
  echo "If evaluating diartk, please give which flavour"
  echo "of SAD you used to produce the diartk transcription"
  echo "you want to evaluate"
  exit
fi

# switch eval depending on system
audio_dir=$1
system=$2

case $system in
"ldc_sad"|"noisemes")
   sh $BASEDIR/evalSAD.sh $audio_dir $system
   ;;
"diartk")
   if [ $# -ne 3 ]; then
      echo "please specify SAD flavour for diartk"
      echo "Choices are :"
      echo "  -ldc_sad"
      echo "  -noisemes_sad"
      echo "  -textgrid"
      echo "  -eaf"
      echo "  -rttm"
      exit
   fi
   sad=$3
   sh $BASEDIR/evalDiar.sh $audio_dir $sad
   ;;
esac
