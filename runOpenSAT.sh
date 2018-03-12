#!/bin/bash

# run OpenSAT with hard coded models & configs found here and in /vagrant
# assumes Python environment in /home/${user}/

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

# let's get our bearings: set CWD to the path of OpenSAT
cd $OPENSATDIR

# first features
echo "extracting Features for OpenSAT"
SSSF/code/feature/extract-htk-vm.sh $audio_dir

# then confidences
#/home/vagrant/anaconda/bin/python SSSF/code/predict/1-confidence-vm.py $BASEDIR/SSSF/data/feature/evl.med.htk/$basename.htk $basename
echo "predicting classes"
python SSSF/code/predict/1-confidence-vm.py $BASEDIR/SSSF/data/feature/evl.med.htk/$basename.htk $basename
echo "OpenSAT finished running"
