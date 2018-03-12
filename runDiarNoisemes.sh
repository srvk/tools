#!/bin/bash
# runDiarNoisemes.sh

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

if [ $# -ne 1 ]; then
  echo "Usage: runOpenSAT.sh <audiofile>"
  exit 1;
fi

# let's get our bearings: set CWD to path of OpenSAT
cd $OpenSAT

# make output folder for features, below input folder
mkdir -p $audio_dir/feature

# first features
for file in `ls $audio_dir/*.wav`; do
  SSSF/code/feature/extract-htk-vm2.sh $file
done

# then confidences
python SSSF/code/predict/1-confidence-vm3.py $audio_dir
