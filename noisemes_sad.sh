#!/bin/bash
# runDiarNoisemes.sh
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
OPENSATDIR=$(dirname $BASEDIR)/OpenSAT

audio_dir=/vagrant/$1
filename=$(basename "$audio_dir")
dirname=$(dirname "$audio_dir")
extension="${filename##*.}"
basename="${filename%.*}"

# this is set in user's login .bashrc
#export PATH=/home/${user}/anaconda/bin:$PATH

# let's get our bearings: set CWD to path of OpenSAT
cd $OPENSATDIR

# make output folder for features, below input folder
mkdir -p $audio_dir/feature

# first features
echo "extracting features for speech activity detection"
for file in `ls $audio_dir/*.wav`; do
  SSSF/code/feature/extract-htk-vm2.sh $file
done

# then confidences
#python SSSF/code/predict/1-confidence-vm3.py $1
echo "detecting speech and non speech segments"
$conda_dir/python SSSF/code/predict/1-confidence-vm5.py $audio_dir
echo "finished detecting speech and non speech segments"

# take all the .rttm in /vagrant/data/hyp and move them to /vagrant/data - move features and hyp to another folder also.
for sad in `ls $audio_dir/hyp_sum/*.lab`; do
    _lab=`basename $sad`
    lab=/vagrant/data/opensat_sad_$_lab
    mv $sad $lab
done

if [ ! -d "/vagrant/SAD_temp" ]; then
    mkdir -p /vagrant/SAD_temp
fi

if [ ! -d "/vagrant/SAD_temp/hyp_sum" ]; then
    mv /vagrant/data/hyp_sum /vagrant/SAD_temp
else
    echo "can't move hyp_sum/ folder to SAD_temp/ because SAD_temp is already full"
fi

if [ ! -d "/vagrant/SAD_temp/feature" ]; then
    mv /vagrant/data/feature /vagrant/SAD_temp
else
    echo "can't move feature/ folder to SAD_temp/ because SAD_temp is already full"
fi

