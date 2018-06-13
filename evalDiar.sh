#!/bin/bash
# Since the script is built to be launched outside of the vm, source
# the .bashrc which is not necessarily sourced!
source ~/.bashrc
conda_dir=/home/vagrant/anaconda/bin

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`
# Path to OpenSAT (go on folder up and to opensat)
DSCOREDIR=$(dirname $BASEDIR)/dscore


if [ $# -ne 2 ]; then
  echo "Usage: evalDiar.sh <dirname> <transcription>"
  echo "where dirname is the name of the folder"
  echo "containing the wav files, and transcription"
  echo "specifies which transcription you want to use."
  echo "Choices are:"
  echo "  -ldc_sad"
  echo "  -noisemes"
  echo "  -textgrid"
  echo "  -eaf"
  echo "  -rttm"
  exit 1;
fi


# data directory
audio_dir=/vagrant/$1
filename=$(basename "$audio_dir")
dirname=$(dirname "$audio_dir")
extension="${filename##*.}"
basename="${filename%.*}"

#sys_name='goldSad'
trs_format=$2

# Set CWD to path of Dscore
#cd $DSCOREDIR
cd $DSCOREDIR

# create temp dir and copy gold rttm inside it
mkdir $audio_dir/temp_ref

case $trs_format in
  "ldc_sad")
   sys_name="ldcSad"
  ;;
  "noisemes")
   sys_name="noisemesSad"
  ;;
  "textgrid") 
   sys_name="goldSad"
   for wav in `ls $audio_dir/*.wav`; do
       base=$(basename $wav .wav)
       $conda_dir/python /home/vagrant/varia/textgrid2rttm.py $audio_dir/${basename}.TextGrid $audio_dir/${basename}.rttm
   done
  ;;
  "eaf")
    sys_name="goldSad"
   for wav in `ls $audio_dir/*.wav`; do
       base=$(basename $wav .wav)
       $conda_dir/python /home/vagrant/varia/elan2rttm.py $audio_dir/${basename}.eaf $audio_dir/${basename}.rttm
   done
   ;;
   "rttm")
    sys_name="goldSad"
   ;;
   *)
    echo "ERROR: please choose SAD system between:"
    echo "  ldc_sad"
    echo "  noisemes"
    echo "  textgrid"
    echo "  eaf"
    echo "  rttm"
    echo "Now exiting..."
    exit 1
   ;;

esac

# copy transcription to  temporary folders, since the eval takes folders !
for wav in `ls $audio_dir/*.wav`; do
    base=$(basename $wav .wav)
    cp $audio_dir/${base}.rttm $audio_dir/temp_ref/${base}.rttm
    #awk '{print $4" "($4+$5)" speech"}' $audio_dir/${base}.rttm > /vagrant/temp_ref/${base}.lab
done

# create temp dir and copy system .lab inside it,
# while also converting them to .rttm
mkdir $audio_dir/temp_sys

for rttm in `ls $audio_dir/diartk_${sys_name}_*.rttm`; do

    base=$(basename $rttm)
    out=`echo $base | cut -d '_' -f 3-`
    cp $rttm $audio_dir/temp_sys/$out
done

# check that temp_sys is not empty, otherwise exit and remove it.
if [ -z "$(ls -A $audio_dir/temp_sys)" ]; then
    echo "didn't find any transcription from the system you specified. Please run the SAD before Evaluating."
    rm -rf $audio_dir/temp_sys $audio_dir/temp_ref
    exit
fi

echo "evaluating"


$conda_dir/python score_batch.py $audio_dir/diartk_${sys_name}_eval.df $audio_dir/temp_ref $audio_dir/temp_sys

# Check if some gold files are empty. If so, add a line in the eval dataframe
for fin in `ls $audio_dir/temp_ref/*.rttm`; do
    base=$(basename $fin .rttm)
    if [ ! -s $audio_dir/temp_ref/$base.rttm ]; then
        echo $base"	NA	NA	NA	NA	NA	NA	NA	NA	NA" >> $audio_dir/diartk_${sys_name}_eval.df
    elif [ ! -s $audio_dir/temp_sys/$base.rttm ]; then
        echo $base"	100	NA	NA	NA	NA	NA	NA	NA	NA" >> $audio_dir/diartk_${sys_name}_eval.df
    fi
done

echo "done evaluating, check $1/diartk_${sys_name}_eval.df for the results"
# remove temps
rm -rf $audio_dir/temp_ref $audio_dir/temp_sys
