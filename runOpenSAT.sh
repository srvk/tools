#!/bin/bash
# Since the script is built to be launched outside of the vm, source
# the .bashrc which is not necessarily sourced!
source ~/.bashrc
conda_dir=/home/vagrant/anaconda/bin

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
$conda_dir/python SSSF/code/predict/1-confidence-vm.py $BASEDIR/SSSF/data/feature/evl.med.htk/$basename.htk $basename
echo "OpenSAT finished running"

# take all the .rttm in /vagrant/data/hyp and move them to /vagrant/data - move features and hyp to another folder also.
for sad in `ls $audio_dir/hyp/*.rttm`; do
    _rttm=`basename $sad`
    rttm=/vagrant/data/opensat_sad_$_rttm
    mv $sad $rttm
done

if [ ! -d "/vagrant/openSAT_temp" ]; then
    mkdir -p /vagrant/openSAT_temp
fi

if [! -d "/vagrant/temp/hyp_sum" ]; then
    mv /vagrant/data/hyp_sum /vagrant/openSAT_temp
else
    echo "can't move hyp_sum/ folder to openSAT_temp/ because temp is already full"
fi

if [! -d "/vagrant/temp/feature" ]; then
    mv /vagrant/data/feature /vagrant/openSAT_temp
else
    echo "can't move features/ folder to openSAT_temp/ because temp is already full"
fi

