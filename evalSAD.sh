#!/bin/bash
# Since the script is built to be launched outside of the vm, source
# the .bashrc which is not necessarily sourced!
source ~/.bashrc
conda_dir=/home/vagrant/anaconda/bin

# run OpenSAT with hard coded models & configs found here and in /vagrant
# assumes Python environment in /home/${user}/
# usage: runDiarNoisemes.sh <folder containing .wav files to process>

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
BASEDIR=`dirname $SCRIPT`
# Path to OpenSAT (go on folder up and to opensat)
DSCOREDIR=$(dirname $BASEDIR)/dscore

audio_dir=/vagrant/data
filename=$(basename "$audio_dir")
dirname=$(dirname "$audio_dir")
extension="${filename##*.}"
basename="${filename%.*}"

# check system to evaluate - either LDC, OpenSAT or "MySystem"
system=$1

if [[ $system = "ldc_sad" ]]; then
    sys_name="ldc_sad"
elif [[ $system = "openSAT_sad" ]]; then
    sys_name="opensat_sad"
elif [[ $system = "my_sad" ]]; then
    sys_name="my_sad"
else
    echo "Please Specify the System you wish to evaluate."
    echo "Choose between ldc_sad, openSAT_sad, or my_sad"
    exit
fi


# Set CWD to path of Dscore
cd $DSCOREDIR

# create temp dir and copy gold rttm inside it
mkdir /vagrant/temp_ref

for wav in `ls $audio_dir/*.wav`; do
    base=$(basename $wav .wav)
    cp $audio_dir/${base}.rttm /vagrant/temp_ref/${base}.rttm
done

# create temp dir and copy system .lab inside it,
# while also converting them to .rttm
mkdir /vagrant/temp_sys

for lab in `ls $audio_dir/${sys_name}_*.lab`; do
    base=$(basename $lab)
    out=`echo $base | cut -d '_' -f 3-`
    cp $lab /vagrant/temp_sys/$out
done
# check that temp_sys is not empty, otherwise exit and remove it.
if [ -z "$(ls -A /vagrant/temp_sys)" ]; then
    echo "didn't find any transcription from the system you specified. Please run the SAD before Evaluating."
    rm -rf /vagrant/temp_sys /vagrant/temp_ref
    exit
fi

# convert lab to rttm and remove labs
echo "gathering all files to evaluate"
sh /vagrant/toolbox/lab2rttm.sh /vagrant/temp_sys

rm /vagrant/temp_sys/*.lab

# evaluate using score_batch.py
echo "evaluating"
$conda_dir/python score_batch.py /vagrant/data/${sys_name}_eval.df /vagrant/temp_ref /vagrant/temp_sys
echo "done evaluating, check ${sys_name}_eval.df for the results"
# remove temps
rm -rf /vagrant/temp_ref /vagrant/temp_sys

