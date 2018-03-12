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
OPENSATDIR=$(dirname $BASEDIR)/OpenSAT

audio_dir=/vagrant/data
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
for file in `ls $audio_dir/*.wav`; do
  SSSF/code/feature/extract-htk-vm2.sh $file
done

# then confidences
$conda_dir/python SSSF/code/predict/1-confidence-vm3.py $audio_dir

# take all the .rttm in /vagrant/data/hyp and move them to /vagrant/data - move features and hyp to another folder also.
for sad in `ls $audio_dir/hyp/*.rttm`; do
    _rttm=`basename $sad`
    rttm=/vagrant/data/opensat_sad_$_rttm
    mv $sad $rttm
done

if [ ! -d "/vagrant/diarNoisemes_temp" ]; then
    mkdir -p /vagrant/diarNoisemes_temp
fi

if [ ! -d "/vagrant/diarNoisemes_temp/hyp" ]; then
    mv /vagrant/data/hyp /vagrant/diarNoisemes_temp
else
    echo "can't move hyp_sum/ folder to diarNoisemes_temp/ because diarNoisemes_temp is already full"
fi

if [ ! -d "/vagrant/diarNoisemes_temp/feature" ]; then
    mv /vagrant/data/feature /vagrant/diarNoisemes_temp
else
    echo "can't move feature/ folder to diarNoisemes_temp/ because diarNoisemes_temp is already full"
fi

