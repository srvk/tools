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


# data directory
audio_dir=/vagrant/$1
filename=$(basename "$audio_dir")
dirname=$(dirname "$audio_dir")
extension="${filename##*.}"
basename="${filename%.*}"

sys_name='diartk'


# Set CWD to path of Dscore
#cd $DSCOREDIR
cd $DSCOREDIR

# create temp dir and copy gold rttm inside it
mkdir $audio_dir/temp_ref

for wav in `ls $audio_dir/*.wav`; do
    base=$(basename $wav .wav)
    cp $audio_dir/${base}.rttm $audio_dir/temp_ref/${base}.rttm
    #awk '{print $4" "($4+$5)" speech"}' $audio_dir/${base}.rttm > /vagrant/temp_ref/${base}.lab
done

# create temp dir and copy system .lab inside it,
# while also converting them to .rttm
mkdir $audio_dir/temp_sys

for rttm in `ls $audio_dir/${sys_name}_*.rttm`; do
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


$conda_dir/python score_batch.py $audio_dir/${sys_name}_eval.df $audio_dir/temp_ref $audio_dir/temp_sys
echo "done evaluating, check $audio_dir/${sys_name}_eval.df for the results"
# remove temps
#rm -rf /vagrant/temp_ref /vagrant/temp_sys
