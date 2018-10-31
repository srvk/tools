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
  echo "Usage: evalYunitate.sh <dirname>"
  echo "where dirname is the name of the folder"
  echo "containing the wav files, and transcription"
  echo "specifies which transcription you want to evaluate against."
  echo "Choices are:"
  echo "  -lena"
  echo "  -gold"
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

# Set CWD to path of dscore
cd $DSCOREDIR

# create temp dir and copy gold rttm inside it
mkdir $audio_dir/temp_ref

case $trs_format in
  "lena")
   sys_name="lena_"
  ;;
  "gold")
   sys_name=""
  ;;
   *)
    echo "ERROR: please choose SAD system between:"
    echo "  lena"
    echo "  gold"
    echo "Now exiting..."
    exit 1
   ;;

esac

# copy transcription to  temporary folders, since the eval takes folders !
for wav in `ls $audio_dir/*.wav`; do
    base=$(basename $wav .wav)
    cp $audio_dir/${base}.rttm $audio_dir/temp_ref/${base}.rttm
    sort --key 4 --numeric-sort $audio_dir/${base}.rttm -o $audio_dir/temp_ref/${base}.rttm
    sed -i 's/ \+/\t/g' $audio_dir/temp_ref/${base}.rttm
done

# create temp dir and copy .rttm inside of it
mkdir $audio_dir/temp_sys

for rttm in `ls $audio_dir/${sys_name}*.rttm`; do

    base=$(basename $rttm)
    out=`echo $base | cut -d '_' -f 3-`

    cp $rttm $audio_dir/temp_sys/$out
done

# check that temp_sys is not empty, otherwise exit and remove it.
if [ -z "$(ls -A $audio_dir/temp_sys)" ]; then
    echo "didn't find any transcription from the system you specified. Please run the yunitate or import lena rttm before evaluating."
    rm -rf $audio_dir/temp_sys $audio_dir/temp_ref
    exit
fi

echo "evaluating"


$conda_dir/python score_batch.py $audio_dir/${sys_name}_eval.df $audio_dir/temp_ref $audio_dir/temp_sys

# Check if some gold files are empty. If so, add a line in the eval dataframe
for fin in `ls $audio_dir/temp_ref/*.rttm`; do
    base=$(basename $fin .rttm)
    if [ ! -s $audio_dir/temp_ref/$base.rttm ]; then
        if [ ! -s $audio_dir/temp_sys/$base.rttm ]; then
            echo $base"	0	NA	NA	NA	NA	NA	NA	NA	NA" >> $audio_dir/${sys_name}eval.df
        else
            echo $base"	100	NA	NA	NA	NA	NA	NA	NA	NA" >> $audio_dir/${sys_name}eval.df
        fi
    elif [ ! -s $audio_dir/temp_sys/$base.rttm ] && [ -s $audio_dir/temp_ref/$base.rttm ]; then
        echo $base"	100	NA	NA	NA	NA	NA	NA	NA	NA" >> $audio_dir/${sys_name}eval.df
    fi
done

echo "done evaluating, check $1/${sys_name}_eval.df for the results"
# remove temps
rm -rf $audio_dir/temp_ref $audio_dir/temp_sys
