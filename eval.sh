#!/bin/bash
# Since the script is built to be launched outside of the vm, source
# the .bashrc which is not necessarily sourced!
source ~/.bashrc

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`

display_usage() {
    echo "Usage: eval.sh <data> <system> <<optionalSAD>>"
    echo "where data is the folder containing the data"
    echo "and system is the system you want"
    echo "to evaluate. Choices are:"
    echo "  ldc_sad"
    echo "  noisemes"
    echo "  tocombosad"
    echo "  opensmile"
    echo "  diartk"
    echo "  yunitate"
    echo "  yuniseg"
    echo "If evaluating diartk or yuniseg, please give which flavour"
    echo "of SAD you used to produce the transcription"
    echo "you want to evaluate"
    exit 1
}

if [ $# -lt 2 ] ; then
  display_usage
fi

# switch eval depending on system
audio_dir=$1
system=$2

case $system in
"tocombosad"|"opensmile"|"ldc_sad"|"noisemes")
   sh $BASEDIR/evalSAD.sh $audio_dir $system
   ;;
"yunitate"|"lena")
   sh $BASEDIR/evalDiar.sh $audio_dir $system
   ;;
"diartk"|"yuniseg")
   sad=$3
   sh $BASEDIR/evalDiar.sh $audio_dir $system $sad
   ;;
*)
   display_usage
   ;;

esac
